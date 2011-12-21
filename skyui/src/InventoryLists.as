import gfx.io.GameDelegate;
import gfx.ui.NavigationCode;
import gfx.events.EventDispatcher;
import gfx.managers.FocusHandler;

import Shared.GlobalFunc;

import skyui.HorizontalList;
import skyui.InventoryItemList;
import skyui.ItemTypeFilter;
import skyui.ItemNameFilter;
import skyui.ItemSortingFilter;
import skyui.SortedListHeader;
import skyui.SearchWidget;
import skyui.Config;
import skyui.Util;

class InventoryLists extends MovieClip
{
	static var HIDE_PANEL = 0;
	static var SHOW_PANEL = 1;
	static var TRANSITIONING_TO_HIDE_PANEL = 2;
	static var TRANSITIONING_TO_SHOW_PANEL = 3;

	private var _config;

	private var _CategoriesList:HorizontalList;
	private var _CategoryLabel:MovieClip;
	private var _ItemsList:InventoryItemList;
	private var _SearchWidget:SearchWidget;

	private var _platform:Number;
	private var _currentState:Number;

	private var _typeFilter:ItemTypeFilter;
	private var _catTypeFilter:ItemTypeFilter;
	private var _nameFilter:ItemNameFilter;
	private var _sortFilter:ItemSortingFilter;

	private var _currCategoryIndex:Number;

	private var _searchKey:Number;

	// Children
	var panelContainer:MovieClip;

	// Mixin
	var dispatchEvent:Function;
	var addEventListener:Function;


	function InventoryLists()
	{
		super();
		Util.addArrayFunctions();

		_CategoriesList = panelContainer.categoriesList;
		_CategoryLabel = panelContainer.CategoryLabel;
		_ItemsList = panelContainer.itemsList;
		_SearchWidget = panelContainer.searchWidget;

		EventDispatcher.initialize(this);

		gotoAndStop("NoPanels");

		GameDelegate.addCallBack("SetCategoriesList",this,"SetCategoriesList");
		GameDelegate.addCallBack("InvalidateListData",this,"InvalidateListData");

		_typeFilter = new ItemTypeFilter();
		_catTypeFilter = new ItemTypeFilter();
		_nameFilter = new ItemNameFilter();
		_sortFilter = new ItemSortingFilter();

		_searchKey = undefined;

		Config.instance.addEventListener("configLoad",this,"onConfigLoad");
	}

	function onLoad()
	{
		_global.skse.Log("InventoryLists onLoad()");
		_ItemsList.addFilter(_typeFilter);
		_ItemsList.addFilter(_nameFilter);
		_ItemsList.addFilter(_sortFilter);
		_CategoriesList.addFilter(_catTypeFilter);

		_typeFilter.addEventListener("filterChange",_ItemsList,"onFilterChange");
		_nameFilter.addEventListener("filterChange",_ItemsList,"onFilterChange");
		_sortFilter.addEventListener("filterChange",_ItemsList,"onFilterChange");
		_catTypeFilter.addEventListener("filterChange",_CategoriesList,"onFilterChange");

		_CategoriesList.addEventListener("itemPress",this,"onCategoriesItemPress");
		_CategoriesList.addEventListener("listPress",this,"onCategoriesListPress");
		_CategoriesList.addEventListener("listMovedUp",this,"onCategoriesListMoveUp");
		_CategoriesList.addEventListener("listMovedDown",this,"onCategoriesListMoveDown");
		_CategoriesList.addEventListener("selectionChange",this,"onCategoriesListMouseSelectionChange");

		_ItemsList.maxTextLength = 100;
		_ItemsList.disableInput = false;

		_ItemsList.addEventListener("listMovedUp",this,"onItemsListMoveUp");
		_ItemsList.addEventListener("listMovedDown",this,"onItemsListMoveDown");
		_ItemsList.addEventListener("selectionChange",this,"onItemsListMouseSelectionChange");
		_ItemsList.addEventListener("sortChange",this,"onSortChange");

		_SearchWidget.addEventListener("inputStart",this,"onSearchInputStart");
		_SearchWidget.addEventListener("inputEnd",this,"onSearchInputEnd");
		_SearchWidget.addEventListener("inputChange",this,"onSearchInputChange");
	}

