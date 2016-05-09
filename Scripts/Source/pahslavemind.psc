Scriptname PAHSlaveMind extends ReferenceAlias
Import Utility

; ### Constants ###
PAHCore Property PAH Auto

Faction Property PAHPersonalityGenerated Auto

Float spontaneous_anger_submission_cap = 70.0
Float base_chance_attack_player = 0.5
Float base_chance_run_away = 0.5

Faction Property PAHMoodNeutral Auto
Faction Property PAHMoodAngry Auto
Faction Property PAHMoodAfraid Auto
Faction Property PAHMoodJustCaptured Auto
Faction Property PAHPosing Auto

Faction Property PAHTraitAngerRating Auto
Faction Property PAHTraitFearRating Auto

Event OnInit()
	if !PAH
		PAH = Game.GetFormFromFile(0x0001FAEF, "paradise_halls.esm") as PAHCore
	endIf
EndEvent

; ### Properties ###
PAHSlave __slave
PAHSlave Property slave
	PAHSlave Function get()
		if __slave == None
			__slave = (self as ReferenceAlias) as PAHSlave
		endif
		return __slave
	EndFunction
EndProperty

PAHPersonalityDefinition Property personality_definition Auto

; ### Setup and teardown ###
Event OnBootstrap(string eventName = "", string strArg = "", float numArg = 0.0, Form sender = None)
	UnregisterForModEvent("PAHBootstrap")
	if GetActorRef() != None
		RecoverPersonality()
	endif
EndEvent

Event AfterAssign()
	__slave = (self as ReferenceAlias) as PAHSlave
	if GetActorRef().IsInFaction(PAHPersonalityGenerated)
		RecoverPersonality()
	else
		GeneratePersonality()
	endif
EndEvent

Event BeforeClear()
	personality_definition = None
	__slave = None
EndEvent

Function GeneratePersonality()
	int i = 0
	;# Get a personality definition which matches voice type
	while (i < PAH.personality_definitions.length)
		if PAH.personality_definitions[i] != None && PAH.personality_definitions[i].SupportsVoiceType(slave.actor_alias.GetVoiceType())
			personality_definition = PAH.personality_definitions[i]
			i = PAH.personality_definitions.length
		endif
		i += 1
	endwhile

	;# Otherwise assign a default one
	if personality_definition == None
		if GetActorRef().GetLeveledActorBase().GetSex() == 0
			personality_definition = PAH.default_male_personality_definition
		else
			personality_definition = PAH.default_female_personality_definition
		endif
	endif

	GetActorRef().AddToFaction(PAHPersonalityGenerated)
	GetActorRef().AddToFaction(personality_definition.dialogue_faction)

	anger_rating = RandomFloat(personality_definition.anger_rating_min, personality_definition.anger_rating_max)
	fear_rating = RandomFloat(personality_definition.fear_rating_min, personality_definition.fear_rating_max)

	if slave.submission == 0
		mood = "just_captured"
	else
		mood = "neutral"
	endif
EndFunction

Function RecoverPersonality()
	int i = 0
	while (i < PAH.personality_definitions.length)
		if PAH.personality_definitions[i] != None && PAH.personality_definitions[i].ActorIsThisPersonality(GetActorRef())
			personality_definition = PAH.personality_definitions[i]
			return
		endif
		i += 1
	endwhile

	anger_rating = GetActorRef().GetFactionRank(PAHTraitAngerRating)
	fear_rating = GetActorRef().GetFactionRank(PAHTraitFearRating)

	if  GetActorRef().IsInFaction(PAHMoodJustCaptured)
		mood = "just_captured"
	elseIf GetActorRef().IsInFaction(PAHMoodAngry)
		mood = "angry"
	elseIf GetActorRef().IsInFaction(PAHMoodAfraid)
		mood = "afraid"
	else
		mood = "neutral"
	endIf
EndFunction

