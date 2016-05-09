Scriptname PAHLeashEffectScript extends activemagiceffect  

Float Property update_timer = 0.5 Auto
Float Property refire_timer = 3.0 Auto
Float property launch_z_lift = 0.0 Auto
Float Property launch_force = 300.0 Auto
Float Property leash_distance = 300.0 Auto

PAHCore Property PAH Auto
Sound Property leash_link_sound Auto

PAHActorAlias slave_actor_alias
Actor slave_actor_ref

Static Property XMarkerHeading Auto
Explosion Property LeashFieldExplosion Auto
Spell Property PAHSelfStaggerSpell Auto
Spell Property PAHLeashLinkSpell Auto

ObjectReference explosion_ref
ObjectReference explosion_marker
ObjectReference link_cast_source


Event OnEffectStart(Actor akTarget, Actor akCaster)
	if akTarget == Game.GetPlayer()
		return
	endif
	slave_actor_alias = PAH.GetSlaveAlias(akTarget) as PAHActorAlias

	if slave_actor_alias != None
		slave_actor_ref = slave_actor_alias.GetActorRef()
		PlayLinkFX()
		RegisterForSingleUpdate(update_timer)
	endif
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
	UnRegisterForUpdate()
	if explosion_ref != None
		explosion_ref.Delete()
	endif
	if explosion_marker != None
		explosion_marker.Delete()
	endif
	if link_cast_source != None
		link_cast_source.Delete()
	endif
EndEvent

Event OnUpdate()
	if slave_actor_alias.leash_point != None
		if slave_actor_ref.GetDistance(slave_actor_alias.leash_point) > leash_distance
			HandleSlaveOutOfRange()
		else
			if Utility.RandomFloat() < 0.4
				; PlayLinkFX()
			endif
			RegisterForSingleUpdate(update_timer)
		endif
	endif
EndEvent

Function HandleSlaveOutOfRange()
	PlayLinkFX()
	PlayLeashFieldFX()

	float zOffset = slave_actor_ref.GetHeadingAngle(slave_actor_alias.leash_point)
	if !(zOffset < 90 && zOffset > -90)
		RepelByStagger()
	else
		RepelByLaunch()
	endif
	slave_actor_alias.OnLeashEffect()
	RegisterForSingleUpdate(refire_timer)
EndFunction

Function PlayLeashFieldFX()
	if explosion_ref != None
		explosion_ref.Disable()
		explosion_ref.Delete()
	endif

	if explosion_marker == None
		explosion_marker = slave_actor_ref.PlaceAtMe(XMarkerHeading)
	endif

	explosion_marker.MoveTo(slave_actor_ref)
	float zOffset = explosion_marker.GetHeadingAngle(slave_actor_alias.leash_point)
	explosion_marker.SetAngle(0, 0, explosion_marker.GetAngleZ() + zOffset)
	explosion_ref = explosion_marker.PlaceAtMe(LeashFieldExplosion)
EndFunction

Function RepelByStagger()
	PAHSelfStaggerSpell.Cast(slave_actor_ref)
EndFunction

Function RepelByLaunch()
	Float delta_x = slave_actor_ref.GetPositionX() - slave_actor_alias.leash_point.GetPositionX()
	Float delta_y = slave_actor_ref.GetPositionY() - slave_actor_alias.leash_point.GetPositionY()

	;# Normalise to max delta of 1
	Float divider
	Float pos_delta_x = delta_x
	Float pos_delta_y = delta_y
	if pos_delta_x < 0
		pos_delta_x = 0 - pos_delta_x
	endif
	if pos_delta_y < 0
		pos_delta_y = 0 - pos_delta_y
	endif
	if pos_delta_x > pos_delta_y
		divider = pos_delta_x
	else
		divider = pos_delta_y
	endif
	delta_x = delta_x/divider
	delta_y = delta_y/divider

	delta_x = 0 - delta_x
	delta_y = 0 - delta_y

	slave_actor_ref.PushActorAway(slave_actor_ref, 0)
	Utility.Wait(0.05)
	slave_actor_ref.ApplyHavokImpulse(delta_x, delta_y, launch_z_lift, launch_force)
EndFunction

Function PlayLinkFX(Bool with_pull_fx = false)
	; if link_cast_source != None
	; 	link_cast_source.Delete()
	; endif
	; link_cast_source = slave_actor_ref.PlaceAtMe(XMarkerHeading)
	; link_cast_source.SetPosition(link_cast_source.GetPositionX(), link_cast_source.GetPositionY(), link_cast_source.GetPositionZ() + 110)

	PAHLeashLinkSpell.Cast(slave_actor_alias.leash_point, slave_actor_ref)
EndFunction
