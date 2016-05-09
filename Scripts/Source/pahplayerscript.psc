Scriptname PAHPlayerScript extends ReferenceAlias  

PAHCore Property PAH Auto

bool __whistleWait
bool Property WhistleWait
	bool Function get()
		return __whistleWait
	EndFunction
	Function set(bool value)
		__whistleWait = value
	EndFunction
EndProperty

Event OnPlayerLoadGame()
	Utility.wait(0.1)
	PAH.OnPlayerLoadGame()
EndEvent

Event OnLocationChange(Location akOldLoc, Location akNewLoc)
	PAH.HandleLocationChange()
EndEvent