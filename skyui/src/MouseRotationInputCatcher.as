class MouseRotationInputCatcher extends MovieClip
{
	static var PROCESS_ROTATION_DELAY = 150;
	
	private var _processRotationDelayTimerID;
	
	static var DEBUG_LEVEL = 1;
	
	function MouseRotationInputCatcher()
	{
		super();
	}
	
	function onMouseDown()
	{
		var pressed = Mouse.getTopMostEntity() == this;
		
		if (pressed || _parent.bFadedIn == false)
		{
			_parent.onMouseRotationStart();
		}
		
		if (pressed && _processRotationDelayTimerID == undefined)
		{
			_processRotationDelayTimerID = setInterval(this, "onProcessDelayElapsed", PROCESS_ROTATION_DELAY);
		}
	}
	
	function onProcessDelayElapsed()
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("MouseRotationInputCatcher onProcessDelayElapsed()");
		clearInterval(_processRotationDelayTimerID);
		_processRotationDelayTimerID = undefined;
	}
	
	function onMouseUp()
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("MouseRotationInputCatcher onMouseUp()");
		_parent.onMouseRotationStop();
		clearInterval(_processRotationDelayTimerID);
		
		if (_processRotationDelayTimerID != undefined && _parent.bFadedIn != false)
		{
			_parent.onMouseRotationFastClick(0);
		}
		_processRotationDelayTimerID = undefined;
	}
	
	function onPressAux()
	{
		if (DEBUG_LEVEL > 0)
			_global.skse.Log("MouseRotationInputCatcher onPressAux()");
		_parent.onMouseRotationFastClick(1);
	}
}
