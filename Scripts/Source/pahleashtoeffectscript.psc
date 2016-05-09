Scriptname PAHLeashToEffectScript extends activemagiceffect  

PAHCore Property PAH Auto

PAHActorAlias slave_actor_alias
Form Property PAHLeashPoint Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
	slave_actor_alias = PAH.GetSlaveAlias(akTarget) as PAHActorAlias
	if slave_actor_alias == None
		return
	endif

	if slave_actor_alias.leash_point != None
		PAH.clearing_leash_point = true
	endif

	RegisterForSingleUpdate(0.2)
EndEvent

Event OnUpdate()
	if PAH.clearing_leash_point
		ClearCurrentLeashPoint()
	else
		SetNewLeashPoint()
	endif
EndEvent

Function ClearCurrentLeashPoint()
	PAHLeashPointScript current_leash_point = slave_actor_alias.leash_point as PAHLeashPointScript
	if current_leash_point != None
		current_leash_point.ClearAndRemove()
	endif
	slave_actor_alias.leash_point = None
EndFunction

Function SetNewLeashPoint()	
	ObjectReference leash_point = Game.FindClosestReferenceOfTypeFromRef(PAHLeashPoint as Form, slave_actor_alias.GetRef(), 300)
	slave_actor_alias.leash_point = leash_point
EndFunction