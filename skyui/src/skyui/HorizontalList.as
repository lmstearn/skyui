import gfx.events.EventDispatcher;
import gfx.ui.NavigationCode;
import Shared.GlobalFunc;
import skyui.Defines;

class skyui.HorizontalList extends skyui.FilteredCategoryList
{
	private var _selectorPos:Number;
	private var _targetSelectorPos:Number;

	// Component settings
	var buttonOption:String;
	var fillOption:String;
	var borderWidth:Number;
	// iconX holds label name for iconX

	// Children
	var selectorCenter:MovieClip;
	var selectorLeft:MovieClip;
	var selectorRight:MovieClip;
	
	var _bMagic:Boolean;
	var _reverseMagicIndex:Number;

	function HorizontalList()
	{
		super();

		_bMagic = false;
		_reverseMagicIndex = 10;
		_selectorPos = 0;
		_targetSelectorPos = 0;

		if (borderWidth != undefined)
		{
			_indent = borderWidth;
		}

		if (buttonOption == "text and icons")
		{
			_bNoIcons = false;

			_bNoText = false;
		}
		else if (buttonOption == "icons only")
		{
			_bNoIcons = false;
			_bNoText = true;
		}
		else
		{
			_bNoIcons = true;
			_bNoText = false;
		}

		if (fillOption == "parent")
		{
			_fillType = FILL_PARENT;
		}
		else if (fillOption == "stage")
		{
			_fillType = FILL_STAGE;
		}
		else
		{
			_fillType = FILL_BORDER;
		}
	}

	// Gets a clip, or if it doesn't exist, creates it.
	function getClipByIndex(a_index):MovieClip
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("HorizontalList getClipByIndex()");
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

		if (!_bNoIcons && this["icon" + a_index] != undefined)
		{
			entryClip.icon.gotoAndStop(this["icon" + a_index]);

			if (_bNoText)
			{
				entryClip.textField._visible = false;
			}
		}
		else
		{
			entryClip.icon._visible = false;
			entryClip.textField._x = 0;
		}

		return entryClip;
	}

	function UpdateList()
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("HorizontalList UpdateList()");
		super.UpdateList();
		updateSelector();
	}

	function onEnterFrame()
	{
		if (_selectedIndex == -1)
		{
			// Set initial category to first entry when opening menu
			if (DEBUG_LEVEL > 1)
				_global.skse.Log("Current category selected index = " + _selectedIndex);
			//if (_prevSelectedIndex != undefined)
				//restoreSelectedEntry(_prevSelectedIndex);
			//else restoreSelectedEntry(_filteredList[0].unfilteredIndex);
			if (_prevFilteredIndex != undefined)
			{
				if (_filteredList[_prevFilteredIndex] != undefined)
					restoreSelectedEntry(_filteredList[_prevFilteredIndex].unfilteredIndex);
				else restoreSelectedEntry(_filteredList[_prevFilteredIndex - 1].unfilteredIndex);
			}
			else restoreSelectedEntry(0);
			if (DEBUG_LEVEL > 1)
				_global.skse.Log("category selected index now = " + _selectedIndex);
		}
		if (_selectorPos < _targetSelectorPos)
		{
			_selectorPos = _selectorPos + (_targetSelectorPos - _selectorPos) * 0.2 + 1;

			refreshSelector();

			if (_selectorPos > _targetSelectorPos)
			{
				_selectorPos = _targetSelectorPos;
			}

		}
		else if (_selectorPos > _targetSelectorPos)
		{
			_selectorPos = _selectorPos - (_selectorPos - _targetSelectorPos) * 0.2 - 1;

			refreshSelector();

			if (_selectorPos < _targetSelectorPos)
			{
				_selectorPos = _targetSelectorPos;
			}
		}
	}

	function updateSelector()
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("HorizontalList updateSelector()");
		if (selectorCenter == undefined)
		{
			return;
		}

		if (_selectedIndex == -1)
		{
			selectorCenter._visible = false;

			if (selectorLeft != undefined)
			{
				selectorLeft._visible = false;
			}
			if (selectorRight != undefined)
			{
				selectorRight._visible = false;
			}

			return;
		}
		if (DEBUG_LEVEL > 1)
			_global.skse.Log("updateSelector() selectedIndex = " + _selectedIndex);
		var selectedClip = getClipByIndex(_entryList[_selectedIndex].filteredIndex);
		if (selectedClip.divider)
			return;
		if (DEBUG_LEVEL > 1)
			_global.skse.Log("updateSelector() selectedClip = " + selectedClip + " name = " + selectedClip.text + " selectedIndex = " + _selectedIndex);
		_targetSelectorPos = selectedClip._x + (selectedClip.buttonArea._width - selectorCenter._width) / 2;

		selectorCenter._visible = true;
		selectorCenter._y = selectedClip._y + selectedClip.buttonArea._height;

		if (selectorLeft != undefined)
		{
			selectorLeft._visible = true;
			selectorLeft._x = 0;
			selectorLeft._y = selectorCenter._y;
		}

		if (selectorRight != undefined)
		{
			selectorRight._visible = true;
			selectorRight._y = selectorCenter._y;
			selectorRight._width = _totalWidth - selectorRight._x;
		}
	}

	function refreshSelector()
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("HorizontalList refreshSelector()");
		selectorCenter._visible = true;
		var selectedClip = getClipByIndex(_entryList[_selectedIndex].filteredIndex);
		if (DEBUG_LEVEL > 1)
			_global.skse.Log("refreshSelector() selectedClip = " + selectedClip + " name = " + selectedClip.text);
		selectorCenter._x = _selectorPos;

		if (selectorLeft != undefined)
		{
			selectorLeft._width = selectorCenter._x;
		}

		if (selectorRight != undefined)
		{
			selectorRight._x = selectorCenter._x + selectorCenter._width;
			selectorRight._width = _totalWidth - selectorRight._x;
		}
	}

	function onItemPress(a_keyboardOrMouse)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("HorizontalList onItemPress()");
		if (!_bDisableInput && !_bDisableSelection && _selectedIndex != -1)
		{

			//_parent._parent.debug.textField.SetText("ItemPress true" + counter);
			updateSelector();
			dispatchEvent({type:"itemPress", index:_selectedIndex, entry:_entryList[_selectedIndex], keyboardOrMouse:a_keyboardOrMouse});
		}
	}

	function handleInput(details, pathToFocus):Boolean
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("HorizontalList handleInput()");
		var processed = false;

		if (!_bDisableInput)
		{
			var entry = getClipByIndex(selectedIndex);

			processed = entry != undefined && entry.handleInput != undefined && entry.handleInput(details, pathToFocus.slice(1));

			if (!processed && GlobalFunc.IsKeyPressed(details))
			{
				if (details.navEquivalent == NavigationCode.LEFT)
				{
					moveSelectionLeft();
					processed = true;
				}
				else if (details.navEquivalent == NavigationCode.RIGHT)
				{
					moveSelectionRight();
					processed = true;
				}
				else if (!_bDisableSelection && details.navEquivalent == NavigationCode.ENTER)
				{
					onItemPress(0);
					processed = true;
				}
			}
		}
		return processed;
	}


}