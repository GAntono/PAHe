Scriptname PAHRebootScript extends activemagiceffect  

PAHBootstrapScript Property bootstrap_quest Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
	bootstrap_quest.Boot()
EndEvent