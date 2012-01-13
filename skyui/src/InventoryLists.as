import gfx.io.GameDelegate;
import gfx.ui.NavigationCode;
import gfx.events.EventDispatcher;
import gfx.managers.FocusHandler;

import Shared.GlobalFunc;

import skyui.CategoryList;
import skyui.FormattedItemList; // This scrollingStop(); on any key press
import skyui.ItemTypeFilter;
import skyui.ItemNameFilter;
import skyui.ItemSortingFilter;
import skyui.SortedListHeader;
import skyui.SearchWidget;
import skyui.TabBar;
import skyui.Config;
import skyui.Util;


class InventoryLists extends MovieClip
{
	static var HIDE_PANEL = 0;
	static var SHOW_PANEL = 1;
	static var TRANSITIONING_TO_HIDE_PANEL = 2;
	static var TRANSITIONING_TO_SHOW_PANEL = 3;

	private var _config:Config;

	private var _CategoriesList:CategoryList;
	private var _CategoryLabel:MovieClip;
	private var _ItemsList:FormattedItemList;
	private var _SearchWidget:SearchWidget;
	private var _TabBar:TabBar;

	private var _platform:Number;
	private var _currentState:Number;

	private var _typeFilter:ItemTypeFilter;
	private var _nameFilter:ItemNameFilter;
	private var _sortFilter:ItemSortingFilter;

	private var _currCategoryIndex:Number;

	private var _searchKey:Number;
	private var _tabToggleKey:Number;

	// Children
	var panelContainer:MovieClip;

	// Mixin
	var dispatchEvent:Function;
	var addEventListener:Function;

	static var DEBUG_LEVEL = 1;
	// timers
	var startTime:Date;
	var endTime:Date;

	function InventoryLists()
	{
		super();

		Util.addArrayFunctions();

		_CategoriesList = panelContainer.categoriesList;
		_CategoryLabel = panelContainer.CategoryLabel;
		_ItemsList = panelContainer.itemsList;
		_SearchWidget = panelContainer.searchWidget;
		_TabBar = panelContainer.tabBar;

		EventDispatcher.initialize(this);

		gotoAndStop("NoPanels");

		GameDelegate.addCallBack("SetCategoriesList",this,"SetCategoriesList");
		GameDelegate.addCallBack("InvalidateListData",this,"InvalidateListData");

		_typeFilter = new ItemTypeFilter();
		_nameFilter = new ItemNameFilter();
		_sortFilter = new ItemSortingFilter();

		_searchKey = undefined;
		_tabToggleKey = undefined;

		Config.instance.addEventListener("configLoad",this,"onConfigLoad");
	}

	function onLoad()
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("InventoryLists onLoad()");
		_ItemsList.addFilter(_typeFilter);
		_ItemsList.addFilter(_nameFilter);
		_ItemsList.addFilter(_sortFilter);

		_typeFilter.addEventListener("filterChange",_ItemsList,"onFilterChange");
		_nameFilter.addEventListener("filterChange",_ItemsList,"onFilterChange");
		_sortFilter.addEventListener("filterChange",_ItemsList,"onFilterChange");

		_CategoriesList.addEventListener("itemPress",this,"onCategoriesItemPress");
		_CategoriesList.addEventListener("listPress",this,"onCategoriesListPress");
		_CategoriesList.addEventListener("listMovedUp",this,"onCategoriesListMoveUp");
		_CategoriesList.addEventListener("listMovedDown",this,"onCategoriesListMoveDown");
		_CategoriesList.addEventListener("selectionChange",this,"onCategoriesListMouseSelectionChange");

		_ItemsList.disableInput = false;

		_ItemsList.addEventListener("listMovedUp",this,"onItemsListMoveUp");
		_ItemsList.addEventListener("listMovedDown",this,"onItemsListMoveDown");
		_ItemsList.addEventListener("selectionChange",this,"onItemsListMouseSelectionChange");
		_ItemsList.addEventListener("sortChange",this,"onSortChange");

		_SearchWidget.addEventListener("inputStart",this,"onSearchInputStart");
		_SearchWidget.addEventListener("inputEnd",this,"onSearchInputEnd");
		_SearchWidget.addEventListener("inputChange",this,"onSearchInputChange");
		
