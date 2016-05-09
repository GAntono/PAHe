Scriptname PAHModSlaveStatsScript extends activemagiceffect  

PAHCore Property PAH Auto

Float Property submission_mod_ammount = 0.0 Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
	PAHSlave slave = PAH.GetSlave(akTarget)
	slave.submission += submission_mod_ammount
EndEvent