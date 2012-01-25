import Shared.GlobalFunc;

class Components.Meter
{
	var CurrentPercent:Number;
	var Empty:Number;
	var EmptySpeed:Number;
	var FillSpeed:Number;
	var Full:Number;
	var TargetPercent:Number;
	var meterMovieClip:MovieClip;

	function Meter(aMovieClip:MovieClip)
	{
		Empty = 0;
		Full = 0;
		CurrentPercent = 100;
		TargetPercent = 100;
		FillSpeed = 2;
		EmptySpeed = 3;
		meterMovieClip = aMovieClip;
		meterMovieClip.gotoAndStop("Empty");
		Empty = meterMovieClip._currentframe;
		meterMovieClip.gotoAndStop("Full");
		Full = meterMovieClip._currentframe;
	}

	function SetPercent(a_percent:Number)
	{
		CurrentPercent = Math.min(100, Math.max(a_percent, 0));
		TargetPercent = CurrentPercent;
		var _meterFrame:Number = Math.floor(GlobalFunc.Lerp(Empty, Full, 0, 100, CurrentPercent));
		meterMovieClip.gotoAndStop(_meterFrame);
	}

	function SetTargetPercent(a_percent:Number)
	{
		TargetPercent = Math.min(100, Math.max(a_percent, 0));
	}

	function SetFillSpeed(a_speed:Number)
	{
		FillSpeed = a_speed;
	}

	function SetEmptySpeed(a_speed:Number)
	{
		EmptySpeed = a_speed;
	}

	function Update()
	{
		if (TargetPercent > 0 && TargetPercent > CurrentPercent) {
			if (TargetPercent - CurrentPercent > FillSpeed) {
				CurrentPercent = CurrentPercent + FillSpeed;
				var _meterFrame:Number = GlobalFunc.Lerp(Empty, Full, 0, 100, CurrentPercent);
				meterMovieClip.gotoAndStop(_meterFrame);
			} else {
				SetPercent(TargetPercent);
			}
			return;
		}
		if (TargetPercent <= CurrentPercent) {
			var _bUnknown = CurrentPercent - TargetPercent > EmptySpeed;
			if ((TargetPercent > 0 && _bUnknown) || CurrentPercent > EmptySpeed) {
				if (_bUnknown) {
					CurrentPercent = CurrentPercent - EmptySpeed;
				} else {
					CurrentPercent = TargetPercent;
				}
				var _meterFrame:Number = GlobalFunc.Lerp(Empty, Full, 0, 100, CurrentPercent);
				meterMovieClip.gotoAndStop(_meterFrame);
				return;
			}
			if (CurrentPercent >= 0) {
				SetPercent(TargetPercent);
			}
		}
	}

}