; ### Personality Traits ###
Float __anger_rating
Float Property anger_rating
	Float Function get()
		return __anger_rating
	EndFunction
	Function set(Float value)
		__anger_rating = value
		slave.actor_alias.SetFactionRank(PAHTraitAngerRating, __anger_rating as Int)
	EndFunction
EndProperty

Float __fear_rating
Float Property fear_rating
	Float Function get()
		return __fear_rating
	EndFunction
	Function set(Float value)
		__fear_rating = value
		slave.actor_alias.SetFactionRank(PAHTraitFearRating, __fear_rating as Int)
	EndFunction
EndProperty

; ### Events ###
Event OnUpdate()
	OnMoodUpdate()
EndEvent

Event OnUpdateGameTime()
	If slave.actor_alias
	;	SetRespectfulOnDeepTick()
		If slave.should_be_respectful
			slave.respectful = RandomFloat() < ChanceRespectful()
		EndIf
	;	SetFightsForPlayerOnDeepTick()
		If slave.should_fight_for_player
			slave.fights_for_player = RandomFloat() < ChanceFightForPlayer()
		EndIf
		OnMoodUpdateGameTime()
	EndIf
EndEvent

Event OnExperiencePain()
EndEvent

Event OnStartPunishment(String type, string reason)
EndEvent

Event OnEndPunishment(String type, Float severity, string reason = "")
EndEvent

Event OnToldOff(string reason)
EndEvent

Event OnLeashEffect()
EndEvent

Event OnLeashed()
EndEvent

Event OnUnLeashed()
EndEvent

; ### Mood Handler ###
String __mood = ""
String Property mood
	String Function get()
		return __mood
	EndFunction
	Function set(String value)
		if __mood != value && slave.actor_alias.CanChangeMood()
			__mood = value
			if __mood == ""
				__mood = "neutral"
			endif
			EndMood()
			GoToState(__mood)
			StartMood()
		endif
	EndFunction
EndProperty

Function StartMood()
EndFunction

Function EndMood()
EndFunction

Function OnMoodUpdate()
EndFunction

Function OnMoodUpdateGameTime()
EndFunction

; ### Mood definitions ###
State neutral
	Function StartMood()
		slave.actor_alias.AddToFaction(PAHMoodNeutral)
	EndFunction

	Function EndMood()
		slave.actor_alias.RemoveFromFaction(PAHMoodNeutral)
	EndFunction

	Function OnMoodUpdateGameTime()
		RunAwayByFormula()
		SetAngryByFormulaSpontaneous()
	EndFunction

	Event OnExperiencePain()
		If (slave.actor_alias.CanChangeMood())
			if RandomFloat() < (ChanceAfraid() * 0.5)
				mood = "afraid"
			elseif RandomFloat() < (ChanceAngry() * 0.25)
				mood = "angry"
			endif
		EndIf
	EndEvent
EndState

State angry
	Function StartMood()
		slave.actor_alias.AddToFaction(PAHMoodAngry)
	EndFunction

	Function EndMood()
		slave.actor_alias.RemoveFromFaction(PAHMoodAngry)
	EndFunction

	Function OnMoodUpdateGameTime()
		RecoverFromAngryByFormula()
		RunAwayByFormula()
	EndFunction

	Function OnMoodUpdate()
		if !slave.actor_alias.is_moving && RandomFloat() < 0.05
			If (slave.actor_alias.CanIdle())
				if RandomFloat() < 0.1 && !slave.actor_alias.PlayerIsFacing()
					slave.actor_alias.MakeAggressiveGesture()
				else
					slave.actor_alias.CrossArms()
				endif
			EndIf
		endif
	EndFunction

	Event OnExperiencePain()
		If (slave.actor_alias.CanChangeMood())
			if RandomFloat() < (ChanceAfraid() * 0.5)
				mood = "afraid"
			endif
		EndIf
	EndEvent
EndState

