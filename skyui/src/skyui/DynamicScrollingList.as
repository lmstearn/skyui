import gfx.events.EventDispatcher;
import gfx.ui.NavigationCode;
import Shared.GlobalFunc;

import skyui.ScrollBar;
import skyui.Config;

class skyui.DynamicScrollingList extends skyui.DynamicList
{
	private var _savedScrollPosition:Number;
	
	private var _scrollPosition:Number;
	private var _maxScrollPosition:Number;

	private var _listIndex:Number;
	private var _maxListIndex:Number;
	private var _listHeight:Number;
	
	private var _entryHeight:Number;
	
	
	private var _scrollTmp: Number;
	private var _scrollDelta: Number;
	
	private var _isScrolling: Number;
	private var _isFastScrolling: Number;

	
	private var _scrollDelay: Number;
	
	private var _config: Config;

	// Children
	var scrollbar:MovieClip;

	// Constructor
	function DynamicScrollingList()
	{
		super();
		
		_savedScrollPosition = 0;
		_scrollPosition = 0;
		_maxScrollPosition = 0;
		_listIndex = 0;

		_scrollTmp = 0;
		// Time in ms before fast scroll is instantiated
		_scrollDelay = 500;

		_entryHeight = 28;
		_listHeight = border._height;
		_maxListIndex = Math.floor(_listHeight / _entryHeight);
		
		Config.instance.addEventListener("configLoad", this, "onConfigLoad");
	}

	function onLoad()
	{
		if (scrollbar != undefined) {
			scrollbar.position = 0;
			scrollbar.addEventListener("scroll",this,"onScroll");
			scrollbar._y = _indent;
			scrollbar.height = _listHeight;
		}
	}

	function onConfigLoad(event)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("DynamicScrollingList onConfigLoad()");
			
		_config = event.config;
		_scrollDelta = _config.General.scrollDelta;
		
		setScrollDelta(_maxListIndex);
	}

	function onScroll(event)
	{
		if (DEBUG_LEVEL > 1) _global.skse.Log("DynamicScrollingList onScroll()");
		updateScrollPosition(Math.floor(event.position + 0.500000));
	}
	
	function setScrollDelta(maxPosition: Number): Void {
		if (_scrollDelta != undefined && _scrollDelta != 0) {
			if (Math.abs(_scrollDelta) > maxPosition) {
				// sign(scrollDelta) * maxPosition
				_scrollDelta = (Math.abs(_scrollDelta)/_scrollDelta) * maxPosition;
			}
		} else {
			_scrollDelta = 1;
		}
	}

	function getClipByIndex(a_index:Number)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("DynamicScrollingList getClipByIndex()");
		if (a_index < 0 || a_index >= _maxListIndex) {
			return undefined;
		}

		return super.getClipByIndex(a_index);
	}

	function handleInput(details, pathToFocus):Boolean
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("DynamicScrollingList handleInput()");
		var processed = false;

		if (!_bDisableInput) {
			var entry = getClipByIndex(selectedIndex - scrollPosition);

			processed = entry != undefined && entry.handleInput != undefined && entry.handleInput(details, pathToFocus.slice(1));
			
			if (!processed && (details.value == "keyDown" || details.value == "keyHold" || details.value == "keyUp")) {
				
				var scroll:Boolean = details.navEquivalent == NavigationCode.UP || details.navEquivalent == NavigationCode.DOWN;
				var scrollPage:Boolean  = details.navEquivalent == NavigationCode.PAGE_UP || details.navEquivalent == NavigationCode.PAGE_DOWN;
				var scrollUp:Boolean = details.navEquivalent == NavigationCode.UP || details.navEquivalent == NavigationCode.PAGE_UP;
				
				var _changeCat : Boolean = details.navEquivalent == NavigationCode.LEFT || details.navEquivalent == NavigationCode.RIGHT;
				
				if (details.value == "keyDown")  {
				
					if (scroll || scrollPage) {
						// Scroll up or down once
						scrollUp ? moveSelectionUp(scrollPage) : moveSelectionDown(scrollPage);
						if (_isScrolling == undefined) {
							// Start fast scrolling after a delay of _scrollDelay milliseconds
							// _global.setTimeout(objectReference:Object, methodName:String, interval:Number, [param1:Object, param2, ..., paramN]) : Number
							// Undocumented
							_isScrolling = _global.setTimeout(this, "scrollingStart", _scrollDelay, scrollUp, scrollPage);
						} else {
							// Stop scrolling if another scroll button is pressed
							scrollingStop();
						}
						processed = true;
						
					} else if (!_bDisableSelection && details.navEquivalent == NavigationCode.ENTER) {
						scrollingStop();
						onItemPress();
						processed = true;
					}
				} else if (details.value == "keyUp") {
					if (scroll || scrollPage) {
						scrollingStop();
						processed = true;
					}
				}
			}
		}
		return processed;
	}

