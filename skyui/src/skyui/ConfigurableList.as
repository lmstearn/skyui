import skyui.Config;
import skyui.Util;
import Shared.GlobalFunc;
import gfx.ui.NavigationCode;

class skyui.ConfigurableList extends skyui.FilteredList
{
	private var _config:Config;

	private var _views:Array;
	private var _prefData:Array;
	private var _categoryData:Array;
	private var _categoryFlag:Number;
	private var _activeViewIndex:Number;

	private var _activeColumnIndex:Number;
	private var _lastViewIndex:Number;
	private var _pressed:Number;

	// 1 .. n
	private var _activeColumnState:Number;

	private var _saveSortHeaders:Boolean;
	private var _saveItemSelection:Boolean;

	private var _bEnableItemIcon:Boolean;
	private var _bEnableEquipIcon:Boolean;
	private var _bRestoreColumnData:Boolean;

	// Preset in config
	private var _entryWidth:Number;

	// --- Store lots of pre-calculated values in memory so we don't have to recalculate them for each entry

	// [c1.x, c1.y, c2.x, c2.y, ...] - (x,y) Offset of column fields in a row (relative to the entry clip)
	private var _columnPositions:Array;

	// [c1.width, c1.height, c2.width, c2.height, ...]
	private var _columnSizes:Array;

	// These are the names like textField0, equipIcon etc used when positioning, not the names as defined in the config
	private var _columnNames:Array;
	private var _hiddenColumnNames:Array;

	// Only used for textfield-based columns
	private var _columnEntryValues:Array;

	private var _customEntryFormats:Array;
	private var _defaultEntryFormat:TextFormat;
	private var _defaultLabelFormat:TextFormat;

	// Children
	var header:MovieClip;


	function ConfigurableList()
	{
		super();

		_columnPositions = new Array();
		_columnSizes = new Array();
		_columnNames = new Array();
		_hiddenColumnNames = new Array();
		_columnEntryValues = new Array();
		_customEntryFormats = new Array();
		_prefData = new Array();
		_categoryData = new Array();

		_defaultEntryFormat = new TextFormat();
		_defaultLabelFormat = new TextFormat();

		_config = undefined;

		// Reasonable defaults, will be overridden later
		_entryWidth = 525;
		_entryHeight = 28;
		_activeViewIndex = -1;
		_lastViewIndex = -1;
		_bRestoreColumnData = false;
		_bEnableItemIcon = false;
		_bEnableEquipIcon = false;
		_pressed = 0;
		_activeColumnState = 1;
		_activeColumnIndex = 0;

		Config.instance.addEventListener("configLoad",this,"onConfigLoad");

		Util.addArrayFunctions();
	}

	function onLoad()
	{
		super.onLoad();

		if (header != 0) {
			header.addEventListener("columnPress",this,"onColumnPress");
		}
	}

	function get currentView()
	{
		return _views[_activeViewIndex];
	}

	function get columnData()
	{
		return _prefData;
	}

	function get categoryData()
	{
		return _categoryData;
	}

	function set restoreColumnData(a_flag:Boolean)
	{
		_bRestoreColumnData = a_flag;
	}

	function onConfigLoad(event)
	{
		super.onConfigLoad(event);
		_config = event.config;
		// 0 - disabled, 1 - per cat, 2 - global
		_saveSortHeaders = _config.Sort.saveSortHeaders;
		// 0 - disabled, 1 - save item selection position
		_saveItemSelection = _config.Sort.saveItemSelection;
	}

	// Has to be called before the list can be used
	function setConfigSection(a_section:String)
	{
		_global.skse.Log("ConfigurableList setConfigSection()");
		_views = _config[a_section].views;
		_entryWidth = _config[a_section].entry.width;

		// Create default formats
		for (var prop in _config[a_section].entry.format) {
			if (_defaultEntryFormat.hasOwnProperty(prop)) {
				_defaultEntryFormat[prop] = _config[a_section].entry.format[prop];
			}
		}

		for (var prop in _config[a_section].label.format) {
			if (_defaultLabelFormat.hasOwnProperty(prop)) {
				_defaultLabelFormat[prop] = _config[a_section].label.format[prop];
			}
		}
	}

