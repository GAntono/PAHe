Scriptname PAHPersonalityDefinition extends Quest  

PAHCore Property PAH Auto

Faction Property dialogue_faction Auto
VoiceType[] Property supported_voice_types Auto

Float Property anger_rating_min = 20.0 Auto
Float Property anger_rating_max = 70.0 Auto

Float Property fear_rating_min = 20.0 Auto
Float Property fear_rating_max = 90.0 Auto


Bool Function SupportsVoiceType(VoiceType the_voice_type)
	int i = 0
	while (i < supported_voice_types.length)
		if supported_voice_types[i] == the_voice_type
			return true
		endif		
		i += 1
	endwhile
	return false
EndFunction

Bool Function ActorIsThisPersonality(Actor the_actor)
	return the_actor.IsInFaction(dialogue_faction)
EndFunction

Event OnInit()
	Utility.Wait(4.0)
	PAH.RegisterPersonalityDefinition(self)
EndEvent

; Float base_chance_attack_player = 0.5
; Float base_chance_run_away = 0.5
; Float run_away_submission_cap = 60.0
; Float leash_influence_on_running_away = 0.1
