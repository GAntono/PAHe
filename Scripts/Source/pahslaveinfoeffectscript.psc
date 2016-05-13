Scriptname PAHSlaveInfoEffectScript extends activemagiceffect  

PAHCore Property PAH Auto

Message Property PAHSlaveInfoMessage Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
	PAHSlave slave = PAH.GetSlave(akTarget)
	PAHSlaveInfoMessage.Show(\
		slave.submission, \
		slave.combat_training, \
		slave.anger_training, \
		slave.respect_training, \
		slave.pose_training, \
		slave.sex_training, \
		slave.fear_training \
	)
EndEvent
