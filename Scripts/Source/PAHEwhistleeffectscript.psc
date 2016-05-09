Scriptname PAHEWhistleEffectScript extends ActiveMagicEffect

PAHCore Property PAH Auto
PAHPlayerScript Property player_alias Auto
Sound Property PAHEWhistleShortSM Auto
Sound Property PAHEWhistleMediumSM Auto

Sound whistle
String event_suffix

Event OnEffectStart(Actor akTarget, Actor akCaster)
	If akCaster != Game.GetPlayer()
		dispel()
		return
	ElseIf akTarget == Game.GetPlayer()
		If player_alias.WhistleWait
			whistle = PAHEWhistleMediumSM
			event_suffix = "follow"
		Else
			whistle = PAHEWhistleShortSM
			event_suffix = "wait"
		EndIf
		Whistle.PlayAndWait(akCaster)
		akCaster.SendModEvent("PAHEWhistle_" + event_suffix)
		player_alias.WhistleWait = !player_alias.WhistleWait
		return
	EndIf
	dispel()
EndEvent
