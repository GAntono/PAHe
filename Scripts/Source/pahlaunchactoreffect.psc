Scriptname PAHLaunchActorEffect extends activemagiceffect  

Float property z_lift = 0.45 Auto
Float Property force = 800.0 Auto
Bool Property throw_towards_caster = false Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
	Float delta_x = akTarget.GetPositionX() - akCaster.GetPositionX()
	Float delta_y = akTarget.GetPositionY() - akCaster.GetPositionY()

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

	if throw_towards_caster
		delta_x = 0 - delta_x
		delta_y = 0 - delta_y
	endif

	akTarget.PushActorAway(akTarget, 0)
	Utility.Wait(0.05)
	akTarget.ApplyHavokImpulse(delta_x, delta_y, z_lift, force)
EndEvent


