class skyui.Util
{
	static function extract(a_str:String, a_startChar:String, a_endChar:String):String
	{
		return a_str.slice(a_str.indexOf(a_startChar) + 1, a_str.lastIndexOf(a_endChar));
	}

	// Remove comments and leading/trailing white space
	static function clean(a_str:String):String
	{
		if (a_str.indexOf(";") > 0) {
			a_str = a_str.slice(0, a_str.indexOf(";"));
		}

		var i = 0;
		while (a_str.charAt(i) == " " || a_str.charAt(i) == "\t")
		{
			i++;
		}

		var j = a_str.length - 1;
		while (a_str.charAt(j) == " " || a_str.charAt(j) == "\t")
		{
			j--;
		}

		return a_str.slice(i, j + 1);
	}

	static function addArrayFunctions()
	{
		Array.prototype.indexOf = function(a_element):Number 
		{
			for (var i = 0; i < this.length; i++) {
				if (this[i] == a_element) {
					return i;
				}
			}
			return undefined;
		};
		
		
		Array.prototype.equals = function (a:Array):Boolean 
		{
			if (a == undefined) {
				return false;
			}
			
	    	if (this.length != a.length) {
	        	return false;
	    	}
			
	    	for (var i = 0; i < a.length; i++) {
	        	if (a[i] !== this[i]) {
					return false;
				}
        	}
	    	return true;
    	};
	}

	// Maps Unicode inputted character code to it's CP819/CP1251 character code
	static function mapUnicodeChar(a_charCode:Number):Number
	{
		//NUMERO SIGN
		if (a_charCode == 0x2116) {
			return 0xB9;

		} else if (0x0401 <= a_charCode && a_charCode <= 0x0491) {
			switch (a_charCode) {
					//CYRILLIC CAPITAL LETTER IO
				case 0x0401 :
					return 0xA8;
					//CYRILLIC CAPITAL LETTER UKRAINIAN IE
				case 0x0404 :
					return 0xAA;
					//CYRILLIC CAPITAL LETTER DZE
				case 0x0405 :
					return 0xBD;
					//CYRILLIC CAPITAL LETTER BYELORUSSIAN-UKRAINIAN I
				case 0x0406 :
					return 0xB2;
					//CYRILLIC CAPITAL LETTER YI
				case 0x0407 :
					return 0xAF;
					//CYRILLIC CAPITAL LETTER JE
				case 0x0408 :
					return 0xA3;
					//CYRILLIC CAPITAL LETTER SHORT U
				case 0x040E :
					return 0xA1;
					//CYRILLIC SMALL LETTER IO
				case 0x0451 :
					return 0xB8;
					//CYRILLIC SMALL LETTER UKRAINIAN IE
				case 0x0454 :
					return 0xBA;
					//CYRILLIC SMALL LETTER DZE
				case 0x0455 :
					return 0xBE;
					//CYRILLIC SMALL LETTER BYELORUSSIAN-UKRAINIAN I
				case 0x0456 :
					return 0xB3;
					//CYRILLIC SMALL LETTER YI
				case 0x0457 :
					return 0xBF;
					//CYRILLIC SMALL LETTER JE
				case 0x0458 :
					return 0xBC;
					//CYRILLIC SMALL LETTER SHORT U
				case 0x045E :
					return 0xA2;
					//CYRILLIC CAPITAL LETTER GHE WITH UPTURN
				case 0x0490 :
					return 0xA5;
					//CYRILLIC SMALL LETTER GHE WITH UPTURN
				case 0x0491 :
					return 0xA4;
					//Standard Cyrillic characters
				default :
					if (0x040F <= a_charCode && a_charCode <= 0x044F) {
						return a_charCode - 0x0350;
					}
			}
		}
		return a_charCode;
	}

