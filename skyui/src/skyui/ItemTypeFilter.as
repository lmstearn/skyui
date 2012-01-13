import gfx.events.EventDispatcher;

class skyui.ItemTypeFilter implements skyui.IFilter
{
	private var _itemFilter;
	private var _filterArray:Array;
	private var _bDoNotUpdate:Boolean;

	private var _matcherFunc:Function;

	//Mixin
	var dispatchEvent:Function;
	var addEventListener:Function;

	static var DEBUG_LEVEL = 1;

	function ItemTypeFilter()
	{
		_itemFilter = 0xFFFFFFFF;
		_matcherFunc = entryMatchesFilter;
		_bDoNotUpdate = false;
		
		EventDispatcher.initialize(this);
	}

	function get itemFilter():Number
	{
		return _itemFilter;
	}

	function set itemFilter(a_newFilter:Number)
	{
		if (_itemFilter == a_newFilter) {
			return;
		}
		
		_itemFilter = a_newFilter;
		if (_bDoNotUpdate == false)
			dispatchEvent({type:"filterChange"});
		_bDoNotUpdate = false;
	}
	
	function changeFilterFlag(a_newFilter:Number, a_bDoNotUpdate:Boolean)
	{
		_bDoNotUpdate = a_bDoNotUpdate;
		itemFilter = a_newFilter;
	}
	
	function setPartitionedFilterMode(a_bPartition:Boolean)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("ItemTypeFilter setPartitionFilterMode()");
		_matcherFunc = a_bPartition ? entryMatchesPartitionedFilter : entryMatchesFilter;
	}

	function entryMatchesFilter(a_entry:Object):Boolean
	{
		if (DEBUG_LEVEL > 1)
			_global.skse.Log("ItemTypeFilter entryMatchesFilter()");
		return (a_entry != undefined && (a_entry.filterFlag == undefined || (a_entry.filterFlag & _itemFilter) != 0));
	}

	function entryMatchesPartitionedFilter(a_entry:Object):Boolean
	{
		if (DEBUG_LEVEL > 1)
			_global.skse.Log("ItemTypeFilter entryMatchesPartitionedFilter()");
		var matched = false;
		if (a_entry != undefined) {
			if (_itemFilter == 0xFFFFFFFF) {
				matched = true;
			} else {
				var flag = a_entry.filterFlag;
				matched = (flag & 0xFF) == _itemFilter || ((flag & 0xFF00) >>> 8) == _itemFilter
							|| ((flag & 0xFF0000) >>> 16) == _itemFilter || ((flag & 0xFF000000) >>> 24) == _itemFilter;
			}
		}
		return matched;
	}

	function process(a_filteredList:Array)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("ItemTypeFilter process()");
		for (var i = 0; i < a_filteredList.length; i++) {
			if (!_matcherFunc(a_filteredList[i])) {
				a_filteredList.splice(i,1);
				i--;
			}
		}
	}
}