State afraid
	Function StartMood()
		slave.actor_alias.AddToFaction(PAHMoodAfraid)
	EndFunction

	Function EndMood()
		slave.actor_alias.RemoveFromFaction(PAHMoodAfraid)
	EndFunction

	Function OnMoodUpdateGameTime()
		RunAwayByFormula()
		RecoverFromAfraidByFormulaSpontaneous()
	EndFunction

	Function OnMoodUpdate()
		if !slave.actor_alias.is_moving && RandomFloat() < 0.05
			If (slave.actor_alias.CanIdle())
				if RandomFloat() < 0.5
					slave.actor_alias.LookAroundNervously()
				else
					slave.actor_alias.WipeBrow()
				endif
			EndIf
		endif
	EndFunction

	Event OnExperiencePain()
		If (slave.actor_alias.CanChangeStates())
			If (slave.actor_alias.current_action != "cower" && RandomFloat() < 0.5)
				slave.actor_alias.IdleCower()
			EndIf
		EndIf
	EndEvent
EndState

State just_captured
	Function StartMood()
		slave.actor_alias.AddToFaction(PAHMoodJustCaptured)
		slave.actor_alias.AddToFaction(PAHMoodAfraid)
		slave.FleeAndCower()
	EndFunction

	Function EndMood()
		slave.actor_alias.RemoveFromFaction(PAHMoodJustCaptured)
		slave.actor_alias.RemoveFromFaction(PAHMoodAfraid)
	EndFunction
EndState

;### Mood update game time functions ###
Bool Function RunAwayByFormula()
	If (slave.actor_alias.CanChangeStates())
		Float chance = base_chance_run_away * 0.5
		chance = chance * SubmissionChanceMultiplier(0, PAH.Config.runAwayValue, inverted = true)
		chance = chance * RecentlyPunishedChanceMultiplier(inverted = true)

		if RandomFloat() < chance
			slave.RunAway()
			return true
		endif
	EndIf
	return false
EndFunction

Bool Function StartMovingByFormula()
	Float chance = 0.5 + (slave.fear_training / 200)
	chance = chance * SubmissionChanceMultiplier(inverted = true)
	chance = chance * RecentlyPunishedChanceMultiplier(inverted = true)

	If RandomFloat() < chance
		return true
	EndIf
	return false
EndFunction

Bool Function CanBreakRestraint(Form cuffs)
	Float baseValue = (PAH.Config.runAwayValue as float)  / 100
	Float rpcm = RecentlyPunishedChanceMultiplier(inverted = true)
	Float chance = baseValue * (rpcm + RandomFloat() - 0.5)

	float restraintModifier
	If cuffs == PAH.CuffsIron || cuffs == PAH.CuffsIronBrown
		restraintModifier = baseValue * 1.5
	ElseIf cuffs == PAH.CuffsSimpleBlack || cuffs == PAH.CuffsSimpleBrown
		restraintModifier = baseValue * 1.4
	ElseIf cuffs == PAH.CuffsLeather
		restraintModifier = baseValue * 1.2
	ElseIf cuffs == PAH.CuffsRope
		restraintModifier = baseValue * 1
	Else
		restraintModifier = baseValue
	EndIf
						Debug.trace("[PAHE SlaveMind] CanBreakRestraints 367 " + GetActorRef().GetDisplayName() + ": base = " + baseValue + " / multiplier = " + (rpcm + 0.5) + " / chance = " + chance + " / restraint = " + restraintModifier)
;						Debug.trace("[PAHE SlaveMind] CanBreakRestraints 367 " + GetActorRef().GetDisplayName() + " chance = " + chance + " / restraintModifier = " + restraintModifier)
	If chance > restraintModifier
						Debug.trace("[PAHE SlaveMind] CanBreakRestraints 368 " + GetActorRef().GetDisplayName() + ": CanBreakRestraints true")
		return true
	EndIf
						Debug.trace("[PAHE SlaveMind] CanBreakRestraints 370 " + GetActorRef().GetDisplayName() + ": CanBreakRestraints false")
	return false
EndFunction