	function createEntryClip(a_index:Number):MovieClip
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("ConfigurableList createEntryClip " + a_index);
		}
		var entryClip = attachMovie(_entryClassName, "Entry" + a_index, getNextHighestDepth());

		for (var i = 0; entryClip["textField" + i] != undefined; i++) {
			entryClip["textField" + i]._visible = false;
		}
		entryClip["itemIcon"]._visible = false;
		entryClip["equipIcon"]._visible = false;

		entryClip.viewIndex = -1;

		return entryClip;
	}

	function setEntry(a_entryClip:MovieClip, a_entryObject:Object)
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("ConfigurableList setEntry " + a_entryObject.text + " at clipIndex " + a_entryClip.clipIndex);
		}
		if (_activeViewIndex != -1 && a_entryClip.viewIndex != _activeViewIndex) {
			a_entryClip.viewIndex = _activeViewIndex;

			var columns = currentView.columns;

			a_entryClip.border._width = a_entryClip.selectArea._width = _entryWidth;
			a_entryClip.border._height = a_entryClip.selectArea._height = _entryHeight;

			var iconY = _entryHeight * 0.25;
			var iconSize = _entryHeight * 0.5;

			a_entryClip.bestIcon._height = a_entryClip.bestIcon._width = iconSize;
			a_entryClip.favoriteIcon._height = a_entryClip.favoriteIcon._width = iconSize;
			a_entryClip.poisonIcon._height = a_entryClip.poisonIcon._width = iconSize;
			a_entryClip.stolenIcon._height = a_entryClip.stolenIcon._width = iconSize;
			a_entryClip.enchIcon._height = a_entryClip.enchIcon._width = iconSize;

			a_entryClip.bestIcon._y = iconY;
			a_entryClip.favIcon._y = iconY;
			a_entryClip.poisonIcon._y = iconY;
			a_entryClip.stolenIcon._y = iconY;
			a_entryClip.enchIcon._y = iconY;

			for (var i = 0; i < columns.length; i++) {
				var e = a_entryClip[_columnNames[i]];
				e._visible = true;

				e._x = _columnPositions[i * 2];
				e._y = _columnPositions[i * 2 + 1];

				if (_columnSizes[i * 2] > 0) {
					e._width = _columnSizes[i * 2];
				}

				if (_columnSizes[i * 2 + 1] > 0) {
					e._height = _columnSizes[i * 2 + 1];
				}

				if (e instanceof TextField) {
					if (_customEntryFormats[i] != undefined) {
						e.setTextFormat(_customEntryFormats[i]);
					} else {
						e.setTextFormat(_defaultEntryFormat);
					}
				}
			}

			for (var i = 0; i < _hiddenColumnNames.length; i++) {
				var e = a_entryClip[_hiddenColumnNames[i]];
				e._visible = false;
			}
		}

		super.setEntry(a_entryClip,a_entryObject);
	}

	// called when switching categories
	function changeFilterFlag(a_flag:Number)
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("ConfigurableList changeFilterFlag " + a_flag);
		}
		_categoryFlag = a_flag;
		// Find a match, or use last index
		for (var i = 0; i < _views.length; i++) {

			// Wrap in list if necessary
			if (!((_views[i].category) instanceof Array)) {
				_views[i].category = [_views[i].category];
			}

			if (_views[i].category.indexOf(a_flag) != undefined || i == _views.length - 1) {
				_activeViewIndex = i;
				break;
			}
		}

		if (_activeViewIndex == -1) {
			return;
		}

		if (_lastViewIndex == _activeViewIndex && _saveSortHeaders != 1) {
			// since no sort parameters have changed we must trigger a filter change
			InvalidateData();
			return;
		}

		var _bResult = false;
		if (_saveSortHeaders == 1) {
			_bResult = findCategoryMatch(a_flag);
		} else if (_saveSortHeaders == 2) {
			_bResult = findSortMatch();

		}
		if (!_bResult) {
			_lastViewIndex = _activeViewIndex;
			_activeColumnState = 1;
			_activeColumnIndex = _views[_activeViewIndex].columns.indexOf(_views[_activeViewIndex].primaryColumn);

			if (_activeColumnIndex == undefined) {
				_activeColumnIndex = 0;
			}
			_bRestoreColumnData = true;
			updateView();
		} else {
			updateView();
			// since no sort parameters have changed we must invalidatedata
			InvalidateData();
		}
	}

	function findCategoryMatch(a_flag):Boolean
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("ConfigurableList findCategoryMatch()");
		}
		for (var i = 0; i < _categoryData.length; i++) {
			if (a_flag == _categoryData[i][3]) {
				_global.skse.Log("found category match " + _categoryData[i][3]);
				if (_categoryData[i].length > 0) {
					for (var j = 0; j < _categoryData[i].length; j++) {
						_global.skse.Log("restoring category data " + _categoryData[i][j] + " in pos " + i);
					}

					_lastViewIndex = _categoryData[i][0];
					_activeColumnIndex = _categoryData[i][1];
					_activeColumnState = _categoryData[i][2];
					return true;
				}
			}
		}
		return false;
	}

	function findSortMatch():Boolean
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("ConfigurableList findSortMatch()");
		}
		// restore old data if column header has not been pressed 
		if (_prefData.length > 0 && _bRestoreColumnData) {
			_lastViewIndex = _prefData[0];
			_activeColumnIndex = _prefData[1];
			_activeColumnState = _prefData[2];
		}
		// Check if columns match 
		for (var i = 0; i < _views[_activeViewIndex].columns.length; i++) {
			if (_views[_activeViewIndex].columns[i] == _views[_lastViewIndex].columns[_activeColumnIndex]) {
				_activeColumnIndex = i;
				_lastViewIndex = _activeViewIndex;
				return true;
			}
		}

		// Check if sortoptions and sortattributes match
		var lastStateData = _views[_lastViewIndex].columns[_activeColumnIndex]["state" + _activeColumnState];
		for (var i = 0; i < _views[_activeViewIndex].columns.length; i++) {
			if (_views[_activeViewIndex].columns[i].states == undefined) {
				continue;
			}
			for (var j = 1; j <= _views[_activeViewIndex].columns[i].states; j++) {
				var currentStateData = _views[_activeViewIndex].columns[i]["state" + j];
				if (currentStateData.entry.text == lastStateData.entry.text) {
					if (arraysEqual(currentStateData.sortAttributes, lastStateData.sortAttributes) && arraysEqual(currentStateData.sortOptions, lastStateData.sortOptions) && (currentStateData.label.arrowDown == lastStateData.label.arrowDown)) {
						_activeColumnState = j;
						_lastViewIndex = _activeViewIndex;
						return true;
					}
				}
			}
		}

		return false;

	}

	function saveColumnData()
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("ConfigurableList saveColumnData()");
		}
		if (_saveSortHeaders == 0) {
			return;
		}

		if (_saveSortHeaders == 1) {
			for (var i = 0; i < _categoryData.length; i++) {
				_global.skse.Log("checking categoryData pos " + i + " for match...");
				if (_categoryData[i][3] == _categoryFlag) {
					_global.skkse.Log("Found match for flag " + _categoryFlag);
					_categoryData[i][0] = _lastViewIndex;
					_categoryData[i][1] = _activeColumnIndex;
					_categoryData[i][2] = _activeColumnState;
					return;
				}
			}
			_global.skse.Log("adding category " + _categoryFlag + " data...");
			_categoryData.push(new Array(4));
			var index:Number = _categoryData.length - 1;
			_categoryData[index][0] = _lastViewIndex;
			_categoryData[index][1] = _activeColumnIndex;
			_categoryData[index][2] = _activeColumnState;
			_categoryData[index][3] = _categoryFlag;
			for (var i = 0; i < _categoryData.length; i++) {
				_global.skse.Log("printing category " + _categoryData[i][3]);
				for (var j = 0; j < _categoryData[i].length; j++) {
					_global.skse.Log("pos j = " + _categoryData[i][j]);
				}
			}
			return;
		}
		// saveSortHeaders = 3 
		_prefData[0] = _lastViewIndex;
		_prefData[1] = _activeColumnIndex;
		_prefData[2] = _activeColumnState;
	}

	function arraysEqual(a:Array, b:Array):Boolean
	{
		if (a == undefined && b == undefined) {
			return true;
		}
		if (a.length != b.length) {
			return false;
		}
		var len = a.length;
		for (var i = 0; i < len; i++) {
			if (a[i] !== b[i]) {
				return false;
			}
		}
		return true;
	}

	function onColumnPress(event)
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("ConfigurableList onColumnPress " + event.index);
		}
		if (event.index != undefined) {
			selectColumn(event.index);
		}
	}

	function selectColumn(a_index:Number)
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("ConfigurableList selectColumn()");
		}

		if (DEBUG_LEVEL > 1) {
			_global.skse.Log("ConfigurableList selected column " + a_index);
		}
		// Invalid column 
		if (currentView.columns[a_index] == undefined) {
			return;
		}
		// Don't process for passive columns 
		if (currentView.columns[a_index].passive) {
			return;
		}

		if (_activeColumnIndex != a_index) {
			_activeColumnIndex = a_index;
			_activeColumnState = 1;
		} else {
			if (_activeColumnState < currentView.columns[_activeColumnIndex].states) {
				_activeColumnState++;
			} else {
				_activeColumnState = 1;
			}
		}

		// save column data
		saveColumnData();
		_bRestoreColumnData = false;
		_pressed = 1;
		updateView();
	}

	function handleInput(details, pathToFocus):Boolean
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("ConfigurableList handleInput()");
		}
		var processed = super.handleInput(details, pathToFocus);

		if (!_bDisableInput && !processed && _platform != 0) {

			if (GlobalFunc.IsKeyPressed(details)) {
				if (details.navEquivalent == NavigationCode.GAMEPAD_L1) {
					selectColumn(_activeColumnIndex - 1);
					processed = true;
				} else if (details.navEquivalent == NavigationCode.GAMEPAD_R1) {
					selectColumn(_activeColumnIndex + 1);
					processed = true;
				} else if (details.navEquivalent == NavigationCode.GAMEPAD_L3) {
					selectColumn(_activeColumnIndex);
					processed = true;
				}
			}
		}
		return processed;
	}

	/* Calculate new column positions and widths for current view */
	function updateView()
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("ConfigurableList updateView()");
		}
		_bEnableItemIcon = false;
		_bEnableEquipIcon = false;

		var columns = currentView.columns;

		// Subtract arrow tip width
		var weightedWidth = _entryWidth - 12;
		var weightSum = 0;
		var maxHeight = 0;

		var textFieldIndex = 0;

		_columnPositions.splice(0);
		_columnSizes.splice(0);
		_columnNames.splice(0);
		_hiddenColumnNames.splice(0);
		_columnEntryValues.splice(0);
		_customEntryFormats.splice(0);

		// Set bit at position i if column is weighted
		var weightedFlags = 0;
		if (DEBUG_LEVEL > 1) {
			_global.skse.Log("ConfigurableList columns length = " + columns.length);
		}
		// Move some data from current state to root of the column so we can access single- and multi-state columns in the same manner 
		for (var i = 0; i < columns.length; i++) {
			if (DEBUG_LEVEL > 1) {
				_global.skse.Log("ConfigurableList configuring states for column " + columns[i].text);
			}
			// Single-state 
			if (columns[i].states == undefined || columns[i].states < 2) {
				continue;
			}
			// Non-active columns always use state 1 
			var stateData;
			if (i == _activeColumnIndex) {
				stateData = columns[i]["state" + _activeColumnState];
			} else {
				stateData = columns[i]["state1"];
			}

			// Might have to create parents nodes first
			if (columns[i].label == undefined) {
				columns[i].label = {};
			}
			if (columns[i].entry == undefined) {
				columns[i].entry = {};
			}

			columns[i].label.text = stateData.label.text;
			columns[i].label.arrowDown = stateData.label.arrowDown;
			columns[i].entry.text = stateData.entry.text;
			columns[i].sortAttributes = stateData.sortAttributes;
			columns[i].sortOptions = stateData.sortOptions;
		}

		// Subtract fixed widths to get weighted width & summ up weights & already set as much as possible
		for (var i = 0; i < columns.length; i++) {
			if (DEBUG_LEVEL > 1) {
				_global.skse.Log("ConfigurableList configuring widths for column " + columns[i].text);
			}
			if (columns[i].weight != undefined) {
				weightSum += columns[i].weight;
				weightedFlags = (weightedFlags | 1) << 1;
			} else {
				weightedFlags = (weightedFlags | 0) << 1;
			}

			if (columns[i].indent != undefined) {
				weightedWidth -= columns[i].indent;
			}
			// Height including borders for maxHeight 
			var curHeight = 0;

			switch (columns[i].type) {
					// ITEM ICON + EQUIP ICON
				case Config.COL_TYPE_ITEM_ICON :
				case Config.COL_TYPE_EQUIP_ICON :

					if (columns[i].type == Config.COL_TYPE_ITEM_ICON) {
						_columnNames[i] = "itemIcon";
						_bEnableItemIcon = true;
					} else if (columns[i].type == Config.COL_TYPE_EQUIP_ICON) {
						_columnNames[i] = "equipIcon";
						_bEnableEquipIcon = true;
					}

					if (columns[i].icon.size != undefined) {
						_columnSizes[i * 2] = columns[i].icon.size;
						weightedWidth -= columns[i].icon.size;

						_columnSizes[i * 2 + 1] = columns[i].icon.size;
						curHeight += columns[i].icon.size;
					}

					break;

					// REST
				default :
					_columnNames[i] = "textField" + textFieldIndex++;

					if (columns[i].entry.width != undefined) {
						_columnSizes[i * 2] = columns[i].entry.width;
						weightedWidth -= columns[i].entry.width;
					} else {
						_columnSizes[i * 2] = 0;
					}

					if (columns[i].entry.height != undefined) {
						_columnSizes[i * 2 + 1] = columns[i].entry.height;
					} else {
						_columnSizes[i * 2 + 1] = 0;
					}

					_columnEntryValues[i] = columns[i].entry.text;

					if (columns[i].entry.format != undefined) {
						var customFormat = new TextFormat();

						// Duplicate default format
						for (var prop in _defaultEntryFormat) {
							customFormat[prop] = _defaultEntryFormat[prop];
						}

						// Overrides
						for (var prop in columns[i].entry.format) {
							if (customFormat.hasOwnProperty(prop)) {
								customFormat[prop] = columns[i].entry.format[prop];
							}
						}

						_customEntryFormats[i] = customFormat;
					}
			}

			if (columns[i].border != undefined) {
				weightedWidth -= columns[i].border[0] + columns[i].border[1];
				curHeight += columns[i].border[2] + columns[i].border[3];
				_columnPositions[i * 2 + 1] = columns[i].border[2];
			} else {
				_columnPositions[i * 2 + 1] = 0;
			}

			if (curHeight > maxHeight) {
				maxHeight = curHeight;
			}
		}

		if (weightSum > 0 && weightedWidth > 0 && weightedFlags != 0) {
			for (var i = columns.length - 1; i >= 0; i--) {
				if ((weightedFlags >>>= 1) & 1) {
					if (columns[i].border != undefined) {
						_columnSizes[i * 2] += ((columns[i].weight / weightSum) * weightedWidth) - columns[i].border[0] - columns[i].border[1];
					} else {
						_columnSizes[i * 2] += (columns[i].weight / weightSum) * weightedWidth;
					}
				}
			}
		}
		// Set x positions based on calculated widths 
		var xPos = 0;

		for (var i = 0; i < columns.length; i++) {

			if (columns[i].indent != undefined) {
				xPos += columns[i].indent;
			}

			if (columns[i].border != undefined) {
				xPos += columns[i].border[0];
				_columnPositions[i * 2] = xPos;
				xPos += columns[i].border[1] + _columnSizes[i * 2];
			} else {
				_columnPositions[i * 2] = xPos;
				xPos += _columnSizes[i * 2];
			}
		}

		while (textFieldIndex < 10)
		{
			_hiddenColumnNames.push("textField" + textFieldIndex++);
		}

		if (!_bEnableItemIcon) {
			_hiddenColumnNames.push("itemIcon");
		}

		if (!_bEnableEquipIcon) {
			_hiddenColumnNames.push("equipIcon");
		}
		// Set up header 
		if (header != undefined) {

			header.clearColumns();
			header.activeColumnIndex = _activeColumnIndex;

			if (columns[_activeColumnIndex].label.arrowDown == true) {
				header.isArrowDown = true;
			} else {
				header.isArrowDown = false;
			}

			for (var i = 0; i < columns.length; i++) {
				var btn = header.addColumn(i);

				btn.label._x = 0;

				if (columns[i].border != undefined) {
					btn._x = _columnPositions[i * 2] - columns[i].border[0];
					btn.label._width = _columnSizes[i * 2] + columns[i].border[0] + columns[i].border[1];

				} else {
					btn._x = _columnPositions[i * 2];
					btn.label._width = _columnSizes[i * 2];
				}

				btn.label.setTextFormat(_defaultLabelFormat);


				if (columns[i].entry.format != undefined) {
					var customFormat = new TextFormat();

					// Duplicate default format
					for (var prop in _defaultLabelFormat) {
						customFormat[prop] = _defaultLabelFormat[prop];
					}

					// Overrides
					for (var prop in columns[i].label.format) {
						if (customFormat.hasOwnProperty(prop)) {
							customFormat[prop] = columns[i].label.format[prop];
						}
					}

					btn.label.setTextFormat(customFormat);
				} else {
					btn.label.setTextFormat(_defaultLabelFormat);
				}

				btn.label.SetText(columns[i].label.text);
			}

			header.activeColumn = _activeColumnIndex;
			header.positionButtons();
		}

		_entryHeight = maxHeight;
		_maxListIndex = Math.floor((_listHeight / _entryHeight) + 0.05);

		setScrollDelta(_maxListIndex);

		updateSortParams();
	}

	function updateSortParams()
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("ConfigurableList updateSortParams()");
		}
		var columns = currentView.columns;
		var sortAttributes = columns[_activeColumnIndex].sortAttributes;
		var sortOptions = columns[_activeColumnIndex].sortOptions;
		if (DEBUG_LEVEL > 1) {
			_global.skse.Log("ConfigurableList updateSortParams(), columns length = " + columns.length + ", sortAttributes = " + sortAttributes + ", sortOptions = " + sortOptions + ", activeColumnIndex = " + _activeColumnIndex);
		}
		if (sortOptions == undefined) {
			return;
		}
		// No attribute(s) set? Try to use entry value 
		if (sortAttributes == undefined) {
			if (_columnEntryValues[_activeColumnIndex] != undefined) {

				if (_columnEntryValues[_activeColumnIndex].charAt(0) == "@") {
					sortAttributes = [_columnEntryValues[_activeColumnIndex].slice(1)];
				}
			}
		}

		if (sortAttributes == undefined) {
			return;
		}
		// Wrap single attribute in array 
		if (!sortAttributes instanceof Array) {
			sortAttributes = [sortAttributes];
		}
		if (!sortOptions instanceof Array) {
			sortOptions = [sortOptions];
		}
		dispatchEvent({type:"sortChange", attributes:sortAttributes, options:sortOptions, pressed:_pressed});
	}
}