	function onConfigLoad(event)
	{
		_config = event.config;
		_searchKey = _config.SearchBox.hotkey;
	}

	function SetPlatform(a_platform:Number, a_bPS3Switch:Boolean)
	{
		_global.skse.Log("InventoryLists SetPlatform()");
		_platform = a_platform;

		_CategoriesList.setPlatform(a_platform,a_bPS3Switch);
		_ItemsList.setPlatform(a_platform,a_bPS3Switch);
	}

	function handleInput(details, pathToFocus)
	{
		_global.skse.Log("InventoryLists handleInput()");
		var bCaught = false;

		if (_currentState == SHOW_PANEL)
		{
			if (GlobalFunc.IsKeyPressed(details))
			{
				if (details.navEquivalent == NavigationCode.LEFT || details.navEquivalent == NavigationCode.GAMEPAD_L1)
				{
					//if (_CategoriesList.selectedIndex == 0 && _CategoriesList.selectedEntry.flag != 1047552 && _CategoriesList.selectedEntry.flag != 10)
					if (_CategoriesList.selectedIndex > 0)
					{
						_global.skse.Log("InventoryLists handleInput() navigation LWDR");
						_CategoriesList.moveSelectionLeft();
						bCaught = true;
					}
					else
					{
						_global.skse.Log("InventoryLists handleInput() exitMenuRect");
						_parent.onExitMenuRectClick();
					}

				}
				else if (details.navEquivalent == NavigationCode.RIGHT || details.navEquivalent == NavigationCode.GAMEPAD_R1)
				{
					_global.skse.Log("InventoryLists handleInput() navigation RIGHT");
					_CategoriesList.moveSelectionRight();
					bCaught = true;

					// Search hotkey (default space)
				}
				else if (details.code == _searchKey)
				{
					_global.skse.Log("InventoryLists handleInput() details.code = " + details.code + " , searchKey = " + _searchKey);
					bCaught = true;
					_SearchWidget.startInput();
				}
			}
			if (!bCaught)
			{
				bCaught = pathToFocus[0].handleInput(details, pathToFocus.slice(1));
				_global.skse.Log("InventoryLists handleInput() bCaught = " + bCaught);
			}


		}
		return bCaught;
	}

	function getContentBounds():Array
	{
		var lb = panelContainer.ListBackground;
		return [lb._x, lb._y, lb._width, lb._height];
	}

	function get CategoriesList()
	{
		return _CategoriesList;
	}

	function get ItemsList()
	{
		return _ItemsList;
	}

	function get currentState()
	{
		return _currentState;
	}

	function set currentState(a_newState)
	{
		_global.skse.Log("InventoryLists currentState(aiNewState) set currentState to " + a_newState);
		if (a_newState == SHOW_PANEL)
		{
			FocusHandler.instance.setFocus(_ItemsList,0);
		}

		_currentState = a_newState;
	}

	function RestoreCategoryIndex()
	{
		_global.skse.Log("InventoryLists RestoreCategoryIndex()");
		_CategoriesList.selectedIndex = _currCategoryIndex;
	}

	function ShowCategoriesList(a_bPlayBladeSound:Boolean)
	{
		_global.skse.Log("InventoryLists ShowCategoriesList()");
		_currentState = TRANSITIONING_TO_SHOW_PANEL;
		gotoAndPlay("PanelShow");

		dispatchEvent({type:"categoryChange", index:_CategoriesList.selectedIndex});

		if (a_bPlayBladeSound != false)
		{
			GameDelegate.call("PlaySound",["UIMenuBladeOpenSD"]);
		}
	}

	function HideCategoriesList()
	{
		_global.skse.Log("InventoryLists HideCategoriesList()");
		_currentState = TRANSITIONING_TO_HIDE_PANEL;
		gotoAndPlay("PanelHide");
		GameDelegate.call("PlaySound",["UIMenuBladeCloseSD"]);
	}


