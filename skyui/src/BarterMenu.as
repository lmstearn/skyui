import skyui.InventoryColumnFormatter;
import skyui.BarterDataFetcher;
import skyui.TabBar;
import gfx.ui.NavigationCode;

dynamic class BarterMenu extends ItemMenu
{
	private var bPCControlsReady: Boolean = true;
	private var BottomBar_mc:MovieClip;
	private var InventoryLists_mc:MovieClip;
	private var ItemCard_mc:MovieClip;
	private var PlayerInfoObj;
	private var fBuyMult:Number;
	private var fSellMult:Number;
	private var iConfirmAmount;
	private var iPlayerGold:Number;
	private var iSelectedCategory;
	private var iVendorGold:Number;
	private var _CategoriesList;
	private var _tabBar:TabBar;
	private var _viewingVendorItems:Boolean;
	private var _prevSelectedTab:Number;
	private var _bAllowTabs:Boolean;
	
	//var CategoryListIconArt:Array;
	
	var ColumnFormatter:InventoryColumnFormatter;
	var DataFetcher:BarterDataFetcher;

	function BarterMenu()
	{
		super();
		fBuyMult = 1;
		fSellMult = 1;
		iVendorGold = 0;
		iPlayerGold = 0;
		iConfirmAmount = 0;
		_viewingVendorItems = true;
		_bAllowTabs = true;
		
		/*CategoryListIconArt = ["cat_favorites", "inv_all", "inv_weapons", "inv_armor",
							   "inv_potions", "inv_scrolls", "inv_food", "inv_ingredients",
							   "inv_books", "inv_keys", "inv_misc"];*/
		
		ColumnFormatter = new InventoryColumnFormatter();
		ColumnFormatter.maxTextLength = 80;
		
		DataFetcher = new BarterDataFetcher();
		
		_tabBar = InventoryLists_mc.panelContainer.tabBar;
	}

	function InitExtensions()
	{
		super.InitExtensions();
		gfx.io.GameDelegate.addCallBack("SetBarterMultipliers", this, "SetBarterMultipliers");
		this.ItemCard_mc.addEventListener("messageConfirm", this, "onTransactionConfirm");
		this.ItemCard_mc.addEventListener("sliderChange", this, "onQuantitySliderChange");
		InventoryLists_mc.addEventListener("itemHighlightChange",this,"onShowItemsList");
		this.BottomBar_mc.SetButtonArt({PCArt: "Tab", XBoxArt: "360_B", PS3Art: "PS3_B"}, 1);
		this.BottomBar_mc.Button1.addEventListener("click", this, "onExitButtonPress");
		this.BottomBar_mc.Button1.disabled = false;
		
		//InventoryLists_mc.CategoriesList.setIconArt(CategoryListIconArt);
		_CategoriesList = InventoryLists_mc.panelContainer.categoriesList;
		// Show vendor items when opening menu for first time
		_CategoriesList._bViewingVendorItems = true;

		InventoryLists_mc.ItemsList.entryClassName = "ItemsListEntryInv";
		InventoryLists_mc.ItemsList.columnFormatter = ColumnFormatter;
		InventoryLists_mc.ItemsList.dataFetcher = DataFetcher;
		InventoryLists_mc.ItemsList.setConfigSection("BarterItemList");
	
		_tabBar.addEventListener("tabPress",this,"onTabPress");
	}
	
	function handleInput(details, pathToFocus)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("BarterMenu handleInput()");
		if (_bFadedIn) {
			if (!pathToFocus[0].handleInput(details, pathToFocus.slice(1))) {
				if (GlobalFunc.IsKeyPressed(details) && details.navEquivalent == NavigationCode.TAB) {
					GameDelegate.call("CloseMenu",[]);
				}
			}
			else if (details.navEquivalent == NavigationCode.TAB) {
					GameDelegate.call("CloseMenu",[]);
					// Allow tab selection, fixes quantity menu bug
					_bAllowTabs = true;
			}
		} 
		return true;
	}

	function onTabPress(event)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("BarterMenu onTabChange()");
		if (_bAllowTabs)
		{
			if (event.index == 1 && event.index != _prevSelectedTab) // buy
			{
				InventoryLists_mc.ItemsList.dataFetcher._barterMult = this.fBuyMult;
				_CategoriesList.isViewingVendorItems(true);
				InventoryLists_mc.ItemsList.InvalidateData();
				_viewingVendorItems = true;
				this.BottomBar_mc.SetButtonsText("$Buy", "$Exit");
			}
			else if (event.index == 2 && event.index != _prevSelectedTab) // sell
			{
				InventoryLists_mc.ItemsList.dataFetcher._barterMult = this.fSellMult;
				_CategoriesList.isViewingVendorItems(false);
				InventoryLists_mc.ItemsList.InvalidateData();
				_viewingVendorItems = false;
				this.BottomBar_mc.SetButtonsText("$Sell", "$Exit");
			}
			_prevSelectedTab = event.index;
		}
	}

	function onExitButtonPress()
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("BarterMenu onExitButtonPress()");
		gfx.io.GameDelegate.call("CloseMenu", []);
	}

	function SetBarterMultipliers(afBuyMult, afSellMult)
	{
		if (DEBUG_LEVEL > 0)_global.skse.Log("BarterMenu SetBarterMultipliers()");
		this.fBuyMult = afBuyMult;
		this.fSellMult = afSellMult;
		// set initial multiplier for datafetcher
		InventoryLists_mc.ItemsList.dataFetcher._barterMult = this.fBuyMult;
		this.BottomBar_mc.SetButtonsText("", "$Exit");
	}

	function onShowItemsList(event)
	{
		this.iSelectedCategory = this.InventoryLists_mc.CategoriesList.selectedIndex;
		if (DEBUG_LEVEL > 0) _global.skse.Log("BarterMenu onShowItemsList() iSelectedCategory = " + this.iSelectedCategory);
		if (this.IsViewingVendorItems())
		{
			this.BottomBar_mc.SetButtonsText("$Buy", "$Exit");
		}
		else
		{
			this.BottomBar_mc.SetButtonsText("$Sell", "$Exit");
		}
		super.onShowItemsList(event);
	}
	
	function onHideItemsList(event)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("BarterMenu onHideItemsList()");
		super.onHideItemsList(event);
		this.BottomBar_mc.SetButtonsText("", "$Exit");
	}

	function IsViewingVendorItems()
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("BarterMenu IsViewingVendorItems()");
		return _viewingVendorItems;
	}

	function onQuantityMenuSelect(event)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("BarterMenu onQuantityMenuSelect()");
		var price = event.amount * this.ItemCard_mc.itemInfo.value;
		if (price > this.iVendorGold && !this.IsViewingVendorItems()) 
		{
			this.iConfirmAmount = event.amount;
			gfx.io.GameDelegate.call("GetRawDealWarningString", [price], this, "ShowRawDealWarning");
			return;
		}
		this.doTransaction(event.amount);
		// allow tabs after transaction
		_bAllowTabs = true;
	}

	function ShowRawDealWarning(strWarning)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("BarterMenu ShowRawDealWarning()");
		this.ItemCard_mc.ShowConfirmMessage(strWarning);
	}

	function onTransactionConfirm()
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("BarterMenu onTransactionConfirm()");
		this.doTransaction(this.iConfirmAmount);
		this.iConfirmAmount = 0;
	}

	function doTransaction(aiAmount)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("BarterMenu doTransaction()");
		gfx.io.GameDelegate.call("ItemSelect", [aiAmount, this.ItemCard_mc.itemInfo.value, this.IsViewingVendorItems()]);
	}

	function UpdateItemCardInfo(aUpdateObj)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("BarterMenu UpdateItemCardInfo()");
		if (this.IsViewingVendorItems()) 
		{
			aUpdateObj.value = aUpdateObj.value * this.fBuyMult;
			aUpdateObj.value = Math.max(aUpdateObj.value, 1);
		}
		else 
		{
			aUpdateObj.value = aUpdateObj.value * this.fSellMult;
		}
		aUpdateObj.value = Math.floor(aUpdateObj.value + 0.5);
		this.ItemCard_mc.itemInfo = aUpdateObj;
		this.BottomBar_mc.SetBarterPerItemInfo(aUpdateObj, this.PlayerInfoObj);
	}

	function UpdatePlayerInfo(aiPlayerGold, aiVendorGold, astrVendorName, aUpdateObj)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("BarterMenu UpdatePlayerInfo()");
		this.iVendorGold = aiVendorGold;
		this.iPlayerGold = aiPlayerGold;
		this.BottomBar_mc.SetBarterInfo(aiPlayerGold, aiVendorGold, undefined, astrVendorName);
		this.PlayerInfoObj = aUpdateObj;
	}

	function onQuantitySliderChange(event)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("BarterMenu onQuantitySliderChange()");
		var __reg2 = this.ItemCard_mc.itemInfo.value * event.value;
		if (this.IsViewingVendorItems()) 
		{
			__reg2 = __reg2 * -1;
		}
		this.BottomBar_mc.SetBarterInfo(this.iPlayerGold, this.iVendorGold, __reg2);
	}

	function onItemCardSubMenuAction(event)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("BarterMenu onItemCardSubMenuAction()");
		super.onItemCardSubMenuAction(event);
		if (event.menu == "quantity") 
		{
			if (event.opening) 
			{
				this.onQuantitySliderChange({value: this.ItemCard_mc.itemInfo.count});
				// disable tabs while quantity menu is open
				_bAllowTabs = false;
				return;
			}
			this.BottomBar_mc.SetBarterInfo(this.iPlayerGold, this.iVendorGold);
		}
	}

}
