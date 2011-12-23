import gfx.events.EventDispatcher;

class skyui.ItemSortingFilter implements skyui.IFilter
{
	private var _filterArray:Array;
	private var _sortAttributes:Array;
	private var _sortOptions:Array;
	static var DEBUG_LEVEL = 1;

	//Mixin
	var dispatchEvent:Function;
	var addEventListener:Function;

	function ItemSortingFilter()
	{
		EventDispatcher.initialize(this);
	}

	// Set both at once so we don't create 2 filter change events
	function setSortBy(a_sortAttributes:Array, a_sortOptions:Array)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("ItemSortingFilter setSortBy()");
		var changed = _sortAttributes != a_sortAttributes || _sortOptions != a_sortOptions;
		_sortAttributes = a_sortAttributes;
		_sortOptions = a_sortOptions;

		if (changed) {
			dispatchEvent({type:"filterChange"});
		}
	}

	function process(a_filteredList:Array)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("ItemSortingFilter process()");
//		if (_sortBy == SORT_BY_NAME) {
//			a_filteredList.sortOn(["equipState", attr], [Array.NUMERIC | Array.DESCENDING, opt]);
//		} else {
	// 18 = DESCENDING | NUMERIC
	// 16 = ASCENDING | NUMERIC
	var sortDirection = _sortOptions[0];
	var num;
	if (sortDirection == 18) {
		if (DEBUG_LEVEL > 1)
			_global.skse.Log("NEGATIVE");
		num = Number.NEGATIVE_INFINITY;
	}
	else if (sortDirection == 16) {
		if (DEBUG_LEVEL > 1)
			_global.skse.Log("POSITIVE");
		num = Number.POSITIVE_INFINITY;
	}
	
	if (num != undefined)
	{
	for (var i = 0; i < a_filteredList.length;i++)
	{
		if (a_filteredList[i].infoArmor == "-")
		{
			a_filteredList[i].infoArmor = num;
		}
		if (a_filteredList[i].infoDamage == "-")
		{
			a_filteredList[i].infoDamage = num;
		}
	}
		
	}
	
			a_filteredList.sortOn(_sortAttributes, _sortOptions);
			
		for (var i = 0; i < a_filteredList.length; i++)
		{
			if (a_filteredList[i].infoArmor == Number.POSITIVE_INFINITY || a_filteredList[i].infoArmor == Number.NEGATIVE_INFINITY )
			{
				a_filteredList[i].infoArmor = "-";
			}
			if (a_filteredList[i].infoDamage == Number.POSITIVE_INFINITY || a_filteredList[i].infoDamage == Number.NEGATIVE_INFINITY)
			{
				a_filteredList[i].infoDamage = "-";
			}
		}

	}
}