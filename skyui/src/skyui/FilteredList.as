import Shared.ListFilterer;
import skyui.IFilter;

class skyui.FilteredList extends skyui.DynamicScrollingList
{
	private var _filteredList:Array;
	private var _filterChain:Array;

	private var _curClipIndex:Number;
	
	private var _bGetInvCalled:Boolean;
	

	function FilteredList()
	{
		super();
		_filteredList = new Array();
		_filterChain = new Array();
		_curClipIndex = -1;
		_bGetInvCalled = false;
	}

	function addFilter(a_filter:IFilter)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("FilteredList addFilter()");		
		_filterChain.push(a_filter);
	}

	function getFilteredEntry(a_index:Number):Object
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("FilteredList getFilteredEntry()");
		return _filteredList[a_index];
	}

	// Did you mean: numFilteredItems() ?
	function get numUnfilteredItems():Number
	{
		return _filteredList.length;
	}

	function generateFilteredList()
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("FilteredList generateFilteredList()");
		_filteredList.splice(0);

		for (var i = 0; i < _entryList.length; i++) {
			_entryList[i].unfilteredIndex = i;
			_entryList[i].filteredIndex = undefined;
			_entryList[i].clipIndex = undefined;
			_filteredList[i] = _entryList[i];
		}

		for (var i = 0; i < _filterChain.length; i++) {
			_filterChain[i].process(_filteredList);
		}

		if (DEBUG_LEVEL > 1) _global.skse.Log("generating new filteredList..."); 
		for (var i = 0; i < _filteredList.length; i++) {
			_filteredList[i].filteredIndex = i;
			if (DEBUG_LEVEL > 1) _global.skse.Log("added entry " + _filteredList[i].text + " count = " + _filteredList[i].count + " to pos " + i + ".");
		}

		if (selectedEntry.filteredIndex == undefined) {
			_global.skse.Log("Setting selectedEntry " + selectedEntry.text + " filteredIndex to undefined");
			_selectedIndex = -1;
		}
	}

	function UpdateList()
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("<========================FilteredList UpdateList==================================" + "\n");
		var yStart = _indent;
		var h = 0;

		for (var i = 0; i < _filteredList.length && i < _scrollPosition; i++) {
			_filteredList[i].clipIndex = undefined;
		}

		_listIndex = 0;

		for (var i = _scrollPosition; i < _filteredList.length && _listIndex < _maxListIndex; i++) {
			var entryClip = getClipByIndex(_listIndex);
			if (DEBUG_LEVEL > 1) _global.skse.Log("FilteredList UpdateList() setEntry " + _filteredList[i].text + " unfilteredIndex = " + _filteredList[i].unfilteredIndex);
			setEntry(entryClip,_filteredList[i]);
			entryClip.itemIndex = _filteredList[i].unfilteredIndex;
			_filteredList[i].clipIndex = _listIndex;

			entryClip._y = yStart + h;
			entryClip._visible = true;

			h = h + _entryHeight;

			_listIndex++;
		}
		
		for (var i = _scrollPosition + _listIndex; i < _filteredList.length; i++) {
			_filteredList[i].clipIndex = undefined;
		}

		for (var i = _listIndex; i < _maxListIndex; i++) {
			getClipByIndex(i)._visible = false;
			getClipByIndex(i).itemIndex = undefined;
		}

		// Select entry under the cursor
		if (_bMouseDrivenNav) {
			for (var e = Mouse.getTopMostEntity(); e != undefined; e = e._parent) {
				if (e._parent == this && e._visible && e.itemIndex != undefined) {
					if (DEBUG_LEVEL > 1) _global.skse.Log("FilteredList UpdateList() doSetSelectedIndex " + e.itemIndex + " for entry " + e.text);
					doSetSelectedIndex(e.itemIndex,0);
				}
			}
		}
		_global.skse.Log("========================END FilteredList UpdateList==================================>" + "\n");
	}

	function InvalidateData()
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("<========================FilteredList InvalidateData==================================" + "\n");
		if (DEBUG_LEVEL > 1) _global.skse.Log("selectedEntry = " + selectedEntry.text + " index = " + selectedEntry.unfilteredIndex + " filteredIndex = " + selectedEntry.filteredIndex);
		generateFilteredList();
		if (DEBUG_LEVEL > 1) _global.skse.Log("selectedEntry = " + selectedEntry.text + " index = " + selectedEntry.unfilteredIndex + " filteredIndex = " + selectedEntry.filteredIndex);
		super.InvalidateData();
		if (DEBUG_LEVEL > 1) _global.skse.Log("selectedEntry = " + selectedEntry.text + " index = " + selectedEntry.unfilteredIndex + " filteredIndex = " + selectedEntry.filteredIndex);
		
		// Restore selection
		if (_curClipIndex != undefined && _curClipIndex != -1 && _listIndex > 0) {
			
			if (_curClipIndex >= _listIndex) {
				_curClipIndex = _listIndex - 1;
			}
			
			var entryClip = getClipByIndex(_curClipIndex);
			if (DEBUG_LEVEL > 0) _global.ske.Log("Restoring entry " + entryClip.text + " at clip index " + entryClip.clipIndex);
			doSetSelectedIndex(entryClip.itemIndex, 1);
		}
		_global.skse.Log("========================END FilteredList InvalidateData==================================>" + "\n");
	}

	function calculateMaxScrollPosition()
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("FilteredList calculateMaxScrollPosition");
		var t = _filteredList.length - _maxListIndex;
		_maxScrollPosition = (t > 0) ? t : 0;

		if (_scrollPosition > _maxScrollPosition) {
			scrollPosition = _maxScrollPosition;
		}

		updateScrollbar();
	}

	function moveSelectionUp(a_bScrollPage:Boolean)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("FilteredList moveSelectionUp()");
		if (!_bDisableSelection && !a_bScrollPage) {
			if (_selectedIndex == -1) {
				selectDefaultIndex(false);
			} else if (selectedEntry.filteredIndex > 0) {
				doSetSelectedIndex(_filteredList[selectedEntry.filteredIndex - 1].unfilteredIndex,1);
				_bMouseDrivenNav = false;
				dispatchEvent({type:"listMovedUp", index:_selectedIndex, scrollChanged:true});
			}
		} else if (a_bScrollPage) {
			var t = scrollPosition - _listIndex;
			scrollPosition = t > 0 ? t : 0;
			doSetSelectedIndex(-1, 0);
		} else {
			scrollPosition = scrollPosition - 1;
		}
	}

	function moveSelectionDown(a_bScrollPage:Boolean)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("FilteredList moveSelectionDown()");
		if (!_bDisableSelection && !a_bScrollPage) {
			if (_selectedIndex == -1) {
				selectDefaultIndex(true);
			} else if (selectedEntry.filteredIndex < _filteredList.length - 1) {
				doSetSelectedIndex(_filteredList[selectedEntry.filteredIndex + 1].unfilteredIndex,1);
				_bMouseDrivenNav = false;
				dispatchEvent({type:"listMovedDown", index:_selectedIndex, scrollChanged:true});
			}
		} else if (a_bScrollPage) {
			var t = scrollPosition + _listIndex;
			scrollPosition = t < _maxScrollPosition ? t : _maxScrollPosition;
			doSetSelectedIndex(-1, 0);
		} else {
			scrollPosition = scrollPosition + 1;
		}
	}

	function doSetSelectedIndex(a_newIndex:Number, a_keyboardOrMouse:Number)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("FilteredList doSetSelectedIndex()");
		if (DEBUG_LEVEL > 0) _global.skse.Log("FilteredList doSetSelectedIndex entry " + _entryList[a_newIndex].text + " at index " + a_newIndex + " count = " + _entryList[a_newIndex].count + " , lastSelectedEntry = " + _entryList[_selectedIndex].text + " at index " + _selectedIndex + " , bDisableSelection = " + _bDisableSelection);
		
		if (DEBUG_LEVEL > 0) if (_bGetInvCalled) _global.skse.Log("GetInventoryItemList CALLED DIRECTLY!");
		// if new selected index is the same and GetInventoryItemList has not been called, ignore
		if (!_bDisableSelection && a_newIndex != _selectedIndex && !_bGetInvCalled) {
			var oldIndex = _selectedIndex;
			_selectedIndex = a_newIndex;

			if (oldIndex != -1 && _entryList[oldIndex].clipIndex != undefined) {
				setEntry(getClipByIndex(_entryList[oldIndex].clipIndex), _entryList[oldIndex]);
			}

			if (_selectedIndex != -1) {
				if (selectedEntry.filteredIndex < _scrollPosition) {
					if (DEBUG_LEVEL > 1) _global.skse.Log(selectedEntry.text +" filteredIndex = " + selectedEntry.filteredIndex + " , scrollPosition = " + _scrollPosition);
					scrollPosition = selectedEntry.filteredIndex;
				} else if (selectedEntry.filteredIndex >= _scrollPosition + _listIndex) {
					if (DEBUG_LEVEL > 1) _global.skse.Log(selectedEntry.text + " filteredIndex = " + selectedEntry.filteredIndex + " , scrollPosition = " + _scrollPosition + " , listIndex = " + _listIndex);
					scrollPosition = Math.min(selectedEntry.filteredIndex - _listIndex + 1, _maxScrollPosition);
				} else {
					setEntry(getClipByIndex(_entryList[_selectedIndex].clipIndex),_entryList[_selectedIndex]);
				}
				
				_curClipIndex = _entryList[_selectedIndex].clipIndex;
			} else {
				_curClipIndex = -1;
			}
			
			dispatchEvent({type:"selectionChange", index:_selectedIndex, keyboardOrMouse:a_keyboardOrMouse});
		}
	}

	function onFilterChange()
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("FilteredList onFilterChange()");
		generateFilteredList();
		calculateMaxScrollPosition();
		UpdateList();
	}
}