function scrollingStart(scrollUp: Boolean, scrollPage: Boolean) {
	var scrollDirection: String = (scrollUp) ? "moveSelectionUp" : "moveSelectionDown";
	_isFastScrolling = setInterval(this, scrollDirection, 0, scrollPage);
}

function scrollingStop(): Void {
	if (_isScrolling  != undefined) {
		// Interrupts the _isScrolling timeout if it's started
		_global.clearTimeout(_isScrolling);
		delete(_isScrolling);
	}
	if (_isFastScrolling  != undefined) {
		// Stops fast scrolling from continuing
		clearInterval(_isFastScrolling);
		delete(_isFastScrolling);
	}
}
	
	function onMouseWheel(delta)
	{
		if (!_bDisableInput) {
			for (var target = Mouse.getTopMostEntity(); target && target != undefined; target = target._parent) {
				if (target == this && delta != 0) {
					_scrollTmp = (delta < 0) ? _scrollTmp + _scrollDelta : _scrollTmp - _scrollDelta;
					var entriesToScroll: Number = Math.floor(_scrollTmp);
					_scrollTmp = _scrollTmp - entriesToScroll;
					if (entriesToScroll <= -1 || entriesToScroll >= 1) {
						scrollPosition = scrollPosition + entriesToScroll;
					}
				}
			}
			_bMouseDrivenNav = true;
		}
	}
	

	function doSetSelectedIndex(a_newIndex:Number, a_keyboardOrMouse:Number)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("DynamicScrollingList doSetSelectedIndex()");
		if (!_bDisableSelection && a_newIndex != _selectedIndex) {
			var oldIndex = _selectedIndex;
			_selectedIndex = a_newIndex;

			if (oldIndex != -1) {
				setEntry(getClipByIndex(_entryList[oldIndex].clipIndex),_entryList[oldIndex]);
			}

			if (_selectedIndex != -1) {
				if (_platform != 0) {
					if (_selectedIndex < _scrollPosition) {
						scrollPosition = _selectedIndex;
					} else if (_selectedIndex >= _scrollPosition + _listIndex) {
						scrollPosition = Math.min(_selectedIndex - _listIndex + 1, _maxScrollPosition);
					} else {
						setEntry(getClipByIndex(_entryList[_selectedIndex].clipIndex),_entryList[_selectedIndex]);
					}
				} else {
					setEntry(getClipByIndex(_entryList[_selectedIndex].clipIndex),_entryList[_selectedIndex]);
				}
			}
			dispatchEvent({type:"selectionChange", index:_selectedIndex, keyboardOrMouse:a_keyboardOrMouse});
		}
	}

	function get scrollPosition()
	{
		if (DEBUG_LEVEL > 1) _global.skse.Log("DynamicScrollingList get scrollPosition() " + _scrollPosition);
		return _scrollPosition;
	}

	function get maxScrollPosition()
	{
		return _maxScrollPosition;
	}

	function set savedScrollPosition(a_position:Number)
	{
		_savedScrollPosition = a_position;
	}

	function set scrollPosition(a_newPosition:Number)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("DynamicScrollingList set scrollPosition "  + a_newPosition);
		if (a_newPosition != _scrollPosition) {
		
			if (a_newPosition < 0) {
				a_newPosition = 0;
			} else if (a_newPosition > _maxScrollPosition) {
				a_newPosition = _maxScrollPosition;
			}
			
			if (scrollbar != undefined) {
				if (DEBUG_LEVEL > 1) _global.skse.Log("updating scroll position = " + _scrollPosition);
				// this is responsible for updating the thumb position on scrollbar 
				// so it's important we call this
				scrollbar.position = a_newPosition;
			} else {
				if (DEBUG_LEVEL > 1) _global.skse.Log("scrollbar is undefined, calling updateScrollPosition");
				updateScrollPosition(a_newPosition);
			}
		}
	}

	// called when pressing mouse button on scrollbar and moving up or down
	// Note: if this is called directly, it will break onScroll
	function updateScrollPosition(a_position:Number)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("DynamicScrollingList updateScrollPosition()" + " currentScrollPos = " + _scrollPosition + ", new scroll pos = " + a_position);
		_scrollPosition = a_position;
		UpdateList();
	}

	function updateScrollbar()
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("DynamicScrollingList updateScrollbar()");
		if (scrollbar != undefined) {
			if (DEBUG_LEVEL > 1) _global.skse.Log("updating scrollbar properties...");
			scrollbar._visible = false;
			scrollbar.setScrollProperties(_maxListIndex,0,_maxScrollPosition);
			scrollbar._visible = _maxScrollPosition > 0;
			// if category has saved scroll position, restore it
			if (_savedScrollPosition > 0)
				_scrollPosition = _savedScrollPosition;
			scrollbar.position = _scrollPosition;
		}
	}

	function UpdateList()
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("DynamicScrollingList UpdateList()");
		var yStart = _indent;
		var h = 0;

		for (var i = 0; i < _scrollPosition; i++) {
			_entryList[i].clipIndex = undefined;
		}

		_listIndex = 0;

		for (var pos = _scrollPosition; pos < _entryList.length && _listIndex < _maxListIndex; pos++) {
			var entry = getClipByIndex(_listIndex);

			setEntry(entry,_entryList[pos]);
			_entryList[pos].clipIndex = _listIndex;
			entry.itemIndex = pos;

			entry._y = yStart + h;
			entry._visible = true;

			h = h + _entryHeight;

			++_listIndex;
		}

		for (var i = _listIndex; i < _maxListIndex; i++) {
			getClipByIndex(i)._visible = false;
			getClipByIndex(i).itemIndex = undefined;
		}
	}

	function InvalidateData()
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("DynamicScrollingList InvalidateData()");
		calculateMaxScrollPosition();

		super.InvalidateData();
	}

	function calculateMaxScrollPosition()
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("DynamicScrollingList calculateMaxScrollPosition()");
		var t = _entryList.length - _maxListIndex;

		_maxScrollPosition = t > 0 ? t : 0;

		if (_scrollPosition > _maxScrollPosition) {
			scrollPosition = _maxScrollPosition;
		}

		updateScrollbar();
	}

	// These need to be updated
	//-------------------------------------//
	function moveSelectionUp(a_bNextPage:Boolean)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("DynamicScrollingList moveSelecttionUp()");
		var lastPosition = _scrollPosition;
		var d = a_bNextPage? _listIndex : 1;

		if (!_bDisableSelection) {
			if (selectedIndex == -1) {
				selectDefaultIndex();
			} else if (selectedIndex - d > -1) {
				selectedIndex = selectedIndex - d;
			}
		} else {
			scrollPosition = scrollPosition - d;
		}
		_bMouseDrivenNav = false;
		dispatchEvent({type:"listMovedUp", index:_selectedIndex, scrollChanged:lastPosition != _scrollPosition});
	}

	function moveSelectionDown(a_bNextPage:Boolean)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("DynamicScrollingList moveSelectionDown()");
		var lastPosition = _scrollPosition;

		if (!_bDisableSelection) {
			if (selectedIndex == -1) {
				selectDefaultIndex();
			} else if (selectedIndex < _entryList.length - 1) {
				selectedIndex = selectedIndex + 1;
			}
		} else {
			scrollPosition = scrollPosition + 1;
		}
		_bMouseDrivenNav = false;
		dispatchEvent({type:"listMovedDown", index:_selectedIndex, scrollChanged:lastPosition != _scrollPosition});
	}
	//----------------------------//

	function selectDefaultIndex(a_bBottom:Boolean)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("DynamicScrollingList selectDefaultIndex()");
		if (_listIndex > 0) {
			if (a_bBottom) {
				var firstClip = getClipByIndex(0);
				if (firstClip.itemIndex != undefined) {
					doSetSelectedIndex(firstClip.itemIndex, 0);
				}
			} else {
				var lastClip = getClipByIndex(_listIndex - 1);
				if (lastClip.itemIndex != undefined) {
					doSetSelectedIndex(lastClip.itemIndex, 0);
				}
			}
		}
	}

	function setEntryText(a_entryClip:MovieClip, a_entryObject:Object)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("DynamicScrollingList setEntryText()");
		if (a_entryClip.textField != undefined) {
			if (textOption == TEXT_OPTION_SHRINK_TO_FIT) {
				a_entryClip.textField.textAutoSize = "shrink";
			} else if (textOption == TEXT_OPTION_MULTILINE) {
				a_entryClip.textField.verticalAutoSize = "top";
			}

			if (a_entryObject.enabled != undefined) {
				a_entryClip.textField.textColor = a_entryObject.enabled == false ? (6316128) : (16777215);
			}

			if (a_entryObject.disabled != undefined) {
				a_entryClip.textField.textColor = a_entryObject.disabled == true ? (6316128) : (16777215);
			}
		}
	}

	// this function needs to be called after calculateMaxScrollPosition or else it will reset the saved
	// scrollposition to 0
	function RestoreScrollPosition(a_newPosition)
	{
		if (DEBUG_LEVEL > 0) _global.skse.Log("DynamicScrollingList RestoreScrollPosition() pos = " + a_newPosition);
		if (a_newPosition < 0) {
			a_newPosition = 0;
		} else if (a_newPosition > _maxScrollPosition) {
			a_newPosition = _maxScrollPosition;
		}
		
		scrollPosition = a_newPosition;
	}
}