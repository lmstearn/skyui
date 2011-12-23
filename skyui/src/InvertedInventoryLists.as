dynamic class InvertedInventoryLists extends InventoryLists
{
static var DEBUG_LEVEL:Number = 1;
	var strHideItemsCode;
	var strShowItemsCode;


	function InvertedInventoryLists()
	{
		super();
if (DEBUG_LEVEL > 0) skse.Log("InvertedInventoryLists InvertedInventoryLists()");
		this.strHideItemsCode = gfx.ui.NavigationCode.RIGHT;
		this.strShowItemsCode = gfx.ui.NavigationCode.LEFT;
		_CategoriesList._bMagic = true;
	}

}