Bool Function StopPoseByFormula()
	If (slave.actor_alias.CanChangeStates())
		Float chance = 0.5 + (slave.pose_training / 200)
		chance = chance * SubmissionChanceMultiplier(inverted = true)
		chance = chance * RecentlyPunishedChanceMultiplier(inverted = true)

		If RandomFloat() < chance
			slave.actor_alias.RemoveFromFaction(PAHPosing)
			return true
		EndIf
	EndIf
	return false
EndFunction

Bool Function SetAngryByFormulaSpontaneous()
	If (slave.actor_alias.CanChangeMood())
		Float chance = ChanceAngry() * SubmissionChanceMultiplier(0, spontaneous_anger_submission_cap, inverted = true)
		if RandomFloat() < chance
			mood = "angry"
			return true
		endif
	EndIf
	return false
EndFunction

Bool Function RecoverFromAfraidByFormulaSpontaneous()
	If (slave.actor_alias.CanChangeMood())
		if RandomFloat() < ChanceRecoverFromAfraid()
			mood = "neutral"
			return true
		endif
	EndIf
	return false
EndFunction

Bool Function RecoverFromAngryByFormula()
	If (slave.actor_alias.CanChangeMood())
		if slave.punishment_active && RandomFloat() < (1 - (anger_rating / 200))
			mood = "neutral"
			return true
		endif
	EndIf
	return false
EndFunction

Bool Function SetRespectfulOnDeepTick()
	slave.respectful = RandomFloat() < ChanceRespectful()
EndFunction

Bool Function SetFightsForPlayerOnDeepTick()
	slave.fights_for_player = RandomFloat() < ChanceFightForPlayer()
EndFunction

;### Chance functions ###
Float Function SubmissionChanceMultiplier(Float submission_min = 0.0, Float submission_max = 100.0, Bool inverted = false)
	Float chance_multiplier = (slave.submission - submission_min) / (submission_max - submission_min)
	if chance_multiplier > 1.0
		chance_multiplier = 1.0
	elseif chance_multiplier < 0.0
		chance_multiplier = 0.0
	endif
	if inverted
		chance_multiplier = 1.0 - chance_multiplier
	endif
	return chance_multiplier
EndFunction

Float Function RecentlyPunishedChanceMultiplier(Float mod_duration = 60.0, Bool inverted = false)
	Float chance_multiplier = DecayOverTime(slave.ticks_since_last_punished, mod_duration, 1.0, 0.0)
	if chance_multiplier > 1.0
		chance_multiplier = 1.0
	endif
	if inverted
		chance_multiplier = 1.0 - chance_multiplier
	endif
	return chance_multiplier
EndFunction

Float Function ChanceFightForPlayer()
	if !slave.should_fight_for_player
		return 0.0
	endif
	Float chance = 0.5 + (slave.combat_training / 200)
	chance = chance * (0.5 + (SubmissionChanceMultiplier() * 0.7))
	chance = chance * (1 + (RecentlyPunishedChanceMultiplier(30.0) * 0.8))
	return chance
EndFunction

Float Function ChanceAngry()
	return ((anger_rating)/100) * (1.0 - (slave.anger_training / 100))
EndFunction

Float Function ChanceAfraid()
	return ((fear_rating)/100)
EndFunction

Float Function ChanceRecoverFromAfraid()
	Float chance = (fear_rating + 10) / 100
	chance = chance * RecentlyPunishedChanceMultiplier(inverted = true)
	return chance
EndFunction

Float Function ChanceRespectful()
	if !slave.should_be_respectful
		return 0.0
	endif
	Float chance = (((slave.respect_training + 10) * 1.6) / 110)
	chance = chance * SubmissionChanceMultiplier()
	if mood == "angry"
		chance = chance * 0.60
	endif
	chance = chance * (1 + (RecentlyPunishedChanceMultiplier(30.0) * 0.8))
	return chance
EndFunction

; Float Function ChanceDoGreetingPose()
; 	return 1.0
; EndFunction

Float Function DecayOverTime(Float time, Float half_life = 60.0, Float max_val = 1.0, Float min_val = 0.0)
	return ((max_val - min_val) / ((time/half_life) + 1)) + min_val
EndFunction

;### Utility ###