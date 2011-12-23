class Shared.ButtonChange extends gfx.events.EventDispatcher
{
	static var PLATFORM_PC:Number = 0;
	static var PLATFORM_PC_GAMEPAD:Number = 1;
	static var PLATFORM_360:Number = 2;
	static var PLATFORM_PS3:Number = 3;
	
	var iCurrPlatform:Number = PLATFORM_360;
	
	static var DEBUG_LEVEL = 1;
	
	function ButtonChange()
	{
		super();
		initialize(this);
	}
	
	function get Platform()
	{
		return iCurrPlatform;
	}
	function IsGamepadConnected()
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("ButtonChange IsGamepadConnected()");
		return (iCurrPlatform == PLATFORM_PC_GAMEPAD || iCurrPlatform == PLATFORM_360 || iCurrPlatform == PLATFORM_PS3);
	}
	
	function SetPlatform(aSetPlatform, aSetSwapPS3)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("ButtonChange SetPlatform()");
		iCurrPlatform = aSetPlatform;
		dispatchEvent({target: this, type: "platformChange", aPlatform: aSetPlatform, aSwapPS3: aSetSwapPS3});
	}
	
	function SetPS3Swap(aSwap)
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("ButtonChange SetPS3Swap()");
		dispatchEvent({target: this, type: "SwapPS3Button", Boolean: aSwap});
	}
}