	/*Default reactions:
	"showItemsList" with index == -1: Do nothing
	"showItemsList" with index != -1: Fade in item card and bottom bar icons, update 3d icon
	"itemHighlightChange" with index == -1: Fade out item card, hide bottom bar icons and 3d icon
	"itemHighlightChange" with index != -1: Update item card, update 3d model
	
	showItemsList() is called to trigger an update of the item list.
	it has to call itemHighlightChange with index -1 and set _bFirstSelectionFlag to true.
	onItemsListMouseSelectionChange() then dispatches
	"showItemsList" and sets _bFirstSelectionFlag=false, if _bFirstSelectionFlag was true
	"itemHighlightChange", if _bFirstSelectionFlag was false
	*/
	function showItemsList()
	{
		_global.skse.Log("InventoryLists ShowItemsList()");
		_currCategoryIndex = _CategoriesList.selectedIndex;

		_CategoryLabel.textField.SetText(_CategoriesList.selectedEntry.text);

		// Let's do this more elegant at some point.. :)
		// Changing the sort filter might already trigger an update, so the final UpdateList is redudant

		// Start with no selection
		_ItemsList.selectedIndex = -1;
		_global.skse.Log("Category selectedEntry = " + _CategoriesList.selectedEntry.text);
		if (_CategoriesList.selectedEntry != undefined)
		{
			// Set filter type before update
			_global.skse.Log("CHANGE DETECTED! Setting filter flags to sort");
			_typeFilter.itemFilter = _CategoriesList.selectedEntry.flag;

			//_ItemsList.statType = _CategoriesList.selectedEntry.flag;
			_currCategoryIndex = _CategoriesList.selectedIndex;
			_ItemsList.changeFilterFlag(_CategoriesList.selectedEntry.flag);


			_ItemsList.RestoreScrollPosition(_CategoriesList.selectedEntry.savedItemIndex);
		}
		else
		{
			_ItemsList.UpdateList();
		}

		dispatchEvent({type:"itemHighlightChange", index:_ItemsList.selectedIndex});

		_ItemsList.disableInput = false;
		GameDelegate.call("PlaySound",["UIMenuFocus"]);
	}

	// Not needed anymore, items list always visible
	function hideItemsList()
	{
		_global.skse.Log("InventoryLists HideItemsList()");
		//_currentState = TRANSITIONING_TO_ONE_PANEL;
		//dispatchEvent({type:"hideItemsList", index:_ItemsList.selectedIndex});
		//_ItemsList.selectedIndex = -1;
		//gotoAndPlay("Panel2Hide");
		//GameDelegate.call("PlaySound",["UIMenuBladeCloseSD"]);
		//_ItemsList.disableInput = true;
	}

	function onCategoriesItemPress()
	{
		_global.skse.Log("InventoryLists onCategoriesItemPress()");
		showItemsList();
	}

	function onCategoriesListPress()
	{
		_global.skse.Log("InventoryLists onCategoriesListPress()");
	}

	function onCategoriesListMoveUp(event)
	{
		_global.skse.Log("InventoryLists onCategoriesListMoveUp()");
		doCategorySelectionChange(event);
	}

	function onCategoriesListMoveDown(event)
	{
		_global.skse.Log("InventoryLists onCategoriesListMoveDown()");
		doCategorySelectionChange(event);
	}

	function onCategoriesListMouseSelectionChange(event)
	{
		_global.skse.Log("InventoryLists onCategoriesListMouseSelectionChange()");
		if (event.keyboardOrMouse == 0)
		{
			doCategorySelectionChange(event);
		}
	}

	function onItemsListMoveUp(event)
	{
		_global.skse.Log("InventoryLists onItemsListMoveUp()");
		this.doItemsSelectionChange(event);
	}

	function onItemsListMoveDown(event)
	{
		_global.skse.Log("InventoryLists onItemsListMoveDown()");
		this.doItemsSelectionChange(event);
	}

	function onItemsListMouseSelectionChange(event)
	{
		_global.skse.Log("InventoryLists onItemsListMouseSelectionChange()");
		if (event.keyboardOrMouse == 0)
		{
			doItemsSelectionChange(event);
		}
	}

