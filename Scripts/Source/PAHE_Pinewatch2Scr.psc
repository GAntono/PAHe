Scriptname PAHE_Pinewatch2Scr extends ObjectReference  

Actor Property _actor Auto

Event OnLoad()
		Utility.wait(0.1)
		_actor.removeAllItems()
		debug.sendAnimationEvent(_actor, "IdleWounded_02")
		_actor.SetDontMove()
EndEvent