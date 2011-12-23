dynamic class Shared.CenteredList extends MovieClip
{
static var DEBUG_LEVEL:Number = 1;
	var BottomHalf;
	var EntriesA;
	var SelectedEntry;
	var TopHalf;
	var bMultilineList;
	var bRepositionEntries;
	var bToFitList;
	var dispatchEvent;
	var fCenterY;
	var iMaxEntriesBottomHalf;
	var iMaxEntriesTopHalf;
	var iSelectedIndex;

	function CenteredList()
	{
		super();
if (DEBUG_LEVEL > 0) skse.Log("Shared.CenteredList CenteredList()");
		this.TopHalf = this.TopHalf;
		this.SelectedEntry = this.SelectedEntry;
		this.BottomHalf = this.BottomHalf;
		this.EntriesA = new Array();
		gfx.events.EventDispatcher.initialize(this);
		Mouse.addListener(this);
		this.iSelectedIndex = 0;
		this.fCenterY = this.SelectedEntry._y + this.SelectedEntry._height / 2;
		this.bRepositionEntries = true;
		this.iMaxEntriesTopHalf = 0;
		while (this.TopHalf["Entry" + this.iMaxEntriesTopHalf] != undefined) 
		{
			++this.iMaxEntriesTopHalf;
		}
		this.iMaxEntriesBottomHalf = 0;
		for (;;) 
		{
			if (this.BottomHalf["Entry" + this.iMaxEntriesBottomHalf] == undefined) 
			{
				return;
			}
			++this.iMaxEntriesBottomHalf;
		}
	}

	function ClearList()
	{
if (DEBUG_LEVEL > 0) skse.Log("Shared.CenteredList ClearList()");
		this.EntriesA.splice(0, this.EntriesA.length);
	}

	function handleInput(details, pathToFocus)
	{
if (DEBUG_LEVEL > 0) skse.Log("Shared.CenteredList handleInput()");
		var __reg2 = false;
		if (Shared.GlobalFunc.IsKeyPressed(details)) 
		{
			if (details.navEquivalent == gfx.ui.NavigationCode.UP) 
			{
				this.moveListDown();
				__reg2 = true;
			}
			else if (details.navEquivalent == gfx.ui.NavigationCode.DOWN) 
			{
				this.moveListUp();
				__reg2 = true;
			}
			else if (details.navEquivalent == gfx.ui.NavigationCode.ENTER && this.iSelectedIndex != -1) 
			{
				this.dispatchEvent({type: "itemPress", index: this.iSelectedIndex, entry: this.EntriesA[this.iSelectedIndex]});
				__reg2 = true;
			}
		}
		return __reg2;
	}

	function onMouseWheel(delta)
	{
if (DEBUG_LEVEL > 0) skse.Log("Shared.CenteredList onMouseWheel()");
		var __reg2 = Mouse.getTopMostEntity();
		for (;;) 
		{
			if (!(__reg2 && __reg2 != undefined && gfx.managers.FocusHandler.instance.getFocus(0) == this)) 
			{
				return;
			}
			if (__reg2 == this) 
			{
				if (delta < 0) 
				{
					this.moveListUp();
				}
				else if (delta > 0) 
				{
					this.moveListDown();
				}
			}
			__reg2 = __reg2._parent;
		}
	}

	function onPress(aiMouseIndex, aiKeyboardOrMouse)
	{
if (DEBUG_LEVEL > 0) skse.Log("Shared.CenteredList onPress()");
		var __reg2 = Mouse.getTopMostEntity();
		for (;;) 
		{
			if (!(__reg2 && __reg2 != undefined)) 
			{
				return;
			}
			if (__reg2 == this.SelectedEntry) 
			{
				this.dispatchEvent({type: "itemPress", index: this.iSelectedIndex, entry: this.EntriesA[this.iSelectedIndex], keyboardOrMouse: aiKeyboardOrMouse});
			}
			__reg2 = __reg2._parent;
		}
	}

	function onPressAux(aiMouseIndex, aiKeyboardOrMouse, aiButtonIndex)
	{
if (DEBUG_LEVEL > 0) skse.Log("Shared.CenteredList onPressAux()");
		if (aiButtonIndex == 1) 
		{
			var __reg2 = Mouse.getTopMostEntity();
			for (;;) 
			{
				if (!(__reg2 && __reg2 != undefined)) 
				{
					return;
				}
				if (__reg2 == this.SelectedEntry) 
				{
					this.dispatchEvent({type: "itemPressAux", index: this.iSelectedIndex, entry: this.EntriesA[this.iSelectedIndex], keyboardOrMouse: aiKeyboardOrMouse});
				}
				__reg2 = __reg2._parent;
			}
		}
	}

	function get selectedTextString()
	{
if (DEBUG_LEVEL > 0) skse.Log("Shared.CenteredList get selectedTextString()");
		return this.EntriesA[this.iSelectedIndex].text;
	}

	function get selectedIndex()
	{
if (DEBUG_LEVEL > 0) skse.Log("Shared.CenteredList get selectedIndex()");
		return this.iSelectedIndex;
	}

	function set selectedIndex(aiNewIndex)
	{
if (DEBUG_LEVEL > 0) skse.Log("Shared.CenteredList set selectedIndex()");
		this.iSelectedIndex = aiNewIndex;
	}

	function get selectedEntry()
	{
if (DEBUG_LEVEL > 0) skse.Log("Shared.CenteredList get selectedEntry()");
		return this.EntriesA[this.iSelectedIndex];
	}

	function get entryList()
	{
if (DEBUG_LEVEL > 0) skse.Log("Shared.CenteredList get entryList()");
		return this.EntriesA;
	}

	function set entryList(anewArray)
	{
if (DEBUG_LEVEL > 0) skse.Log("Shared.CenteredList set entryList()");
		this.EntriesA = anewArray;
	}

	function moveListUp()
	{
if (DEBUG_LEVEL > 0) skse.Log("Shared.CenteredList moveListUp()");
		if (this.iSelectedIndex < this.EntriesA.length - 1) 
		{
			++this.iSelectedIndex;
			this.UpdateList();
			this.dispatchEvent({type: "listMovedUp"});
		}
	}

	function moveListDown()
	{
if (DEBUG_LEVEL > 0) skse.Log("Shared.CenteredList moveListDown()");
		if (this.iSelectedIndex > 0) 
		{
			--this.iSelectedIndex;
			this.UpdateList();
			this.dispatchEvent({type: "listMovedDown"});
		}
	}

	function UpdateList()
	{
if (DEBUG_LEVEL > 0) skse.Log("Shared.CenteredList UpdateList()");
		var __reg2 = undefined;
		this.iSelectedIndex = Math.min(Math.max(this.iSelectedIndex, 0), this.EntriesA.length - 1);
		if (this.iSelectedIndex > 0) 
		{
			this.UpdateTopHalf(this.EntriesA.slice(0, this.iSelectedIndex));
		}
		else 
		{
			this.UpdateTopHalf(__reg2);
		}
		this.SetEntry(this.SelectedEntry, this.EntriesA[this.iSelectedIndex]);
		if (this.iSelectedIndex < this.EntriesA.length - 1) 
		{
			this.UpdateBottomHalf(this.EntriesA.slice(this.iSelectedIndex + 1));
		}
		else 
		{
			this.UpdateBottomHalf(__reg2);
		}
		this.RepositionEntries();
	}

	function UpdateTopHalf(aEntryArray)
	{
if (DEBUG_LEVEL > 0) skse.Log("Shared.CenteredList UpdateTopHalf()");
		var __reg2 = this.iMaxEntriesTopHalf - 1;
		for (;;) 
		{
			if (__reg2 < 0) 
			{
				return;
			}
			var __reg3 = __reg2 - (this.iMaxEntriesTopHalf - aEntryArray.length);
			if (__reg3 >= 0 && __reg3 < aEntryArray.length) 
			{
				this.SetEntry(this.TopHalf["Entry" + __reg2], aEntryArray[__reg3]);
			}
			else 
			{
				this.SetEntry(this.TopHalf["Entry" + __reg2]);
			}
			--__reg2;
		}
	}

	function UpdateBottomHalf(aTextArray)
	{
if (DEBUG_LEVEL > 0) skse.Log("Shared.CenteredList UpdateBottomHalf()");
		var __reg2 = 0;
		for (;;) 
		{
			if (__reg2 >= this.iMaxEntriesBottomHalf) 
			{
				return;
			}
			if (__reg2 < aTextArray.length) 
			{
				this.SetEntry(this.BottomHalf["Entry" + __reg2], aTextArray[__reg2]);
			}
			else 
			{
				this.SetEntry(this.BottomHalf["Entry" + __reg2]);
			}
			++__reg2;
		}
	}

	function SetEntry(aEntryClip, aEntryObject)
	{
if (DEBUG_LEVEL > 0) skse.Log("Shared.CenteredList SetEntry()");
		if (this.bMultilineList == true) 
		{
			aEntryClip.textField.verticalAutoSize = "top";
		}
		if (this.bToFitList == true) 
		{
			aEntryClip.textField.textAutoSize = "shrink";
		}
		if (aEntryObject.text != undefined) 
		{
			if (aEntryObject.count > 1) 
			{
				aEntryClip.textField.SetText(aEntryObject.text + " (" + aEntryObject.count + ")");
			}
			else 
			{
				aEntryClip.textField.SetText(aEntryObject.text);
			}
			return;
		}
		aEntryClip.textField.SetText(" ");
	}

	function SetupMultilineList()
	{
if (DEBUG_LEVEL > 0) skse.Log("Shared.CenteredList SetupMultilineList()");
		this.bMultilineList = true;
		var __reg2 = 0;
		while (__reg2 < this.iMaxEntriesTopHalf) 
		{
			this.TopHalf["Entry" + __reg2].textField.verticalAutoSize = "top";
			++__reg2;
		}
		__reg2 = 0;
		while (__reg2 < this.iMaxEntriesBottomHalf) 
		{
			this.BottomHalf["Entry" + __reg2].textField.verticalAutoSize = "top";
			++__reg2;
		}
		if (this.SelectedEntry != undefined) 
		{
			this.SelectedEntry.textField.verticalAutoSize = "top";
		}
	}

	function SetupToFitList()
	{
if (DEBUG_LEVEL > 0) skse.Log("Shared.CenteredList SetupToFitList()");
		this.bToFitList = true;
		var __reg2 = 0;
		while (__reg2 < this.iMaxEntriesTopHalf) 
		{
			this.TopHalf["Entry" + __reg2].textField.textAutoSize = "shrink";
			++__reg2;
		}
		__reg2 = 0;
		while (__reg2 < this.iMaxEntriesBottomHalf) 
		{
			this.BottomHalf["Entry" + __reg2].textField.textAutoSize = "shrink";
			++__reg2;
		}
		if (this.SelectedEntry != undefined) 
		{
			this.SelectedEntry.textField.textAutoSize = "shrink";
		}
	}

	function RepositionEntries()
	{
if (DEBUG_LEVEL > 0) skse.Log("Shared.CenteredList RepositionEntries()");
		if (this.bRepositionEntries) 
		{
			var __reg3 = 0;
			var __reg2 = 0;
			while (__reg2 < this.iMaxEntriesTopHalf) 
			{
				this.TopHalf["Entry" + __reg2]._y = __reg3;
				__reg3 = __reg3 + this.TopHalf["Entry" + __reg2]._height;
				++__reg2;
			}
			__reg3 = 0;
			__reg2 = 0;
			while (__reg2 < this.iMaxEntriesBottomHalf) 
			{
				this.BottomHalf["Entry" + __reg2]._y = __reg3;
				__reg3 = __reg3 + this.BottomHalf["Entry" + __reg2]._height;
				++__reg2;
			}
			this.SelectedEntry._y = this.fCenterY - this.SelectedEntry._height / 2;
			this.TopHalf._y = this.SelectedEntry._y - this.TopHalf._height;
			this.BottomHalf._y = this.SelectedEntry._y + this.SelectedEntry._height;
		}
	}

}
