Scriptname PAHCaptureEffectScript extends activemagiceffect  

PAHCore Property PAH Auto
Faction Property PAHCleaned Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
	if PAH.GetSlave(akTarget) != None
		return
	endif

	if !akTarget.IsInFaction(PAHCleaned)
		PAH.clonifier.StartCloning(akTarget)
	endif

;	if akTarget.GetActorValuePercentage("Health") <= 0.25
		DoCapture(akTarget)
;	endif		
EndEvent

Function DoCapture(Actor captive)
	if !captive.IsInFaction(PAHCleaned)
		if PAH.clonifier.GetClone(captive) == None
			;# clonifier not ready - return
			return
		else
			captive = PAH.clonifier.SwitchClone(captive)
			if captive.GetBaseAv("Stamina") > captive.GetBaseAv("Magicka")
				captive.DamageAv("Stamina", 10000)
			else
				captive.DamageAv("Magicka", 10000)
			endif	
			captive.DamageAv("Health", captive.GetBaseAv("Health") * 0.75)
		endif
	endif

	PAH.AddSlave(captive)
EndFunction