	function doCategorySelectionChange(event)
	{
		_global.skse.Log("InventoryLists doCategorySelectionChange()");
		dispatchEvent({type:"categoryChange", index:event.index});

		if (event.index != -1)
		{
			GameDelegate.call("PlaySound",["UIMenuFocus"]);
		}
	}

	function doItemsSelectionChange(event)
	{
		_global.skse.Log("InventoryLists onItemsSelectionChange()");
		_CategoriesList.selectedEntry.savedItemIndex = _ItemsList.scrollPosition;

			dispatchEvent({type:"itemHighlightChange", index:event.index});

		if (event.index != -1) {
			GameDelegate.call("PlaySound",["UIMenuFocus"]);
		}
	}

	function onSortChange(event)
	{
		_sortFilter.setSortBy(event.attributes,event.options);
	}

	function onSearchInputStart(event)
	{
		_CategoriesList.disableSelection = true;
		_ItemsList.disableInput = true;
		_nameFilter.filterText = "";
	}

	function onSearchInputChange(event)
	{
		_nameFilter.filterText = event.data;
	}

	function onSearchInputEnd(event)
	{
		_CategoriesList.disableSelection = false;
		_ItemsList.disableInput = false;
		_nameFilter.filterText = event.data;
	}

	// API - Called to initially set the category list
	function SetCategoriesList()
	{
		_global.skse.Log("InventoryLists SetCategoriesList()");
		var textOffset = 0;
		var flagOffset = 1;
		var bDontHideOffset = 2;
		var len = 3;

		_CategoriesList.clearList();

		for (var i = 0; i < arguments.length; i = i + len)
		{
			var entry = {text:arguments[i + textOffset], flag:arguments[i + flagOffset], bDontHide:arguments[i + bDontHideOffset], savedItemIndex:0, filterFlag:arguments[i + bDontHideOffset] == true ? (1) : (0)};
			// If flag = 0 then category is a divider.
			if (entry.flag == 0)
			{
				entry.divider = true;
			}
			_CategoriesList.entryList.push(entry);
		}
		_CategoriesList.InvalidateData();
	}

	// API - Called whenever the underlying entryList data is updated (using an item, equipping etc.)
	function InvalidateListData()
	{
		_global.skse.Log("InventoryLists InvalidateListData()");
		var flag = _CategoriesList.selectedEntry.flag;

		for (var i = 0; i < _CategoriesList.entryList.length; i++)
		{
			_CategoriesList.entryList[i].filterFlag = _CategoriesList.entryList[i].bDontHide ? 1 : 0;
		}

		_ItemsList.InvalidateData();
		for (var i = 0; i < _ItemsList.entryList.length; i++)
		{
			for (var j = 0; j < _CategoriesList.entryList.length; ++j)
			{
				if (_CategoriesList.entryList[j].filterFlag != 0)
				{
					continue;
				}
				//_global.skse.Log("Item entry " + _ItemsList.entryList[i].text + ", filterFlag = " + _ItemsList.entryList[i].filterFlag);  
				// if Barter and Player both share an item of same category then enable the category
				if (_ItemsList.entryList[i].filterFlag & _CategoriesList.entryList[j].flag)
				{
					_global.skse.Log("setting category " + _CategoriesList.entryList[j].text + " filterFlag to 1");
					_CategoriesList.entryList[j].filterFlag = 1;
				}
			}
		}
		_global.skse.Log("InventoryLists catTypeFilter init");
		_catTypeFilter.categoryFilterChange();

		_CategoriesList.UpdateList();

		if (flag != _CategoriesList.selectedEntry.flag)
		{
			// Triggers an update if filter flag changed
			_typeFilter.itemFilter = _CategoriesList.selectedEntry.flag;
			dispatchEvent({type:"categoryChange", index:_CategoriesList.selectedIndex});
		}
		// This is called when an ItemCard list closes(ex. ShowSoulGemList) to refresh ItemCard data 
		if (_currentState != SHOW_PANEL) {
		_ItemsList.selectedIndex = -1;
		} else {
		dispatchEvent({type:"itemHighlightChange", index:_ItemsList.selectedIndex});
		}
	}
}