	static function keyCodeString(a_keyCode:Number, a_platform:Number):String
	{
		switch (a_keyCode) {
			case 8 :
				return "Backspace";
			case 9 :
				if (a_platform == 1) {
					return "360_B";
				}
				return "Tab";
			case 13 :
				if (a_platform == 1) {
					return "360_A";
				}
				return "Enter";
			case 16 :
				return "Shift";
			case 17 :
				return "Control";
			case 18 :
				return "Alt";
			case 19 :
				return "Pause";
			case 20 :
				return "CapsLock";
			case 27 :
				return "Esc";
			case 32 :
				return "Space";
			case 33 :
				return "PgUp";
			case 34 :
				return "PgDn";
			case 35 :
				return "End";
			case 36 :
				return "Home";
			case 37 :
				return "Left";
			case 38 :
				return "Up";
			case 39 :
				return "Right";
			case 40 :
				return "Down";
			case 45 :
				return "Insert";
			case 46 :
				return "Delete";
			case 48 :
				return "0";
			case 49 :
				return "1";
			case 50 :
				return "2";
			case 51 :
				return "3";
			case 52 :
				return "4";
			case 53 :
				return "5";
			case 54 :
				return "6";
			case 55 :
				return "7";
			case 56 :
				return "8";
			case 57 :
				return "9";
			case 65 :
				return "A";
			case 66 :
				return "B";
			case 67 :
				return "C";
			case 68 :
				return "D";
			case 69 :
				return "E";
			case 70 :
				return "F";
			case 71 :
				return "G";
			case 72 :
				return "H";
			case 73 :
				return "I";
			case 74 :
				return "J";
			case 75 :
				return "K";
			case 76 :
				return "L";
			case 77 :
				return "M";
			case 78 :
				return "N";
			case 79 :
				return "O";
			case 80 :
				return "P";
			case 81 :
				return "Q";
			case 82 :
				return "R";
			case 83 :
				return "S";
			case 84 :
				return "T";
			case 85 :
				return "U";
			case 86 :
				return "V";
			case 87 :
				return "W";
			case 88 :
				return "X";
			case 89 :
				return "Y";
			case 90 :
				return "Z";
			case 96 :
				return "Numpad0";
			case 97 :
				return "Numpad1";
			case 98 :
				if (a_platform == 1) {
					return "360_X";
				}
				return "Numpad2";
			case 99 :
				if (a_platform == 1) {
					return "360_Y";
				}
				return "Numpad3";
			case 100 :
				if (a_platform == 1) {
					return "360_LB";
				}
				return "Numpad4";
			case 101 :
				if (a_platform == 1) {
					return "360_L3";
				}
				return "Numpad5";
			case 102 :
				if (a_platform == 1) {
					return "360_LS";
				}
				return "Numpad6";
			case 103 :
				if (a_platform == 1) {
					return "360_RB";
				}
				return "Numpad7";
			case 104 :
				if (a_platform == 1) {
					return "360_R3";
				}
				return "Numpad8";
			case 105 :
				if (a_platform == 1) {
					return "360_RS";
				}
				return "Numpad9";
			case 106 :
				if (a_platform == 1) {
					return "360_START";
				}
				return "NumpadMult";
			case 107 :
				if (a_platform == 1) {
					return "360_BACK";
				}
				return "NumpadPlus";
			case 109 :
				return "NumpadMinus";
			case 110 :
				return "NumpadDec";
			case 111 :
				return "NumpadDivide";
			case 112 :
				return "F1";
			case 113 :
				return "F2";
			case 114 :
				return "F3";
			case 115 :
				return "F4";
			case 116 :
				return "F5";
			case 117 :
				return "F6";
			case 118 :
				return "F7";
			case 119 :
				return "F8";
			case 120 :
				return "F9";
			case 122 :
				return "F11";
			case 123 :
				return "F12";
			case 124 :
				return "F13";
			case 125 :
				return "F14";
			case 126 :
				return "F15";
			case 145 :
				return "ScrollLock";
			case 186 :
				return "Semicolon";
			case 187 :
				return "Equal";
			case 188 :
				return "Comma";
			case 189 :
				return "Hyphen";
			case 190 :
				return "Period";
			case 191 :
				return "Slash";
			case 192 :
				return "Tilde";
			case 219 :
				return "BracketLeft";
			case 220 :
				return "Backslash";
			case 222 :
				return "QuoteSingle";
			default :
				return "UnknownKey";
		}
	}
}