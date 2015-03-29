import Components.CrossPlatformButtons;
import gfx.io.GameDelegate;
import gfx.ui.InputDetails;
import Shared.GlobalFunc;
import gfx.ui.NavigationCode;
import gfx.managers.FocusHandler;
import Shared.coords;





dynamic class QuestsPage extends MovieClip
{
	var DescriptionText: TextField;
	var Divider: MovieClip;
	var NoQuestsText: TextField;
	var ObjectiveList: Object;
	var ObjectivesHeader: MovieClip;
	var QuestTitleText: TextField;
	var TitleList: MovieClip;
	var TitleList_mc: MovieClip;
	var bAllowShowOnMap: Boolean;
	var bHasMiscQuests: Boolean;
	var bUpdated: Boolean;
	var iPlatform: Number;
	var objectiveList: Object;
	var objectivesHeader: MovieClip;
	var questDescriptionText: TextField;
	var questTitleEndpieces: MovieClip;
	var questTitleText: TextField;


	private var _showOnMapButton: MovieClip;
	private var _toggleActiveButton: MovieClip;
	private var _bottomBar: MovieClip;

	private var _toggleActiveControls: Object;
	private var _showOnMapControls: Object;
	private var _deleteControls: Object;

	//For Quest
	private var _toggleActiveButton1: MovieClip;
	private var holdInput = new  Array();
	private var holdsToggle: Boolean;
	private var holdTitleList: MovieClip;
	private var shelfTitleList: MovieClip;
	
	
	function QuestsPage()
	{
		super();
		TitleList = TitleList_mc.List_mc;
		DescriptionText = questDescriptionText;
		QuestTitleText = questTitleText;
		ObjectiveList = objectiveList;
		ObjectivesHeader = objectivesHeader;
		bHasMiscQuests = false;
		bUpdated = false;

		_bottomBar = _parent._parent.BottomBar_mc;
	}

	function onLoad()
	{
		QuestTitleText.SetText(" ");
		DescriptionText.SetText(" ");
		DescriptionText.verticalAutoSize = "top";
		QuestTitleText.textAutoSize = "shrink";
		TitleList.addEventListener("itemPress", this, "onTitleListSelect");
		TitleList.addEventListener("listMovedUp", this, "onTitleListMoveUp");
		TitleList.addEventListener("listMovedDown", this, "onTitleListMoveDown");
		TitleList.addEventListener("selectionChange", this, "onTitleListMouseSelectionChange");
		TitleList.disableInput = true; // Bugfix for vanilla
		ObjectiveList.addEventListener("itemPress", this, "onObjectiveListSelect");
		ObjectiveList.addEventListener("selectionChange", this, "onObjectiveListHighlight");
		
	}

	function startPage()
	{
		TitleList.disableInput = false; // Bugfix for vanilla
		
		if (!bUpdated) {
			holdsToggle = false; //hold stuff
			//ShowOnMapButton = _parent._parent._bottomBar.Button2_mc;
			//static function call(methodName, params, scope, callBack)
			GameDelegate.call("RequestQuestsData", [TitleList], this, "onQuestsDataComplete");
			
			//For Quest
			InitHoldTitleList();
			bUpdated = true;
		}
		
		
		_bottomBar.buttonPanel.clearButtons();
		_toggleActiveButton = _bottomBar.buttonPanel.addButton({text: "$Toggle Active", controls: _toggleActiveControls});
		if (bAllowShowOnMap)
			_showOnMapButton = _bottomBar.buttonPanel.addButton({text: "$Show on Map", controls: _showOnMapControls});
		
			
		//For Quest
		//The GFX requires a match on "Toggle Active" Can change it to something like "Local Hold" but no "$" spoils it.
		_toggleActiveButton1 = _bottomBar.buttonPanel.addButton({text: "$Toggle Active", controls: _toggleActiveControls});
		// Other button creation methods
		//_toggleActiveButton1 = new toggleActiveButton;
		//this.addProperty (_toggleActiveButton1);
		//_toggleActiveButton = new _parent._parent._bottomBar.Button1_mc;
			
		//Listeners and click events added for the buttons which don't work.
		_showOnMapButton.addEventListener("click", this, "_ShowOnMapButtonClick");
		_toggleActiveButton.addEventListener("click", this, "_ToggleActiveButtonClick");
		_toggleActiveButton1.addEventListener("click", this, "_ToggleActiveButton1Click");
		//_toggleActiveButton1.addEventListener("click", this, "onAcceptMousePress"); //Tried this but useless
		//End for Quest
		
		
		
		_bottomBar.buttonPanel.updateButtons(true);
		switchFocusToTitles();
		
		
	}

	function endPage()
	{
		_showOnMapButton._alpha = 100;
		_toggleActiveButton._alpha = 100;

		_bottomBar.buttonPanel.clearButtons();

		TitleList.disableInput = true; // Bugfix for vanilla
	}

	function get selectedQuestID(): Number
	{
		return TitleList.entryList.length <= 0 ? undefined : TitleList.centeredEntry.formID;
	}

	function get selectedQuestInstance(): Number
	{
		return TitleList.entryList.length <= 0 ? undefined : TitleList.centeredEntry.instance;
	}

	function handleInput(details: InputDetails, pathToFocus: Array): Boolean
	{
		var bhandledInput: Boolean = false;
		var quest: Object = undefined;
		if (GlobalFunc.IsKeyPressed(details)) {
			if ((details.navEquivalent == NavigationCode.GAMEPAD_X || details.code == 77) && bAllowShowOnMap) 
			{
				
				if (ObjectiveList.selectedEntry != undefined && ObjectiveList.selectedEntry.questTargetID != undefined) {
					quest = ObjectiveList.selectedEntry;
				} else {
					quest = ObjectiveList.entryList[0];
				}
				
				if (quest != undefined && quest.questTargetID != undefined) {
					_parent._parent.CloseMenu();
					GameDelegate.call("ShowTargetOnMap", [quest.questTargetID]);
				} else {
					GameDelegate.call("PlaySound", ["UIMenuCancel"]);
				}
				bhandledInput = true;

				}  else if (details.code == 72 && _platform == PLATFORM_PC && bAllowShowOnMap) {//Local stuff

				////For quest: Hope this works, Note that to call onQuestsDataComplete directly -ahem- requires parms.
				holdsToggle = !holdsToggle;
				GameDelegate.call("RequestQuestsData", [TitleList], this, "onQuestsDataComplete");


				bhandledInput = true;
			}	else if (TitleList.entryList.length > 0) {
				if (details.navEquivalent == NavigationCode.LEFT && FocusHandler.instance.getFocus(0) != TitleList) {
					switchFocusToTitles();
					bhandledInput = true;
				} else if (details.navEquivalent == NavigationCode.RIGHT && FocusHandler.instance.getFocus(0) != 
				eList) {
					switchFocusToObjectives();
					bhandledInput = true;
				}
				
			}
			
			
		}
		//Deleted the following and made no perceivable difference on my rig.
		if (!bhandledInput && pathToFocus != undefined && pathToFocus.length > 0) {
			bhandledInput = pathToFocus[0].handleInput(details, pathToFocus.slice(1));
		}
		return bhandledInput;
	}
	

	private function isViewingMiscObjectives(): Boolean
	{
		return bHasMiscQuests && TitleList.selectedEntry.formID == 0;
	}

	function onTitleListSelect(): Void
	{
		
		if (TitleList.selectedEntry != undefined && !TitleList.selectedEntry.completed) {
			if (!isViewingMiscObjectives()) {
				GameDelegate.call("ToggleQuestActiveStatus", [TitleList.selectedEntry.formID, TitleList.selectedEntry.instance], this, "onToggleQuestActive");
				return;
			}
			TitleList.selectedEntry.active = !TitleList.selectedEntry.active;
			GameDelegate.call("ToggleShowMiscObjectives", [TitleList.selectedEntry.active]);
			TitleList.UpdateList();
		}
	}

	function onObjectiveListSelect(): Void
	{
		if (isViewingMiscObjectives()) {
			GameDelegate.call("ToggleQuestActiveStatus", [ObjectiveList.selectedEntry.formID, ObjectiveList.selectedEntry.instance], this, "onToggleQuestActive");
		}
	}

	private function switchFocusToTitles(): Void
	{
		FocusHandler.instance.setFocus(TitleList, 0);
		Divider.gotoAndStop("Right");
		_toggleActiveButton._alpha = 100;
		ObjectiveList.selectedIndex = -1;
		if (iPlatform != 0) {
			ObjectiveList.disableSelection = true;
		}
		updateShowOnMapButtonAlpha(0);
	}

	private function switchFocusToObjectives(): Void
	{
		FocusHandler.instance.setFocus(ObjectiveList, 0);
		Divider.gotoAndStop("Left");
		_toggleActiveButton._alpha = isViewingMiscObjectives() ? 100 : 50;
		if (iPlatform != 0) {
			ObjectiveList.disableSelection = false;
		}
		ObjectiveList.selectedIndex = 0;
		updateShowOnMapButtonAlpha(0);
	}

	private function onObjectiveListHighlight(event): Void
	{
		updateShowOnMapButtonAlpha(event.index);
	}

	private function updateShowOnMapButtonAlpha(a_entryIdx: Number): Void
	{
		var alpha: Number = 50;

		if (bAllowShowOnMap && (a_entryIdx >= 0 && ObjectiveList.entryList[a_entryIdx].questTargetID != undefined) || (ObjectiveList.entryList.length > 0 && ObjectiveList.entryList[0].questTargetID != undefined)) {
			alpha = 100;
		}
		_toggleActiveButton._alpha = ((!TitleList.selectedEntry.completed) ? 100 : 50);

		_showOnMapButton._alpha = alpha;
	}

	private function onToggleQuestActive(a_bnewActiveStatus: Number): Void
	{
		if (isViewingMiscObjectives()) {
			var iformID: Number = ObjectiveList.selectedEntry.formID;
			var iinstance: Number = ObjectiveList.selectedEntry.instance;
			for (var i: String in ObjectiveList.entryList) {
				if (ObjectiveList.entryList[i].formID == iformID && ObjectiveList.entryList[i].instance == iinstance) {
					ObjectiveList.entryList[i].active = a_bnewActiveStatus;
				}
			}
			ObjectiveList.UpdateList();
		} else {
			TitleList.selectedEntry.active = a_bnewActiveStatus;
			TitleList.UpdateList();
		}
		if (a_bnewActiveStatus) {
			GameDelegate.call("PlaySound", ["UIQuestActive"]);
			return;
		}
		GameDelegate.call("PlaySound", ["UIQuestInactive"]);
	}
	
	private function InitHoldTitleList():Void 
	{
		var questNew: Object;
		var quest: Object;
		var targCoordsX: Number;
		var targCoordsY: Number;
		var questHold: Number;
		var playerHold: Number;
		var k: Number;
		
		k = 0
		//shelfTitleList = TitleList; Needed?
		var playerCoords = Shared.coords.GetplayerPosition;
		var playerCoordsX = playerCoords [0];
		var playerCoordsY = playerCoords [1];

		if (playerCoordsX == null || playerCoordsY == undefined)
{
	
				//For Debug: Currently this condition is always satisfied,- so... broken.
		_parent._parent.CloseMenu();
		GameDelegate.call("ShowTargetOnMap", []);				
} else
{
	//Put better debug coed here, too.
}

		//playerHold initialised here
		playerHold = this.GetHoldCoords (playerCoordsX, playerCoordsY);


		
		
		
		for (var i: Number = 0; i < TitleList.entryList.length; i++) {
			
			
			shelfTitleList.entryList[i] = TitleList.entryList[i]; //"deep copy" list over

			questHold = -1
			quest = null;
			//Build Hold TitleList here Need last OBJECTIVE however

			
			//Can we fill our "selected entry" property in this way. Probably not.
			TitleList.selectedEntry =TitleList.entryList[i];
			GameDelegate.call("RequestObjectivesData", []); //This grabs the "selectedEntry" apparently
			ObjectiveList.entryList = TitleList.selectedEntry.objectives;
				if (ObjectiveList.entryList == null || ObjectiveList.entryList == undefined) {
				
				{ throw new Error("Error: No Objectives");
				}
			
			try {
				
				// output: No Objectives.
				} catch (e_err:Error) {
				trace(e_err.toString());
				}
				
			}
				

			//
			
			for (var j: String in ObjectiveList.entryList) {
				
				questNew = ObjectiveList.entryList[j];
				if (questNew.active == 1)//presumably objectives iterate from first to last in "timeline"?
				{
					quest = questNew;
				} else
				{
					if (quest != null && questHold > -1)//If undefined do nothing -if all undefined add to the completed log
					{
					//quest.targetID._xy works?? 
					var targCoordsX = quest.questTargetID._x;
					var targCoordsy = quest.questTargetID._y;
					
					
					questHold = GetHoldCoords (targCoordsX, targCoordsY); //on success leave- don't care about newer entries
					//questHold = 8;
			
					}

					
				}
				}
			
			if (TitleList.entryList[i].completed)
			{
			holdTitleList.entryList[k] = TitleList.entryList[i];
			k = k + 1;
			
			} else {
				if (questHold == playerHold) //Populate holdTitleList
				{
				holdTitleList.entryList[k] = TitleList.entryList[i];
				k = k + 1;
				}
			}	

		}	
	}

	private function onQuestsDataComplete(auiSavedFormID: Number, auiSavedInstance: Number, abAddMiscQuest: Boolean, abMiscQuestActive: Boolean, abAllowShowOnMap: Boolean): Void
	{
		var titlelistTemp = new MovieClip;
		titlelistTemp = TitleList;
	
		bAllowShowOnMap = abAllowShowOnMap;

		var itimeCompleted: Number = undefined;
		var bCompleted = false;
		var bUncompleted = false;
	//Two problems: Misc not location dependent, and duplicating on screen when 
	//The problem occurs when returning from the save/load or Stats tab.
		if (abAddMiscQuest)	{
			TitleList.entryList.push({text: "$MISCELLANEOUS", formID: 0, instance: 0, active: abMiscQuestActive, completed: false, type: 0});
			bHasMiscQuests = true;
		}		
		
			
			//For Quest: This block may need repositioning in this fucntion
		for (var i: Number = 0; i < TitleList.entryList.length; i++) {			
			
			
			if (TitleList.entryList[i].formID == 0) {
				// Is a misc quest
				TitleList.entryList[i].timeIndex = Number.MAX_VALUE;
			} else {
				TitleList.entryList[i].timeIndex = i;
			}
			if (TitleList.entryList[i].completed) {
				if (itimeCompleted == undefined) {
					itimeCompleted = TitleList.entryList[i].timeIndex - 0.5;
				}
				bCompleted = true;
			} else {
				bUncompleted = true;
			}
		}
		
		if (itimeCompleted != undefined && bCompleted && bUncompleted) {
			// i.e. at least one completed and one uncompleted quest in the list
			TitleList.entryList.push({divider: true, completed: true, timeIndex: itimeCompleted});
		}

		
		
		
		
		
		
			for (var i: Number = 0; i < TitleList.entryList.length; i++) 
				{
					//backup updated TitleList
					titlelistTemp.entryList[i] = TitleList.entryList[i];
				
					//titlelistTemp.entryList[i].active = TitleList.entryList[i].active; //Not Needed
				}

			if (titlelistTemp.entryList[0] == null || titlelistTemp.entryList[0] == undefined) {
				

				
				{ throw new Error("Error: No Quests");
				}
			
			try {
				
				// output: No Quests.
				} catch (e_err:Error) {
				trace(e_err.toString());
				}
				
			}
				
				
		
		//Copy over active status before restoring
		
			for (var i: String in titleListTemp.entryList) 
			
			var currQuest= titlelistTemp.entryList[i];
		{
					if (holdsToggle) {
						
							for (var j: String in holdTitleList.entryList) {
				
								if (currQuest == holdTitleList.entryList[j]); //Save active status
								{
									holdTitleList.entryList[j].active = currQuest.active;
								}
							}
					
					
				} else { 
							for (var j: String in holdTitleList.entryList)
							{
							
							if (currQuest == shelfTitleList[j] && shelfTitleList.entryList[i] != null && shelfTitleList.entryList[i] != undefined)
							//Save active status, extra null condition for startup
							{
								shelfTitleList.entryList[j].active = currQuest.active;
							}
							}
						}


				}
		
		
		for (var i: Number = 0; i < TitleList.entryList.length; i++) 
		{
				if (holdsToggle) {
					TitleList.entryList[i] = holdTitleList.entryList[i]; //Restore with Hold List
				} else {
					if (shelfTitleList.entryList[i] != null && shelfTitleList.entryList[i] != undefined) {
					TitleList.entryList[i] = shelfTitleList.entryList[i];
					} //Restore original
				}
		}
				//End for Quest
		
		
		
		
		
		
		
		
		TitleList.entryList.sort(completedQuestSort);
		
		var isavedIndex: Number = 0;

		for (var i: Number = 0; i < TitleList.entryList.length; i++) {
			if (TitleList.entryList[i].text != undefined) {
				TitleList.entryList[i].text = TitleList.entryList[i].text.toUpperCase();
			}
			if (TitleList.entryList[i].formID == auiSavedFormID && TitleList.entryList[i].instance == auiSavedInstance) {
				isavedIndex = i;
			}
		}


		
		
		TitleList.InvalidateData();
		TitleList.RestoreScrollPosition(isavedIndex, true);
		TitleList.UpdateList();
		onQuestHighlight();
	}

		private function _ToggleActiveButtonClick(): Void //Click events added
	{
		holdsToggle = false;
		GameDelegate.call("RequestQuestsData", [TitleList], this, "onQuestsDataComplete");
	}
		private function _ToggleActiveButton1Click(): Void
	{
		holdsToggle = true;
		GameDelegate.call("RequestQuestsData", [TitleList], this, "onQuestsDataComplete");
	}
		private function _ShowOnMapButtonClick(): Void
	{
		var quest: Object = undefined;
					if (ObjectiveList.selectedEntry != undefined && ObjectiveList.selectedEntry.questTargetID != undefined) {
					quest = ObjectiveList.selectedEntry;
				} else {
					quest = ObjectiveList.entryList[0];
				}
				
				if (quest != undefined && quest.questTargetID != undefined) {
					_parent._parent.CloseMenu();
					GameDelegate.call("ShowTargetOnMap", [quest.questTargetID]);
				} else {
					GameDelegate.call("PlaySound", ["UIMenuCancel"]);
				}
	}
	
	function completedQuestSort(aObj1: Object, aObj2: Object): Number
	{
		if (!aObj1.completed && aObj2.completed) 
		{
			return -1;
		}
		if (aObj1.completed && !aObj2.completed) 
		{
			return 1;
		}
		if (aObj1.timeIndex < aObj2.timeIndex) 
		{
			return -1;
		}
		if (aObj1.timeIndex > aObj2.timeIndex) 
		{
			return 1;
		}
		return 0;
	}

	function onQuestHighlight(): Void
	{
		if (TitleList.entryList.length > 0) {
			var aCategories: Array = ["Misc", "Main", "MagesGuild", "ThievesGuild", "DarkBrotherhood", "Companion", "Favor", "Daedric", "Misc", "CivilWar", "DLC01", "DLC02"];
			QuestTitleText.SetText(TitleList.selectedEntry.text);
			if (TitleList.selectedEntry.objectives == undefined) {
				GameDelegate.call("RequestObjectivesData", []);
			}
			ObjectiveList.entryList = TitleList.selectedEntry.objectives;
			SetDescriptionText();
			questTitleEndpieces.gotoAndStop(aCategories[TitleList.selectedEntry.type]);
			questTitleEndpieces._visible = true;
			ObjectivesHeader._visible = !isViewingMiscObjectives();
			ObjectiveList.selectedIndex = -1;
			ObjectiveList.scrollPosition = 0;
			if (iPlatform != 0) {
				ObjectiveList.disableSelection = true;
			}

			_showOnMapButton._visible = true;
			updateShowOnMapButtonAlpha(0);
		} else {
			NoQuestsText.SetText("No Active Quests");
			DescriptionText.SetText(" ");
			QuestTitleText.SetText(" ");
			ObjectiveList.ClearList();
			questTitleEndpieces._visible = false;
			ObjectivesHeader._visible = false;

			_showOnMapButton._visible = false;
		}
		ObjectiveList.InvalidateData();
	}

	function SetDescriptionText(): Void
	{
		var iHeaderyOffset: Number = 25;
		var iObjectiveyOffset: Number = 10;
		var iObjectiveBorderMaxy: Number = 470;
		var iObjectiveBorderMiny: Number = 40;
		DescriptionText.SetText(TitleList.selectedEntry.description);
		var oCharBoundaries: Object = DescriptionText.getCharBoundaries(DescriptionText.getLineOffset(DescriptionText.numLines - 1));
		ObjectivesHeader._y = DescriptionText._y + oCharBoundaries.bottom + iHeaderyOffset;
		if (isViewingMiscObjectives()) {
			ObjectiveList._y = DescriptionText._y;
		} else {
			ObjectiveList._y = ObjectivesHeader._y + ObjectivesHeader._height + iObjectiveyOffset;
		}
		ObjectiveList.border._height = Math.max(iObjectiveBorderMaxy - ObjectiveList._y, iObjectiveBorderMiny);
		ObjectiveList.scrollbar.height = ObjectiveList.border._height - 20;
	}

	function onTitleListMoveUp(event: Object): Void
	{
		onQuestHighlight();
		GameDelegate.call("PlaySound", ["UIMenuFocus"]);
		if (event.scrollChanged == true) {
			TitleList._parent.gotoAndPlay("moveUp");
		}
	}

	function onTitleListMoveDown(event: Object): Void
	{
		onQuestHighlight();
		GameDelegate.call("PlaySound", ["UIMenuFocus"]);
		if (event.scrollChanged == true) {
			TitleList._parent.gotoAndPlay("moveDown");
		}
	}

	function onTitleListMouseSelectionChange(event: Object): Void
	{
		if (event.keyboardOrMouse == 0 && event.index != -1) {
			onQuestHighlight();
			GameDelegate.call("PlaySound", ["UIMenuFocus"]);
		}
	}

	function onRightStickInput(afX: Number, afY: Number): Void
	{
		if (afY < 0) {
			ObjectiveList.moveSelectionDown();
			return;
		}
		ObjectiveList.moveSelectionUp();
	}

	function SetPlatform(a_platform: Number, a_bPS3Switch: Boolean): Void
	{
		
	//static var PLATFORM_PC: Number = 0; from buttonchange
	//static var PLATFORM_PC_GAMEPAD: Number = 1;
	//static var PLATFORM_360: Number = 2;
	//static var PLATFORM_PS3: Number = 3;
		
		if (a_platform == 0) { //but these are Linux codes???
			_toggleActiveControls = {keyCode: 28}; // Enter
			_showOnMapControls = {keyCode: 50}; // M
			_deleteControls = {keyCode: 45}; // X
		} else {
			_toggleActiveControls = {keyCode: 276}; // 360_A
			_showOnMapControls = {keyCode: 278}; // 360_X
			_deleteControls = {keyCode: 278}; // 360_X
		}

		iPlatform = a_platform;
		TitleList.SetPlatform(a_platform, a_bPS3Switch);
		ObjectiveList.SetPlatform(a_platform, a_bPS3Switch);
	}

	private function GetHoldCoords(coordsX: Number, coordsY: Number): Number /* New implementation: This function returns the hold value*/
	{


			
		if (holdInput[1] == null || holdInput[1] == undefined) //Populate holdData just once
		{

			var holdTemp = new Array();
			var holdNum = new Array();
			//Define the holdmap here. All currently set on Hjaalmarch. This is only half the map size. Taleden to supply CSV cell map with partial fill.
			holdInput[0] =  [565452504846444240383634323028262422201816141210080604020004060810121416182022242628303234384042444648];
			holdInput[1] =  [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//48
			holdInput[2] =  [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//46
			holdInput[3] =  [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//44
			holdInput[4] =  [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//42
			holdInput[5] =  [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//40
			holdInput[6] =  [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//38
			holdInput[7] =  [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//36
			holdInput[8] =  [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//34
			holdInput[9] =  [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//32
			holdInput[10] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//30
			holdInput[11] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//28
			holdInput[12] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//26
			holdInput[13] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//24
			holdInput[14] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//22
			holdInput[15] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//20
			holdInput[16] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//18
			holdInput[17] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//16
			holdInput[18] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//14
			holdInput[19] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//12
			holdInput[20] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//10
			holdInput[21] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//08
			holdInput[22] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//06
			holdInput[23] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//04
			holdInput[24] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//02
			holdInput[25] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//00
			holdInput[26] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//02
			holdInput[27] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//04
			holdInput[28] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//06
			holdInput[29] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//08
			holdInput[30] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//10
			holdInput[31] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//12
			holdInput[32] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//14
			holdInput[33] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//16
			holdInput[34] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//18
			holdInput[35] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//20
			holdInput[36] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//22
			holdInput[37] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//24
			holdInput[38] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//26
			holdInput[39] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//28
			holdInput[40] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//30
			holdInput[41] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//34
			holdInput[42] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//36
			holdInput[43] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//38
			holdInput[44] = [3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3];//40
			
/*			//Preferred method is below
			// a Line Feed \x0A or Carriage Return \x0D
			var holdData:LoadVars = new LoadVars();
			holdData.load("Holds.txt"); //& used as a variable separator in Holds.txt
			holdData.onLoad = function (success: Boolean)
			{ 
			if (success)
				{ 
			//"this.L..." is better than holdData.L...
			//don't worry about 0th element strip carriage returns
			holdInput[1] = (holdData.L01).split(String.fromCharCode(13));
			holdInput[2] = (holdData.L02).split(String.fromCharCode(13));
			holdInput[3] = (holdData.L03).split(String.fromCharCode(13));
			holdInput[4] = (holdData.L04).split(String.fromCharCode(13));
			holdInput[5] = (holdData.L05).split(String.fromCharCode(13));
			holdInput[6] = (holdData.L06).split(String.fromCharCode(13));
			holdInput[7] = (holdData.L07).split(String.fromCharCode(13));
			holdInput[8] = (holdData.L08).split(String.fromCharCode(13));
			holdInput[9] = (holdData.L09).split(String.fromCharCode(13));
			holdInput[10] = (holdData.L10).split(String.fromCharCode(13));
			holdInput[11] = (holdData.L11).split(String.fromCharCode(13));
			holdInput[12] = (holdData.L12).split(String.fromCharCode(13));
			holdInput[13] = (holdData.L13).split(String.fromCharCode(13));
			holdInput[14] = (holdData.L14).split(String.fromCharCode(13));
			holdInput[15] = (holdData.L15).split(String.fromCharCode(13));
			holdInput[16] = (holdData.L16).split(String.fromCharCode(13));
			holdInput[17] = (holdData.L17).split(String.fromCharCode(13));
			holdInput[18] = (holdData.L18).split(String.fromCharCode(13));
			holdInput[19] = (holdData.L19).split(String.fromCharCode(13));
			holdInput[20] = (holdData.L20).split(String.fromCharCode(13));
			holdInput[21] = (holdData.L21).split(String.fromCharCode(13));
			holdInput[22] = (holdData.L22).split(String.fromCharCode(13));
			holdInput[23] = (holdData.L23).split(String.fromCharCode(13));
			holdInput[24] = (holdData.L24).split(String.fromCharCode(13));
			holdInput[25] = (holdData.L25).split(String.fromCharCode(13));
			holdInput[26] = (holdData.L26).split(String.fromCharCode(13));
			holdInput[27] = (holdData.L27).split(String.fromCharCode(13));
			holdInput[28] = (holdData.L28).split(String.fromCharCode(13));
			holdInput[29] = (holdData.L29).split(String.fromCharCode(13));
			holdInput[30] = (holdData.L30).split(String.fromCharCode(13));
			holdInput[31] = (holdData.L31).split(String.fromCharCode(13));
			holdInput[32] = (holdData.L32).split(String.fromCharCode(13));
			holdInput[33] = (holdData.L33).split(String.fromCharCode(13));
			holdInput[34] = (holdData.L34).split(String.fromCharCode(13));
			holdInput[35] = (holdData.L35).split(String.fromCharCode(13));
			holdInput[36] = (holdData.L36).split(String.fromCharCode(13));
			holdInput[37] = (holdData.L37).split(String.fromCharCode(13));
			holdInput[38] = (holdData.L38).split(String.fromCharCode(13));
			holdInput[39] = (holdData.L39).split(String.fromCharCode(13));
			holdInput[40] = (holdData.L40).split(String.fromCharCode(13));
			holdInput[41] = (holdData.L41).split(String.fromCharCode(13));
			holdInput[42] = (holdData.L42).split(String.fromCharCode(13));
			holdInput[43] = (holdData.L43).split(String.fromCharCode(13));
			holdInput[44] = (holdData.L44).split(String.fromCharCode(13));
			  }	else {
					//DEBUG TEST
  					_parent._parent.CloseMenu();
					GameDelegate.call("ShowTargetOnMap", []);	
					throw new Error("Error: Can't find Holds.txt");
			
			try {
				
				// output: Strings do not match.
				} catch (e_err:Error)
				{
				trace(e_err.toString());
				}
			
				  
			  }
			
				
		}
*/
		
		}




			

		for (i = 1; i < 45; i++)
			{
				
				if (i == coordsX) {
	

				holdTemp = holdInput[i];
				if (holdTemp != null && holdTemp != undefined) {
				
					//holdTemp = holdTemp.split(",");
					holdNum.length = 0;
					
					for (var j:Number = 0; i < holdTemp.length; j++)
					{
					   // cast each array element as a number and push into new array 	
					   holdNum.push(Number(holdTemp[j]));
					}
					
					
					
					for (j=1; j<53; j++) {
					
					if (coordsY == j) {
					return holdNum[j]; //mission accomplished
					}
					}
				}
				
				
				} else
				
				{
								  
				throw new Error("Error: Invalid data in Holds.txt");
			
					try {
						
						// output: Strings do not match.
						} 
					catch (e_err:Error)
						{
						trace(e_err.toString());

						}	
				}

			}

		
			

	return 0 //0 is for Wilderness cells
		
	

				}
	
}
