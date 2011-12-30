import skyui.InventoryColumnFormatter;
import skyui.BarterDataFetcher;
import gfx.io.GameDelegate;

class BarterMenu extends ItemMenu
{
    static var DEBUG_LEVEL:Number = 1;
        
	private var bPCControlsReady: Boolean = true;
	private var _playerInfoObj;
	private var _buyMult:Number;
	private var _sellMult:Number;
	private var _confirmAmount:Number;
	private var _playerGold:Number;
	private var _selectedCategory:Number;
	private var _vendorGold:Number;
	
	var CategoryListIconArt:Array;
	
	var ColumnFormatter:InventoryColumnFormatter;
	var DataFetcher:BarterDataFetcher;

	function BarterMenu()
	{
		super();
		_buyMult = 1;
		_sellMult = 1;
		_vendorGold = 0;
		_playerGold = 0;
		_confirmAmount = 0;
		
		CategoryListIconArt = ["inv_all", "inv_weapons", "inv_armor",
							   "inv_potions", "inv_scrolls", "inv_food", "inv_ingredients",
							   "inv_books", "inv_keys", "inv_misc"];
		
		ColumnFormatter = new InventoryColumnFormatter();
		ColumnFormatter.maxTextLength = 80;
		
		DataFetcher = new BarterDataFetcher();
	}

	function InitExtensions()
	{
		super.InitExtensions();
		GameDelegate.addCallBack("SetBarterMultipliers", this, "SetBarterMultipliers");
		ItemCard_mc.addEventListener("messageConfirm", this, "onTransactionConfirm");
		ItemCard_mc.addEventListener("sliderChange", this, "onQuantitySliderChange");
		BottomBar_mc.SetButtonArt({PCArt: "Tab", XBoxArt: "360_B", PS3Art: "PS3_B"}, 1);
		BottomBar_mc.Button1.addEventListener("click", this, "onExitButtonPress");
		BottomBar_mc.Button1.disabled = false;
		
		InventoryLists_mc.CategoriesList.setIconArt(CategoryListIconArt);

		InventoryLists_mc.ItemsList.entryClassName = "ItemsListEntryInv";
		InventoryLists_mc.ItemsList.columnFormatter = ColumnFormatter;
		InventoryLists_mc.ItemsList.dataFetcher = DataFetcher;
		InventoryLists_mc.ItemsList.setConfigSection("BarterList");
	}

	function onExitButtonPress()
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("BarterMenu onExitButtonPress()");
		GameDelegate.call("CloseMenu", []);
	}

	function SetBarterMultipliers(a_buyMult, a_sellMult)
	{
		if (DEBUG_LEVEL > 0)_global.skse.Log("BarterMenu SetBarterMultipliers()");
		_buyMult = a_buyMult;
		_sellMult = a_sellMult;
		// set initial multiplier for datafetcher
		InventoryLists_mc.ItemsList.dataFetcher._barterMult = _buyMult;
		BottomBar_mc.SetButtonsText("", "$Exit");
	}

	function onShowItemsList(event)
	{
		_selectedCategory = InventoryLists_mc.CategoriesList.selectedIndex;
		if (DEBUG_LEVEL > 0) _global.skse.Log("BarterMenu onShowItemsList() _selectedCategory = " + _selectedCategory);
		if (IsViewingVendorItems())
		{
			// adjust item values to buy multiplier
			InventoryLists_mc.ItemsList.dataFetcher._barterMult = _buyMult;
			// invalidate data to apply new values
			InventoryLists_mc.ItemsList.InvalidateData();
			BottomBar_mc.SetButtonsText("$Buy", "$Exit");
		}
		else
		{
			// adjust item values to sell multiplier
			InventoryLists_mc.ItemsList.dataFetcher._barterMult = _sellMult;
			// invalidate data to apply new values
			InventoryLists_mc.ItemsList.InvalidateData();
			BottomBar_mc.SetButtonsText("$Sell", "$Exit");
		}
		super.onShowItemsList(event);
	}
	
	function onHideItemsList(event)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("BarterMenu onHideItemsList()");
		super.onHideItemsList(event);
		BottomBar_mc.SetButtonsText("", "$Exit");
	}

	function IsViewingVendorItems()
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("BarterMenu IsViewingVendorItems()");
		var divider = InventoryLists_mc.CategoriesList.dividerIndex;
		return divider != undefined && _selectedCategory < divider;
	}

	function onQuantityMenuSelect(event)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("BarterMenu onQuantityMenuSelect()");
		var price = event.amount * ItemCard_mc.itemInfo.value;
		if (price > _vendorGold && !IsViewingVendorItems()) 
		{
			_confirmAmount = event.amount;
			GameDelegate.call("GetRawDealWarningString", [price], this, "ShowRawDealWarning");
			return;
		}
		doTransaction(event.amount);
	}

	function ShowRawDealWarning(strWarning)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("BarterMenu ShowRawDealWarning()");
		ItemCard_mc.ShowConfirmMessage(strWarning);
	}

	function onTransactionConfirm()
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("BarterMenu onTransactionConfirm()");
		doTransaction(_confirmAmount);
		_confirmAmount = 0;
	}

	function doTransaction(aiAmount)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("BarterMenu doTransaction()");
		GameDelegate.call("ItemSelect", [aiAmount, ItemCard_mc.itemInfo.value, IsViewingVendorItems()]);
	}

	function UpdateItemCardInfo(aUpdateObj)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("BarterMenu UpdateItemCardInfo()");
		if (IsViewingVendorItems()) 
		{
			aUpdateObj.value = aUpdateObj.value * _buyMult;
			aUpdateObj.value = Math.max(aUpdateObj.value, 1);
		}
		else 
		{
			aUpdateObj.value = aUpdateObj.value * _sellMult;
		}
		aUpdateObj.value = Math.floor(aUpdateObj.value + 0.5);
		ItemCard_mc.itemInfo = aUpdateObj;
		BottomBar_mc.SetBarterPerItemInfo(aUpdateObj, _playerInfoObj);
	}

	function UpdatePlayerInfo(a_playerGold, a_vendorGold, astrVendorName, aUpdateObj)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("BarterMenu UpdatePlayerInfo()");
		_vendorGold = a_vendorGold;
		_playerGold = a_playerGold;
		BottomBar_mc.SetBarterInfo(a_playerGold, a_vendorGold, undefined, astrVendorName);
		_playerInfoObj = aUpdateObj;
	}

	function onQuantitySliderChange(event)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("BarterMenu onQuantitySliderChange()");
		var price = ItemCard_mc.itemInfo.value * event.value;
		if (IsViewingVendorItems()) 
		{
			price = price * -1;
		}
		BottomBar_mc.SetBarterInfo(_playerGold, _vendorGold, price);
	}

	function onItemCardSubMenuAction(event)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("BarterMenu onItemCardSubMenuAction()");
		super.onItemCardSubMenuAction(event);
		if (event.menu == "quantity") 
		{
			if (event.opening) 
			{
				onQuantitySliderChange({value: ItemCard_mc.itemInfo.count});
				// disable tab change while quantity menu is open
				InventoryLists_mc.TabBar._bAllowPress = false;
				return;
			}
			else if (event.opening == false) {
				InventoryLists_mc.TabBar._bAllowPress = true;
			}
			BottomBar_mc.SetBarterInfo(_playerGold, _vendorGold);
		}
	}

}
