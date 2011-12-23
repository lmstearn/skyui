dynamic class QuantitySlider extends gfx.controls.Slider
{
static var DEBUG_LEVEL:Number = 1;
	var dispatchEvent;

	function QuantitySlider()
	{
		super();
if (DEBUG_LEVEL > 0) skse.Log("QuantitySlider QuantitySlider()");
	}

	function handleInput(details, pathToFocus)
	{
if (DEBUG_LEVEL > 0) skse.Log("QuantitySlider handleInput()");
		var __reg4 = super.handleInput(details, pathToFocus);
		if (!__reg4) 
		{
			if (Shared.GlobalFunc.IsKeyPressed(details)) 
			{
				if (details.navEquivalent == gfx.ui.NavigationCode.PAGE_DOWN || details.navEquivalent == gfx.ui.NavigationCode.GAMEPAD_L1) 
				{
					this.value = Math.floor(this.value - this.maximum / 4);
					this.dispatchEvent({type: "change"});
					__reg4 = true;
				}
				else if (details.navEquivalent == gfx.ui.NavigationCode.PAGE_UP || details.navEquivalent == gfx.ui.NavigationCode.GAMEPAD_R1) 
				{
					this.value = Math.ceil(this.value + this.maximum / 4);
					this.dispatchEvent({type: "change"});
					__reg4 = true;
				}
			}
		}
		return __reg4;
	}

}
