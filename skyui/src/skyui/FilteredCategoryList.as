import Shared.ListFilterer;
import skyui.IFilter;
import skyui.Defines;

class skyui.FilteredCategoryList extends skyui.DynamicList
{
	var _filteredList:Array;
	private var _filterChain:Array;
	static var FILL_BORDER = 0;
	static var FILL_PARENT = 1;
	static var FILL_STAGE = 2;

	private var _bNoIcons:Boolean;
	private var _bNoText:Boolean;
	private var _xOffset:Number;
	private var _fillType:Number;
	private var _bSetInitialIndex:Boolean;
	private var _contentWidth:Number;
	private var _totalWidth:Number;
	private var _prevListIndex;
	private var _prevFilteredIndex;
	private var _dividerIndex:Number;
	
	private var _iconArt:Array;

	function FilteredCategoryList()
	{
		super();
		_filteredList = new Array();
		_filterChain = new Array();
		_dividerIndex = -1;
	}

	function addFilter(a_filter:IFilter)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("FilteredCategoryList addFilter()");
		if (DEBUG_LEVEL > 1)
			_global.skse.Log("addFilter " + a_filter);
		_filterChain.push(a_filter);
	}

	function getFilteredEntry(a_index:Number):Object
	{
		return _filteredList[a_index];
	}

	// Did you mean: numFilteredItems() ?
	function get numUnfilteredItems():Number
	{
		return _filteredList.length;
	}

	function generateFilteredList()
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("FilteredCategoryList generateFilteredList()");
		_prevFilteredIndex = selectedEntry.filteredIndex;
		if (DEBUG_LEVEL > 1)
			_global.skse.Log("prevFilteredIndex = " + _prevFilteredIndex + " preventry = " + selectedEntry.text);
		_filteredList.splice(0);
		
		if (DEBUG_LEVEL > 1)
			_global.skse.Log("generateFilteredList() copy entrylist into filteredlist");
		for (var i = 0; i < _entryList.length; i++)
		{
			_entryList[i].unfilteredIndex = i;
			_entryList[i].filteredIndex = undefined;
			_filteredList[i] = _entryList[i];
		}
		if (DEBUG_LEVEL > 1)
			_global.skse.Log("generateFilteredList() process");
		for (var i = 0; i < _filterChain.length; i++)
		{
			_filterChain[i].process(_filteredList);
		}
		if (DEBUG_LEVEL > 1)
			_global.skse.Log("generateFilteredList() set filtered indexes");
		for (var i = 0; i < _filteredList.length; i++)
		{
			_filteredList[i].filteredIndex = i;
		}

		if (selectedEntry.filteredIndex == undefined)
		{
			_selectedIndex = -1;
		}
	}


	// Gets a clip, or if it doesn't exist, creates it.
	function getClipByIndex(a_index):MovieClip
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("FilteredCategoryList getClipByIndex()");
		if (DEBUG_LEVEL > 1)
			_global.skse.Log("getClipByIndex " + a_index);
		var entryClip = this["Entry" + a_index];

		if (entryClip != undefined)
		{
			return entryClip;
		}

		// Create on-demand       
		entryClip = attachMovie(_entryClassName, "Entry" + a_index, a_index);
		entryClip.clipIndex = a_index;

		// How about proper closures? :(
		entryClip.buttonArea.onRollOver = function()
		{
			if (!_parent._parent.listAnimating && !_parent._parent._bDisableInput && _parent.itemIndex != undefined)
			{

				if (_parent.itemIndex != _parent._parent._selectedIndex)
				{
					_parent._alpha = 75;
				}
				_parent._parent._bMouseDrivenNav = true;
			}
		};

		entryClip.buttonArea.onRollOut = function()
		{
			if (!_parent._parent.listAnimating && !_parent._parent._bDisableInput && _parent.itemIndex != undefined)
			{

				if (_parent.itemIndex != _parent._parent._selectedIndex)
				{
					_parent._alpha = 50;
				}
				_parent._parent._bMouseDrivenNav = true;
			}
		};

		entryClip.buttonArea.onPress = function(aiMouseIndex, aiKeyboardOrMouse)
		{
			if (_parent.itemIndex != undefined && !_parent._parent.listAnimating && !_parent._parent._bDisableInput)
			{

				_parent._parent.doSetSelectedIndex(_parent.itemIndex,0);
				_parent._parent.onItemPress(aiKeyboardOrMouse);

				if (!_parent._parent._bDisableInput && _parent.onMousePress != undefined)
				{
					_parent.onMousePress();
				}
			}
		};

		entryClip.buttonArea.onPressAux = function(aiMouseIndex, aiKeyboardOrMouse, aiButtonIndex)
		{
			if (_parent.itemIndex != undefined)
			{
				_parent._parent.onItemPressAux(aiKeyboardOrMouse,aiButtonIndex);
			}
		};

		return entryClip;
	}

	function restoreSelectedEntry(a_newIndex:Number)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("FilteredCategoryList restoreSelectedEntry()");
		if (DEBUG_LEVEL > 1)
			_global.skse.Log("restoreSelectedEntry " + a_newIndex);
		doSetSelectedIndex(a_newIndex,0);
		onItemPress(1);
	}
	
	function isSelectionAboveDivider()
	{
		return (_dividerIndex == -1 || selectedIndex < _dividerIndex);
	}

	function get dividerIndex()
	{
		return _dividerIndex;
	}

	function UpdateList()
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("FilteredCategoryList UpdateList()");
		var cw = _indent * 2;
		var tw = 0;
		var xOffset = 0;
		var _listIndex = 0;
		// used by containers to determine which category side player is on
		_dividerIndex = -1;
		for (var i = 0; i < _filteredList.length; i++)
		{
			if (isDivider(_filteredList[i]))
			{
				_dividerIndex = _filteredList[i].unfilteredIndex;
				if (DEBUG_LEVEL > 0) _global.skse.Log("FilteredCategoryList UpdateList(), _dividerIndex = " + _dividerIndex);
			} 
		}

		if (_fillType == FILL_PARENT)
		{
			xOffset = _parent._x;
			tw = _parent._width;
		}
		else if (_fillType == FILL_STAGE)
		{
			xOffset = 0;
			tw = Stage.visibleRect.width;
		}
		else
		{
			xOffset = border._x;
			tw = border._width;
		}

		for (var i = 0; i < _filteredList.length; i++)
		{
			_filteredList[i].clipIndex = undefined;
		}
		if (DEBUG_LEVEL > 1)
			_global.skse.Log("filteredList length = " + _filteredList.length);
		for (var i = 0; i < _filteredList.length; i++)
		{
			if (DEBUG_LEVEL > 1)
				_global.skse.Log("getClipByIndex " + _listIndex + " for entry " + _filteredList[i]);
			
			var entryClip = getClipByIndex(_listIndex);
			if (_filteredList[i].divider)
				entryClip.divider = true;
			setCategoryIcons(entryClip,_filteredList[i]);
			
			if (DEBUG_LEVEL > 1)
				_global.skse.Log("Setting entry " + _filteredList[i].text);
			
			setEntry(entryClip,_filteredList[i]);
			
			if (DEBUG_LEVEL > 1)
				_global.skse.Log("Setting clip " + entryClip + " itemIndex = " + _filteredList[i].unfilteredIndex);
			
			entryClip.itemIndex = _filteredList[i].unfilteredIndex;
			_filteredList[i].clipIndex = _listIndex;

			entryClip.textField.autoSize = "left";
			
			var w = 0;
			if (entryClip.icon._visible)
			{
				w = w + entryClip.icon._width;
			}
			if (entryClip.textField._visible)
			{
				w = w + entryClip.textField._width;
			}
			entryClip.buttonArea._width = w;
			cw = cw + w;
			_listIndex++;
			/*var catInfo = _filteredList[i];
			_global.skse.Log("reading category info for " + _filteredList[i].text);
			for(var key:String in catInfo);
			{
			_global.skse.Log(key + ": " + catInfo[key]);
			}*/
		}
		if (DEBUG_LEVEL > 1)
			_global.skse.Log("FilteredCategoryList filteredList length = " + _filteredList.length + " , size = " + _listIndex);
		
		_contentWidth = cw;
		_totalWidth = tw;

		var spacing = (_totalWidth - _contentWidth) / (_filteredList.length + 1);
		var spacing = (_totalWidth - _contentWidth) / (_filteredList.length + 1);

		var xPos = xOffset + _indent + spacing;

		for (var i = 0; i < _filteredList.length; i++)
		{
			_global.skse.Log("_filteredList[i] = " + _filteredList[i]);
			var entryClip = getClipByIndex(i);
			entryClip._x = xPos;
			_global.skse.Log("clip index in pos " + i + " = " + entryClip.itemIndex);
			xPos = xPos + entryClip.buttonArea._width + spacing;
			//_global.skse.Log("setting clip " + entryList[_indexMap[i]] + " visible to true");
			entryClip._visible = true;

		}
		// hide any clips that have been filtered out
		// we check our previous category list size since we are adding clips dynamically
		for (var i = _listIndex; i < _prevListIndex; ++i)
		{
			getClipByIndex(i)._visible = false;
			getClipByIndex(i).itemIndex = undefined;
		}
		_prevListIndex = _listIndex;
		if (DEBUG_LEVEL > 1)
			_global.skse.Log("EXITING FilteredCategoryList UpdateList()");
	}

	function setCategoryIcons(entryClip, entry)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("FilteredCategoryList setCategoryIcons()");
		if (DEBUG_LEVEL > 1)
		_global.skse.Log("flag = " + entry.flag + " , Setting category icon for clip " + entryClip);
		if (_bNoText || entry.flag == 0)
		{
			entryClip.textField._visible = false;
		}
		if (!_bNoIcons)
		{
			var a_index = entryClip.clipIndex;
			if (DEBUG_LEVEL > 0)
				_global.skse.Log("setCategoryIcons() entry = " + entry.text + " , flag = " + entry.flag);
			switch (entry.flag)
			{
				case Defines.FLAG_CATEGORY_DIVIDER :	// 0
					entryClip.icon.gotoAndStop("cat_divider");
					break;
				case Defines.FLAG_INV_FAVORITES :	// 1
					entryClip.icon.gotoAndStop("cat_favorites");
					break;
				case Defines.FLAG_CRAFTING_HIDE :
				case Defines.FLAG_INV_WEAPONS :	// 2
					if (entry.text == "HIDE")
					{
						entryClip.icon.gotoAndStop("category_hide");
					}
					else {
						entryClip.icon.gotoAndStop("inv_weapons");
					}
					break;
				case Defines.FLAG_INV_ARMOR :	// 4
					entryClip.icon.gotoAndStop("inv_armor");
					break;
				case Defines.FLAG_ENCHANTING_ITEM :	// 5
					entryClip.icon.gotoAndStop("category_item");
					break;
				case Defines.FLAG_CRAFTING_IRON :
				case Defines.FLAG_INV_POTIONS :	// 8
					if (entry.text == "IRON")
					{
						entryClip.icon.gotoAndStop("category_iron");
					}
					else {
						entryClip.icon.gotoAndStop("inv_potions");
					}
					break;
				case Defines.FLAG_ENCHANTING_DISENCHANT :	// 10
					entryClip.icon.gotoAndStop("category_disenchant");
					break;
				case Defines.FLAG_CRAFTING_STUDDED :
				case Defines.FLAG_INV_SCROLLS :	// 16
					if (entry.text == "STUDDED")
					{
						entryClip.icon.gotoAndStop("category_iron");
					}
					else {
						entryClip.icon.gotoAndStop("inv_scrolls");
					}
					break;
				case Defines.FLAG_CRAFTING_IMPERIAL :
				case Defines.FLAG_INV_FOOD :	// 32
					if (entry.text == "IMPERIAL")
					{
						entryClip.icon.gotoAndStop("category_imperial");
					}
					else {
						entryClip.icon.gotoAndStop("inv_food");
					}
					break;
				case Defines.FLAG_ENCHANTING_ENCHANTMENT :	// 48
					entryClip.icon.gotoAndStop("category_enchantment");
					break;
				case Defines.FLAG_CRAFTING_STEEL :
				case Defines.FLAG_ENCHANTING_SOULGEM :
				case Defines.FLAG_INV_INGREDIENTS :	// 64
					if (entry.text == "Soul Gem")
					{
						entryClip.icon.gotoAndStop("category_soulgem");
						break;
					}
					else if (entry.text == "STEEL")
					{
						entryClip.icon.gotoAndStop("category_steel");
						break;
					}
					else
					{
						entryClip.icon.gotoAndStop("inv_ingredients");
						break;
					}
				case Defines.FLAG_CRAFTING_LEATHER :
				case Defines.FLAG_INV_BOOKS :	// 128
					if (entry.text == "LEATHER")
					{
						entryClip.icon.gotoAndStop("category_leather");
					}
					else {
						entryClip.icon.gotoAndStop("inv_books");
					}
					break;
				case Defines.FLAG_CRAFTING_DWARVEN :
				case Defines.FLAG_INV_KEYS :	// 256
					if (entry.text == "DWARVEN")
					{
						entryClip.icon.gotoAndStop("category_dwarven");
					}
					else {
						entryClip.icon.gotoAndStop("inv_keys");
					}
					break;
				case Defines.FLAG_INV_MISC :	// 512
					entryClip.icon.gotoAndStop("inv_misc");
					break;
				case Defines.FLAG_INV_ALL :	// 1023
					entryClip.icon.gotoAndStop("inv_all");
					break;
				case Defines.FLAG_BARTER_WEAPONS :
				case Defines.FLAG_CRAFTING_ORCISH :	/// 2048
					if (entry.text == "ORCISH")
					{
						entryClip.icon.gotoAndStop("category_orcish");
					}
					else {
						entryClip.icon.gotoAndStop("inv_weapons");
					}
					break;
				case Defines.FLAG_BARTER_ARMOR :
				case Defines.FLAG_CRAFTING_EBONY :	// 4096
					if (entry.text == "EBONY")
					{
						entryClip.icon.gotoAndStop("category_ebony");
					}
					else {
						entryClip.icon.gotoAndStop("inv_armor");
					}
					break;
				case Defines.FLAG_BARTER_POTIONS :	// 8192
					entryClip.icon.gotoAndStop("inv_potions");
					break;
				case Defines.FLAG_BARTER_SCROLLS :
				case Defines.FLAG_CRAFTING_DRAGON :	// 16384
					if (entry.text == "DRAGON")
					{
						entryClip.icon.gotoAndStop("category_dragonplate");
					}
					else {
						entryClip.icon.gotoAndStop("inv_scrolls");
					}
					break;
				case Defines.FLAG_BARTER_FOOD :
				case Defines.FLAG_CRAFTING_DAEDRIC :	// 32768
					if (entry.text == "DAEDRIC")
					{
						entryClip.icon.gotoAndStop("category_daedric");
					}
					else {
						entryClip.icon.gotoAndStop("inv_food");
					}
					break;
				case Defines.FLAG_BARTER_INGREDIENTS :	// 65536
					entryClip.icon.gotoAndStop("inv_ingredients");
					break;
				case Defines.FLAG_BARTER_BOOKS :	// 131072
					entryClip.icon.gotoAndStop("inv_books");
					break;
				case Defines.FLAG_BARTER_KEYS :	   // 262144
					entryClip.icon.gotoAndStop("inv_keys");
					break;
				case Defines.FLAG_BARTER_MISC :	   // 524288
					entryClip.icon.gotoAndStop("inv_misc");
					break;
				case Defines.FLAG_BARTER_ALL :	   // 1047552
					entryClip.icon.gotoAndStop("inv_all");
					break;
				default :
					entryClip.icon.gotoAndStop("inv_misc");
					break;
			}
		}
		else
		{
			entryClip.icon._visible = false;
			entryClip.textField._x = 0;
		}
	}

	function InvalidateData()
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("FilteredCategoryList InvalidateData()");
		generateFilteredList();
		super.InvalidateData();
	}

	function moveSelectionLeft()
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("FilteredCategoryList moveSelectionLeft()");
		if (DEBUG_LEVEL > 1)
			_global.skse.Log("current selectedindex = " + selectedIndex);
		if (!_bDisableSelection)
		{
			if (isDivider(_filteredList[selectedEntry.filteredIndex - 1]))
			{
				doSetSelectedIndex(_filteredList[selectedEntry.filteredIndex - 2].unfilteredIndex,1);
				onItemPress(0);
			}
			else if (selectedEntry.filteredIndex > 0)
			{
				doSetSelectedIndex(_filteredList[selectedEntry.filteredIndex - 1].unfilteredIndex,1);
				onItemPress(0);
			}
		}
	}
	function moveSelectionRight()
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("FilteredCategoryList moveSelectionRight()");
		if (DEBUG_LEVEL > 1)
			_global.skse.Log("current selectedindex = " + _selectedIndex);
		if (!_bDisableSelection)
		{
			if (isDivider(_filteredList[selectedEntry.filteredIndex + 1]))
			{
				doSetSelectedIndex(_filteredList[selectedEntry.filteredIndex + 2].unfilteredIndex,1);
				onItemPress(0);
			}
			else if (selectedEntry.filteredIndex < _filteredList.length - 1 && !isDivider(selectedEntry))
			{
				doSetSelectedIndex(_filteredList[selectedEntry.filteredIndex + 1].unfilteredIndex,1);
				if (DEBUG_LEVEL > 1)
					_global.skse.Log("move right to selectedIndex " + _selectedIndex + " to entry " + _filteredList[selectedEntry.filteredIndex +1].text);
				onItemPress(0);
			}
		}
	}

	function doSetSelectedIndex(a_newIndex:Number, a_keyboardOrMouse:Number)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("FilteredCategoryList doSetSelectedIndex()");
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("doSetSelectedIndex a_newIndex = " + a_newIndex);
		if (!_bDisableSelection && a_newIndex != _selectedIndex)
		{
			var _oldIndex = _selectedIndex;
			_selectedIndex = a_newIndex;

			// check for divider, return if found
			if (isDivider(_entryList[_selectedIndex]))
			{
				if (DEBUG_LEVEL > 0)
					_global.skse.Log("DIVIDER FOUND");
				return;
			}
			if (_oldIndex != -1)
			{
				if (DEBUG_LEVEL > 0)
					_global.skse.Log("_oldIndex getClipByIndex(" + _oldIndex + ") = " + getClipByIndex(_entryList[_oldIndex].filteredIndex) + " , entry = " + _entryList[_oldIndex].text);
				setEntry(getClipByIndex(_entryList[_oldIndex].filteredIndex),_entryList[_oldIndex]);
			}

			if (_selectedIndex != -1)
			{
				if (DEBUG_LEVEL > 0)
					_global.skse.Log("new getClipByIndex(" + _selectedIndex + ") = " + getClipByIndex(_entryList[_selectedIndex].filteredIndex) + " , entry = " + _entryList[_selectedIndex].text);
				setEntry(getClipByIndex(_entryList[_selectedIndex].filteredIndex),_entryList[_selectedIndex]);
			}

			dispatchEvent({type:"selectionChange", index:_selectedIndex, keyboardOrMouse:a_keyboardOrMouse});
		}
	}

	function setEntry(a_entryClip:MovieClip, a_entryObject:Object)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("FilteredCategoryList setEntry()");
		if (DEBUG_LEVEL > 1)
			_global.skse.Log("setEntry " + a_entryObject.text);
		if (a_entryClip != undefined)
		{
			if (a_entryObject == selectedEntry)
			{
				a_entryClip._alpha = 100;
			}
			else
			{
				a_entryClip._alpha = 50;
			}

			setEntryText(a_entryClip,a_entryObject);
		}
	}

	function onFilterChange()
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("FilteredCategoryList onFilterChange()");
		generateFilteredList();
		UpdateList();
	}
}