Scriptname PAHE_PinewatchScr extends ObjectReference  

Event OnLoad()
	If _actor.isInFaction(PAHECanBeCaptured)
		_actor.MoveTo(self)
		_actor.setDontMove(true)
		_actor.AllowPCDialogue(false)
		Debug.sendAnimationEvent(_actor, anim)
	Else
		disable()
	EndIf
EndEvent

Actor Property _actor Auto
String Property anim Auto
Faction Property PAHECanBeCaptured Auto