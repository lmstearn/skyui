import Components.Meter;
import skyui.Translator;

class BottomBar extends MovieClip
{
	var _buttons:Array;

	var _lastItemType:Number;
	var _leftOffset:Number;

	var HealthMeter:Meter;
	var LevelMeter:Meter;
	var MagickaMeter:Meter;
	var StaminaMeter:Meter;

	var PlayerInfoCard_mc:MovieClip;
	var PlayerInfoObj:Object;
	
	static var DEBUG_LEVEL = 1;

	function BottomBar()
	{
		super();
		_lastItemType = InventoryDefines.ICT_NONE;
		HealthMeter = new Meter(PlayerInfoCard_mc.HealthRect.MeterInstance.Meter_mc);
		MagickaMeter = new Meter(PlayerInfoCard_mc.MagickaRect.MeterInstance.Meter_mc);
		StaminaMeter = new Meter(PlayerInfoCard_mc.StaminaRect.MeterInstance.Meter_mc);
		LevelMeter = new Meter(PlayerInfoCard_mc.LevelMeterInstance.Meter_mc);
		_buttons = new Array();
		for (var i = 0; this["Button" + i] != undefined; i++) {
			_buttons.push(this["Button" + i]);
		}
	}

	function PositionElements(a_leftOffset:Number, a_rightOffset:Number)
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("BottomBar PositionElements()");
		}
		_leftOffset = a_leftOffset;
		PositionButtons();
		PlayerInfoCard_mc._x = a_rightOffset - PlayerInfoCard_mc._width;
	}

	function ShowPlayerInfo()
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("BottomBar ShowPlayerInfo()");
		}
		PlayerInfoCard_mc._alpha = 100;
	}

	function HidePlayerInfo()
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("BottomBar HidePlayerInfo()");
		}
		PlayerInfoCard_mc._alpha = 0;
	}

	function UpdatePerItemInfo(a_itemUpdateObj)
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("BottomBar UpdatePerItemInfo()");
		}
		var _itemType:Number = a_itemUpdateObj.type;
		var _bHasWeightandValue = true;
		if (_itemType == undefined) {
			_itemType = _lastItemType;
			if (a_itemUpdateObj == undefined) {
				a_itemUpdateObj = {type:_lastItemType};
			}
		} else {
			_lastItemType = _itemType;
		}
		if (PlayerInfoObj != undefined && a_itemUpdateObj != undefined) {
			switch (_itemType) {

				case InventoryDefines.ICT_ARMOR :
					PlayerInfoCard_mc.gotoAndStop("Armor");
					var strArmor:String = Math.floor(PlayerInfoObj.armor).toString();
					if (a_itemUpdateObj.armorChange != undefined) {
						var _armorDelta = Math.round(a_itemUpdateObj.armorChange);
						if (_armorDelta > 0) {
							strArmor = strArmor + " <font color=\'#189515\'>(+" + _armorDelta.toString() + ")</font>";
						} else if (_armorDelta < 0) {
							strArmor = strArmor + " <font color=\'#FF0000\'>(" + _armorDelta.toString() + ")</font>";
						}
					}
					PlayerInfoCard_mc.ArmorRatingValue.textAutoSize = "shrink";
					PlayerInfoCard_mc.ArmorRatingValue.html = true;
					PlayerInfoCard_mc.ArmorRatingValue.SetText(strArmor,true);
					break;

				case InventoryDefines.ICT_WEAPON :
					PlayerInfoCard_mc.gotoAndStop("Weapon");
					var strDamage:String = Math.floor(PlayerInfoObj.damage).toString();
					if (a_itemUpdateObj.damageChange != undefined) {
						var _damageDelta = Math.round(a_itemUpdateObj.damageChange);
						if (_damageDelta > 0) {
							strDamage = strDamage + " <font color=\'#189515\'>(+" + _damageDelta.toString() + ")</font>";
						} else if (_damageDelta < 0) {
							strDamage = strDamage + " <font color=\'#FF0000\'>(" + _damageDelta.toString() + ")</font>";
						}
					}
					PlayerInfoCard_mc.DamageValue.textAutoSize = "shrink";
					PlayerInfoCard_mc.DamageValue.html = true;
					PlayerInfoCard_mc.DamageValue.SetText(strDamage,true);
					break;

				case InventoryDefines.ICT_POTION :
					var EF_HEALTH:Number = 0;
					var EF_MAGICKA:Number = 1;
					var EF_STAMINA:Number = 2;
					if (a_itemUpdateObj.potionType == EF_MAGICKA) {
						PlayerInfoCard_mc.gotoAndStop("MagickaPotion");
					} else if (a_itemUpdateObj.potionType == EF_STAMINA) {
						PlayerInfoCard_mc.gotoAndStop("StaminaPotion");
					} else if (a_itemUpdateObj.potionType == EF_HEALTH) {
						PlayerInfoCard_mc.gotoAndStop("HealthPotion");
					}
					break;

				case InventoryDefines.ICT_FOOD :
					var EF_HEALTH:Number = 0;
					var EF_MAGICKA:Number = 1;
					var EF_STAMINA:Number = 2;
					if (a_itemUpdateObj.potionType == EF_MAGICKA) {
						PlayerInfoCard_mc.gotoAndStop("MagickaPotion");
					} else if (a_itemUpdateObj.potionType == EF_STAMINA) {
						PlayerInfoCard_mc.gotoAndStop("StaminaPotion");
					} else if (a_itemUpdateObj.potionType == EF_HEALTH) {
						PlayerInfoCard_mc.gotoAndStop("HealthPotion");
					}
					break;

				case InventoryDefines.ICT_BOOK :
				case InventoryDefines.ICT_INGREDIENT :
				case InventoryDefines.ICT_MISC :
				case InventoryDefines.ICT_KEY :
					PlayerInfoCard_mc.gotoAndStop("Default");
					break;

				case InventoryDefines.ICT_SPELL_DEFAULT :
				case InventoryDefines.ICT_ACTIVE_EFFECT :
					PlayerInfoCard_mc.gotoAndStop("Magic");
					_bHasWeightandValue = false;
					break;

				case InventoryDefines.ICT_SPELL :
					PlayerInfoCard_mc.gotoAndStop("MagicSkill");
					if (a_itemUpdateObj.magicSchoolName != undefined) {
						UpdateSkillBar(a_itemUpdateObj.magicSchoolName,a_itemUpdateObj.magicSchoolLevel,a_itemUpdateObj.magicSchoolPct);
					}
					_bHasWeightandValue = false;
					break;

				case InventoryDefines.ICT_SHOUT :
					PlayerInfoCard_mc.gotoAndStop("Shout");
					PlayerInfoCard_mc.DragonSoulTextInstance.SetText(PlayerInfoObj.dragonSoulText);
					_bHasWeightandValue = false;
					break;

				default :
					PlayerInfoCard_mc.gotoAndStop("Default");
			}
		}

		if (_bHasWeightandValue) {
			PlayerInfoCard_mc.CarryWeightValue.textAutoSize = "shrink";
			PlayerInfoCard_mc.CarryWeightValue.SetText(Math.ceil(PlayerInfoObj.encumbrance) + "/" + Math.floor(PlayerInfoObj.maxEncumbrance));
			PlayerInfoCard_mc.PlayerGoldValue.SetText(PlayerInfoObj.gold.toString());
			PlayerInfoCard_mc.PlayerGoldLabel._x = PlayerInfoCard_mc.PlayerGoldValue._x + PlayerInfoCard_mc.PlayerGoldValue.getLineMetrics(0).x - PlayerInfoCard_mc.PlayerGoldLabel._width;
			PlayerInfoCard_mc.CarryWeightValue._x = PlayerInfoCard_mc.PlayerGoldLabel._x + PlayerInfoCard_mc.PlayerGoldLabel.getLineMetrics(0).x - PlayerInfoCard_mc.CarryWeightValue._width - 5;
			PlayerInfoCard_mc.CarryWeightLabel._x = PlayerInfoCard_mc.CarryWeightValue._x + PlayerInfoCard_mc.CarryWeightValue.getLineMetrics(0).x - PlayerInfoCard_mc.CarryWeightLabel._width;
			if (_itemType === InventoryDefines.ICT_ARMOR) {
				PlayerInfoCard_mc.ArmorRatingValue._x = PlayerInfoCard_mc.CarryWeightLabel._x + PlayerInfoCard_mc.CarryWeightLabel.getLineMetrics(0).x - PlayerInfoCard_mc.ArmorRatingValue._width - 5;
				PlayerInfoCard_mc.ArmorRatingLabel._x = PlayerInfoCard_mc.ArmorRatingValue._x + PlayerInfoCard_mc.ArmorRatingValue.getLineMetrics(0).x - PlayerInfoCard_mc.ArmorRatingLabel._width;
			} else if (_itemType === InventoryDefines.ICT_WEAPON) {
				PlayerInfoCard_mc.DamageValue._x = PlayerInfoCard_mc.CarryWeightLabel._x + PlayerInfoCard_mc.CarryWeightLabel.getLineMetrics(0).x - PlayerInfoCard_mc.DamageValue._width - 5;
				PlayerInfoCard_mc.DamageLabel._x = PlayerInfoCard_mc.DamageValue._x + PlayerInfoCard_mc.DamageValue.getLineMetrics(0).x - PlayerInfoCard_mc.DamageLabel._width;
			}
		}
		UpdateStatMeter(PlayerInfoCard_mc.HealthRect,HealthMeter,PlayerInfoObj.health,PlayerInfoObj.maxHealth,PlayerInfoObj.healthColor);
		UpdateStatMeter(PlayerInfoCard_mc.MagickaRect,MagickaMeter,PlayerInfoObj.magicka,PlayerInfoObj.maxMagicka,PlayerInfoObj.magickaColor);
		UpdateStatMeter(PlayerInfoCard_mc.StaminaRect,StaminaMeter,PlayerInfoObj.stamina,PlayerInfoObj.maxStamina,PlayerInfoObj.staminaColor);
	}

	function UpdatePlayerInfo(a_playerUpdateObj, a_itemUpdateObj)
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("BottomBar UpdatePlayerInfo()");
		}
		PlayerInfoObj = a_playerUpdateObj;
		UpdatePerItemInfo(a_itemUpdateObj);
	}

	function UpdateSkillBar(a_skillName:String, a_levelStart:Number, a_levelPercent:Number)
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("BottomBar UpdateSkillBar()");
		}
		PlayerInfoCard_mc.SkillLevelLabel.SetText(a_skillName);
		PlayerInfoCard_mc.SkillLevelCurrent.SetText(a_levelStart);
		PlayerInfoCard_mc.SkillLevelNext.SetText(a_levelStart + 1);
		PlayerInfoCard_mc.LevelMeterInstance.gotoAndStop("Pause");
		LevelMeter.SetPercent(a_levelPercent);
	}

	function UpdateCraftingInfo(a_skillName:String, a_levelStart:Number, a_levelPercent:Number)
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("BottomBar UpdateCraftingInfo()");
		}
		PlayerInfoCard_mc.gotoAndStop("Crafting");
		UpdateSkillBar(a_skillName,a_levelStart,a_levelPercent);
	}

	function UpdateStatMeter(a_meterRect:MovieClip, a_meterObj:Meter, a_currValue:Number, a_maxValue:Number, a_color:String)
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("BottomBar UpdateStatMeter()");
		}
		if (a_color == undefined) {
			a_color = "#FFFFFF";
		}
		if (a_meterRect._alpha > 0) {
			if (a_meterRect.MeterText != undefined) {
				a_meterRect.MeterText.textAutoSize = "shrink";
				a_meterRect.MeterText.html = true;
				a_meterRect.MeterText.SetText("<font color=\'" + a_color + "\'>" + Math.floor(a_currValue) + "/" + Math.floor(a_maxValue) + "</font>",true);
			}
			a_meterRect.MeterInstance.gotoAndStop("Pause");
			a_meterObj.SetPercent(a_currValue / a_maxValue * 100);
		}
	}

	function SetBarterInfo(a_playerGold:Number, a_vendorGold:Number, a_goldDelta:Number, a_vendorName:String)
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("BottomBar SetBarterInfo()");
		}
		if (PlayerInfoCard_mc._currentframe == 1) {
			PlayerInfoCard_mc.gotoAndStop("Barter");
		}
		PlayerInfoCard_mc.PlayerGoldValue.textAutoSize = "shrink";
		PlayerInfoCard_mc.VendorGoldValue.textAutoSize = "shrink";
		if (a_goldDelta == undefined) {
			PlayerInfoCard_mc.PlayerGoldValue.SetText(a_playerGold.toString(),true);
		} else if (a_goldDelta >= 0) {
			PlayerInfoCard_mc.PlayerGoldValue.SetText(a_playerGold.toString() + " <font color=\'#189515\'>(+" + a_goldDelta.toString() + ")</font>",true);
		} else {
			PlayerInfoCard_mc.PlayerGoldValue.SetText(a_playerGold.toString() + " <font color=\'#FF0000\'>(" + a_goldDelta.toString() + ")</font>",true);
		}
		PlayerInfoCard_mc.VendorGoldValue.SetText(a_vendorGold.toString());
		if (a_vendorName != undefined) {
			PlayerInfoCard_mc.VendorGoldLabel.SetText("$Gold");
			PlayerInfoCard_mc.VendorGoldLabel.SetText(a_vendorName + " " + PlayerInfoCard_mc.VendorGoldLabel.text);
		}
		PlayerInfoCard_mc.VendorGoldLabel._x = PlayerInfoCard_mc.VendorGoldValue._x + PlayerInfoCard_mc.VendorGoldValue.getLineMetrics(0).x - PlayerInfoCard_mc.VendorGoldLabel._width - 5;
		PlayerInfoCard_mc.PlayerGoldValue._x = PlayerInfoCard_mc.VendorGoldLabel._x + PlayerInfoCard_mc.VendorGoldLabel.getLineMetrics(0).x - PlayerInfoCard_mc.PlayerGoldValue._width - 20;
		PlayerInfoCard_mc.PlayerGoldLabel._x = PlayerInfoCard_mc.PlayerGoldValue._x + PlayerInfoCard_mc.PlayerGoldValue.getLineMetrics(0).x - PlayerInfoCard_mc.PlayerGoldLabel._width - 5;
	}

	function SetBarterPerItemInfo(a_itemUpdateObj, a_playerInfoObj)
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("BottomBar SetBarterPerItemInfo()");
		}
		switch (a_itemUpdateObj.type) {

			case InventoryDefines.ICT_ARMOR :
				PlayerInfoCard_mc.gotoAndStop("Barter_Armor");
				var strArmor:String = Math.floor(a_playerInfoObj.armor).toString();
				if (a_itemUpdateObj.armorChange != undefined) {
					var _armorDelta:Number = Math.round(a_itemUpdateObj.armorChange);
					if (_armorDelta > 0) {
						strArmor = strArmor + " <font color=\'#189515\'>(+" + _armorDelta.toString() + ")</font>";
					} else if (_armorDelta < 0) {
						strArmor = strArmor + " <font color=\'#FF0000\'>(" + _armorDelta.toString() + ")</font>";
					}
				}
				PlayerInfoCard_mc.ArmorRatingValue.textAutoSize = "shrink";
				PlayerInfoCard_mc.ArmorRatingValue.html = true;
				PlayerInfoCard_mc.ArmorRatingValue.SetText(strArmor,true);
				break;

			case InventoryDefines.ICT_WEAPON :
				PlayerInfoCard_mc.gotoAndStop("Barter_Weapon");
				var strDamage:String = Math.floor(a_playerInfoObj.damage).toString();
				if (a_itemUpdateObj.damageChange != undefined) {
					var _damageDelta:Number = Math.round(a_itemUpdateObj.damageChange);
					if (_damageDelta > 0) {
						strDamage = strDamage + " <font color=\'#189515\'>(+" + _damageDelta.toString() + ")</font>";
					} else if (_damageDelta < 0) {
						strDamage = strDamage + " <font color=\'#FF0000\'>(" + _damageDelta.toString() + ")</font>";
					}
				}
				PlayerInfoCard_mc.DamageValue.textAutoSize = "shrink";
				PlayerInfoCard_mc.DamageValue.html = true;
				PlayerInfoCard_mc.DamageValue.SetText(strDamage,true);
				break;

			default :
				PlayerInfoCard_mc.gotoAndStop("Barter");
		}
	}

	function SetGiftInfo(aiFavorPoints:Number)
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("BottomBar SetGiftInfo()");
		}
		PlayerInfoCard_mc.gotoAndStop("Gift");
	}

	function SetPlatform(a_platform:Number, a_PS3Switch:Boolean)
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("BottomBar SetPlatform()");
		}
		for (var i = 0; i < _buttons.length; i++) {
			_buttons[i].SetPlatform(a_platform,a_PS3Switch);
		}
	}

	function ShowButtons()
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("BottomBar ShowButtons()");
		}
		for (var i = 0; i < _buttons.length; i++) {
			_buttons[i]._visible = _buttons[i].label.length > 0;
		}
	}

	function HideButtons()
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("BottomBar HideButtons()");
		}
		for (var i = 0; i < _buttons.length; i++) {
			_buttons[i]._visible = false;
		}
	}

	function SetButtonsText()
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("BottomBar SetButtonsText()");
		}
		for (var i = 0; i < _buttons.length; i++) {
			_buttons[i].label = arguments[i];
			_buttons[i]._visible = _buttons[i].label.length > 0;
		}
		PositionButtons();
	}

	function SetButtonText(aText:String, aIndex:Number)
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("BottomBar SetButtonText()");
		}
		if (aIndex < _buttons.length) {
			_buttons[aIndex].label = aText;
			_buttons[aIndex]._visible = aText.length > 0;
			PositionButtons();
		}
	}

	function SetButtonsArt(a_buttonArt)
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("BottomBar SetButtonsArt()");
		}
		for (var i = 0; i < a_buttonArt.length; i++) {
			SetButtonArt(a_buttonArt[i],i);
		}
	}

	function AttachDualButton(a_buttonArtObj, a_index:Number)
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("BottomBar AttachDualButton()");
		}
		if (a_index < _buttons.length) {
			_buttons[a_index].AttachDualButton(a_buttonArtObj);
		}
	}

	function GetButtonsArt():Array
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("BottomBar GetButtonsArt()");
		}
		var _buttonsArt = new Array(_buttons.length);
		for (var i = 0; i < _buttonsArt.length; i++) {
			_buttonsArt[i] = _buttons[i].GetArt();
		}
		return _buttonsArt;
	}

	function GetButtonArt(a_index:Number)
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("BottomBar GetButtonArt()");
		}
		if (a_index < _buttons.length) {
			return _buttons[a_index].GetArt();
		}
		return undefined;
	}

	function SetButtonArt(a_platformArt, a_index:Number)
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("BottomBar SetButtonArt()");
		}
		if (a_index < _buttons.length) {
			var a_button = _buttons[a_index];
			a_button.PCArt = a_platformArt.PCArt;
			a_button.XBoxArt = a_platformArt.XBoxArt;
			a_button.PS3Art = a_platformArt.PS3Art;
			a_button.RefreshArt();
		}
	}

	function PositionButtons()
	{
		if (DEBUG_LEVEL > 0) {
			_global.skse.Log("BottomBar PositionButtons()");
		}
		var RightOffset:Number = 10;
		var LeftOffset:Number = _leftOffset;
		for (var i = 0; i < _buttons.length; i++) {
			if (_buttons[i].label.length > 0) {
				_buttons[i]._x = LeftOffset + _buttons[i].ButtonArt._width;
				if (_buttons[i].ButtonArt2 != undefined) {
					_buttons[i]._x = _buttons[i]._x + _buttons[i].ButtonArt2._width;
				}
				LeftOffset = _buttons[i]._x + _buttons[i].textField.getLineMetrics(0).width + RightOffset;
			}
		}
	}

}