		if (_TabBar != undefined) {
			_TabBar.addEventListener("tabPress",this,"onTabPress");
		}
	}

	function onConfigLoad(event)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("InventoryLists onConfigLoad()");
		_config = event.config;
		_searchKey = _config.Input.hotkey.search;
		_tabToggleKey = _config.Input.hotkey.tabToggle;
	}

	function SetPlatform(a_platform:Number, a_bPS3Switch:Boolean)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("InventoryLists SetPlatform()");
		_platform = a_platform;

		_CategoriesList.setPlatform(a_platform,a_bPS3Switch);
		_ItemsList.setPlatform(a_platform,a_bPS3Switch);
	}

	function handleInput(details, pathToFocus)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("InventoryLists handleInput()");
		var bCaught = false;
		
		if (_currentState == SHOW_PANEL) {
			if (GlobalFunc.IsKeyPressed(details)) {
				
				if (details.navEquivalent == NavigationCode.LEFT) {
                    _ItemsList.scrollingRepeatStop();
					_CategoriesList.moveSelectionLeft();
					bCaught = true;

				} else if (details.navEquivalent == NavigationCode.RIGHT) {
                    _ItemsList.scrollingRepeatStop();
					_CategoriesList.moveSelectionRight();
					bCaught = true;

				// Search hotkey (default space)
				} else if (details.code == _searchKey) {
                    _ItemsList.scrollingRepeatStop();
					bCaught = true;
					_SearchWidget.startInput();
					
				// Toggle tab (default ALT)
				} else if (_TabBar != undefined && (details.code == _tabToggleKey || (details.navEquivalent == NavigationCode.GAMEPAD_BACK && details.code != 8))) {
					_ItemsList.scrollingRepeatStop();
					bCaught = true;
					_TabBar.tabToggle();
				}
			}
			if (!bCaught) {
				bCaught = pathToFocus[0].handleInput(details, pathToFocus.slice(1));
			}
		}
		return bCaught;
	}

	function getContentBounds():Array
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("InventoryLists getContentBounds()");
		var lb = panelContainer.ListBackground;
		return [lb._x, lb._y, lb._width, lb._height];
	}

	function get CategoriesList()
	{
		if (DEBUG_LEVEL > 1) _global.skse.Log("InventoryLists get CategoriesList()");
		return _CategoriesList;
	}

	function get ItemsList()
	{
		if (DEBUG_LEVEL > 1) _global.skse.Log("InventoryLists get ItemsList()");
		return _ItemsList;
	}
	
	function get TabBar()
	{
		return _TabBar;
	}

	function get currentState()
	{
		return _currentState;
	}

	function set currentState(a_newState)
	{
	    if (DEBUG_LEVEL > 1) _global.skse.Log("InventoryLists currentState(aiNewState) set currentState to " + a_newState);
		if (a_newState == SHOW_PANEL) {
			FocusHandler.instance.setFocus(_ItemsList,0);
		}

		_currentState = a_newState;
	}

	function RestoreCategoryIndex()
	{
		_CategoriesList.selectedIndex = _currCategoryIndex;
	}

	function ShowCategoriesList(a_bPlayBladeSound:Boolean)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("InventoryLists ShowCategoriesList()");
		_currentState = TRANSITIONING_TO_SHOW_PANEL;
		gotoAndPlay("PanelShow");

		dispatchEvent({type:"categoryChange", index:_CategoriesList.selectedIndex});

		if (a_bPlayBladeSound != false) {
			GameDelegate.call("PlaySound",["UIMenuBladeOpenSD"]);
		}
	}

	function HideCategoriesList()
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("InventoryLists HideCategoriesList()");
		_currentState = TRANSITIONING_TO_HIDE_PANEL;
		gotoAndPlay("PanelHide");
		GameDelegate.call("PlaySound",["UIMenuBladeCloseSD"]);
	}

	function showItemsList()
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("InventoryLists ShowItemsList()");
		skse.Log("initializing timer for showItemsList()...");
		var startShowItemListTime:Date = new Date();
		
		_currCategoryIndex = _CategoriesList.selectedIndex;
		// set category label
		_CategoryLabel.textField.SetText(_CategoriesList.selectedEntry.text);
		
		if (_CategoriesList.selectedEntry != undefined) {
			skse.Log("PHASE 1  - CHANGING ITEM FILTER FLAG...");
			_typeFilter.changeFilterFlag(_CategoriesList.selectedEntry.flag, true);
			skse.Log("PHASE 2  - UPDATING COLUMNS, REFRESHING DATA...");
			_ItemsList.savedScrollPosition = _CategoriesList.selectedEntry.savedScrollPosition;
			_ItemsList.changeFilterFlag(_CategoriesList.selectedEntry.flag);
			skse.Log("PHASE 3  - SELECTED SAVED ITEM...");
			if (_CategoriesList.selectedEntry.savedItemIndex != -1)
				_ItemsList.doSetSelectedIndex(_CategoriesList.selectedEntry.savedItemIndex);
		} 
		
		dispatchEvent({type:"itemHighlightChange", index:_ItemsList.selectedIndex});
		
		_ItemsList.disableInput = false;
		var endShowItemListTime:Date = new Date();
		skse.Log("Time elapsed to execute showItemsList "+String(endShowItemListTime.getTime()-startShowItemListTime.getTime())+" milliseconds");
		endTime = new Date();
		skse.Log("ENDED MAIN START TIMER.");
		skse.Log("Menu opened in : "+String(endTime.getTime()-startTime.getTime())+" milliseconds");
	}

	// Not needed anymore, items list always visible
	function hideItemsList()
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("InventoryLists hideItemsList()");
		/*
		_currentState = TRANSITIONING_TO_ONE_PANEL;
		dispatchEvent({type:"hideItemsList", index:_ItemsList.selectedIndex});
		_ItemsList.selectedIndex = -1;
		gotoAndPlay("Panel2Hide");
		GameDelegate.call("PlaySound",["UIMenuBladeCloseSD"]);
		_ItemsList.disableInput = true;
		*/
	}

	function onCategoriesItemPress()
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("InventoryLists onCategoriesItemPress()");
		showItemsList();
	}

	function onCategoriesListPress()
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("InventoryLists onCategoriesListPress()");
	}

	function onTabPress(event)
	{
		if (_CategoriesList.disableSelection || _CategoriesList.disableInput || _ItemsList.disableSelection || _ItemsList.disableInput) {
			return;
		}
		
		if (event.index == TabBar.LEFT_TAB) {
			_TabBar.activeTab = TabBar.LEFT_TAB;
			_CategoriesList.activeSegment = CategoryList.LEFT_SEGMENT;
		} else if (event.index == TabBar.RIGHT_TAB) {
			_TabBar.activeTab = TabBar.RIGHT_TAB;
			_CategoriesList.activeSegment = CategoryList.RIGHT_SEGMENT;
		}
		
		GameDelegate.call("PlaySound",["UIMenuBladeOpenSD"]);
		showItemsList();
	}

	function onCategoriesListMoveUp(event)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("InventoryLists onCategoriesListMoveUp()");
		doCategorySelectionChange(event);
	}

	function onCategoriesListMoveDown(event)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("InventoryLists onCategoriesListMoveDown()");
		doCategorySelectionChange(event);
	}

	function onCategoriesListMouseSelectionChange(event)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("InventoryLists onCategoriesListMouseSelectionChange()");
		if (event.keyboardOrMouse == 0) {
			doCategorySelectionChange(event);
		}
	}

	function onItemsListMoveUp(event)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("InventoryLists onItemsListMoveUp()");
		this.doItemsSelectionChange(event);
	}

	function onItemsListMoveDown(event)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("InventoryLists onItemsListMoveDown()");
		this.doItemsSelectionChange(event);
	}

	function onItemsListMouseSelectionChange(event)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("InventoryLists onItemsListMouseSelectionChange()");
		if (event.keyboardOrMouse == 0) {
			doItemsSelectionChange(event);
		}
	}

	function doCategorySelectionChange(event)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("InventoryLists doCategorySelectionChange()");
		
		// save current category info before changing
		if (_CategoriesList.entryList[_currCategoryIndex] != undefined) {
			if (_ItemsList.scrollPosition != undefined)
				_CategoriesList.entryList[_currCategoryIndex].savedScrollPosition = _ItemsList.scrollPosition;
			_CategoriesList.entryList[_currCategoryIndex].savedItemIndex = _ItemsList.selectedIndex;
		}		
		_global.skse.Log("DynamicList category " + _CategoriesList.entryList[_currCategoryIndex].text + " savedItemIndex = " + _CategoriesList.entryList[_currCategoryIndex].savedItemIndex + " scrollPosition = " + _CategoriesList.entryList[_currCategoryIndex].savedScrollPosition);
		dispatchEvent({type:"categoryChange", index:event.index});

		if (event.index != -1) {
			GameDelegate.call("PlaySound",["UIMenuFocus"]);
		}
	}

	function doItemsSelectionChange(event)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("InventoryLists onItemsSelectionChange()");
		dispatchEvent({type:"itemHighlightChange", index:event.index});

		if (event.index != -1) {
			GameDelegate.call("PlaySound",["UIMenuFocus"]);
		}
	}

	function onSortChange(event)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("InventoryLists onSortChange() numUnfilteredItems = " + _ItemsList.numUnfilteredItems);
		// reset scroll position to top when sorting
		if (_ItemsList.numUnfilteredItems > 0)
		{
			if (DEBUG_LEVEL > 1) _global.skse.Log("RESETTING SCROLL POSITION TO 0");
			_ItemsList.scrollPosition = 0;
		}
		_sortFilter.setSortBy(event.attributes, event.options);
	}

	function onSearchInputStart(event)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("InventoryLists onSearchInputStart()");
		_CategoriesList.disableSelection = true;
		_ItemsList.disableInput = true;
		_nameFilter.filterText = "";
	}

	function onSearchInputChange(event)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("InventoryLists onSearchInputChange()");
		_nameFilter.filterText = event.data;
	}

	function onSearchInputEnd(event)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("InventoryLists onSearchInputEnd()");
		_CategoriesList.disableSelection = false;
		_ItemsList.disableInput = false;
		_nameFilter.filterText = event.data;
	}

	// API - Called to initially set the category list
	function SetCategoriesList()
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("<========================InventoryLists SetCategoriesList==================================" + "\n");
		skse.Log("initializing MAIN START TIMER...");
		startTime = new Date();
		var textOffset = 0;
		var flagOffset = 1;
		var bDontHideOffset = 2;
		var len = 3;

		_CategoriesList.clearList();

		for (var i = 0, index = 0; i < arguments.length; i = i + len, index++) {
			var entry = {text:arguments[i + textOffset], flag:arguments[i + flagOffset], bDontHide:arguments[i + bDontHideOffset], savedItemIndex:-1, savedScrollPosition:0, filterFlag:arguments[i + bDontHideOffset] == true ? (1) : (0)};
			_CategoriesList.entryList.push(entry);

			if (entry.flag == 0) {
				_CategoriesList.dividerIndex = index;
			}
		}
		
		// Initialize tabbar labels and replace text of segment heads (name -> ALL)
		if (_TabBar != undefined) {
			if (_CategoriesList.dividerIndex != -1) {
				 _TabBar.setLabelText(_CategoriesList.entryList[0].text, _CategoriesList.entryList[_CategoriesList.dividerIndex + 1].text);
				 _CategoriesList.entryList[0].text = _CategoriesList.entryList[_CategoriesList.dividerIndex + 1].text = _config.Strings.all;
			}
			
			// Restore 0 as default index for tabbed lists
			_CategoriesList.selectedIndex = 0;
		}

		_CategoriesList.InvalidateData();
		_global.skse.Log("========================END InventoryLists SetCategoriesList==================================>" + "\n");
	}

	// API - Called whenever the underlying entryList data is updated (using an item, equipping etc.)
	function InvalidateListData()
	{
	if (DEBUG_LEVEL > 0) _global.skse.Log("<========================InventoryLists InvalidateListData==================================" + "\n");
		skse.Log("initializing timer for InvalidateListData()...");
		var startInvalidateTime:Date = new Date();
		var flag = _CategoriesList.selectedEntry.flag;

		for (var i = 0; i < _CategoriesList.entryList.length; i++) {
			_CategoriesList.entryList[i].filterFlag = _CategoriesList.entryList[i].bDontHide ? 1 : 0;
		}

		// Set filter flag = 1 for non-empty categories with bDontHideOffset=false
		_ItemsList.InvalidateData();
		for (var i = 0; i < _ItemsList.entryList.length; i++) {
			for (var j = 0; j < _CategoriesList.entryList.length; ++j) {
				if (_CategoriesList.entryList[j].filterFlag != 0) {
					continue;
				}

				if (_ItemsList.entryList[i].filterFlag & _CategoriesList.entryList[j].flag) {
					_CategoriesList.entryList[j].filterFlag = 1;
				}
			}
		}

		_CategoriesList.UpdateList();

		if (flag != _CategoriesList.selectedEntry.flag) {
			// Triggers an update if filter flag changed
			_typeFilter.itemFilter = _CategoriesList.selectedEntry.flag;
			dispatchEvent({type:"categoryChange", index:_CategoriesList.selectedIndex});
		}
		
		// This is called when an ItemCard list closes(ex. ShowSoulGemList) to refresh ItemCard data    
		if (_ItemsList.selectedIndex == -1) {
			dispatchEvent({type:"showItemsList", index: -1});
		} else {
			dispatchEvent({type:"itemHighlightChange", index:_ItemsList.selectedIndex});
		}
		var endInvalidateTime:Date = new Date();
		skse.Log("Time elapsed to execute InvalidateListData() "+String(endInvalidateTime.getTime()-startInvalidateTime.getTime())+" milliseconds");
		_global.skse.Log("========================END InventoryLists InvalidateListData==================================>" + "\n");
	}
}