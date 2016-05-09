Scriptname PAHLeashPointScript extends ObjectReference  

PAHCore Property PAH Auto

Event OnLoad()
	RegisterForSingleUpdate(0.5)
EndEvent

Event OnUpdate()
	if PAH.clearing_leash_point || !PAH.LeashPointInUse(self)
		Remove()
	endif
EndEvent

Function ClearAndRemove()
	PAH.ClearLeashPoint(self)
	Remove()
EndFunction

Function Remove()
	Disable()
	Utility.Wait(4.0)
	Delete()
EndFunction