Scriptname PAHECaptureSpellEff Extends ActiveMagicEffect

PAHCore Property PAH Auto

Event OnEffectStart(Actor Target, Actor Caster)		
	If !Target.HasKeyWordString("SexLabActive") && Target.HasKeyWordString("ActorTypeNPC") && !PAH.IsFollower(Target)
		PAH.MarkTarget(Target)
	Endif
EndEvent