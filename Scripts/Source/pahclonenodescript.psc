Scriptname PAHCloneNodeScript extends ObjectReference  

PAHClonifierBaseScript Property PAHClonifier Auto
Int Property node_index Auto

EncounterZone Property PAH0to9Zone Auto
EncounterZone Property PAH10to19Zone Auto
EncounterZone Property PAH20to29Zone Auto
EncounterZone Property PAH30to39Zone Auto
EncounterZone Property PAH40to49Zone Auto
EncounterZone Property PAH50to59Zone Auto
EncounterZone Property PAH60to69Zone Auto
EncounterZone Property PAH70to79Zone Auto
EncounterZone Property PAH80to89Zone Auto
EncounterZone Property PAH90to99Zone Auto
EncounterZone Property PAH100to109Zone Auto
EncounterZone Property PAH110to119Zone Auto
EncounterZone Property PAH120to129Zone Auto
EncounterZone Property PAH130to139Zone Auto
EncounterZone Property PAH140to149Zone Auto
EncounterZone Property PAH150to159Zone Auto
EncounterZone Property PAH160to169Zone Auto
EncounterZone Property PAH170to179Zone Auto
EncounterZone Property PAH180to189Zone Auto
EncounterZone Property PAH190to199Zone Auto
EncounterZone Property PAH200PlusZone Auto


Outfit Property PAHNothingOutfit Auto

Static Property XMarkerHeading Auto


Faction Property PAHCleaned Auto

Actor original
Actor clone

Function Clone(Actor original_actor)
	original = original_actor
	RegisterForSingleUpdate(0.1)
EndFunction


Event OnUpdate()
	do_clone()
EndEvent


State cloning
	Function Clone(Actor original_actor)
	EndFunction
EndState


State cloned
	Function Clone(Actor original_actor)
	EndFunction

	Event OnUpdate()
		clone.Delete()
		original = None
		clone = None
		PAHClonifier.original_actors[node_index] = None
		PAHClonifier.cloned_actors[node_index] = None
		GoToState("")
	EndEvent
EndState

State switched
	Function Clone(Actor original_actor)
	EndFunction

	Event OnUpdate()
		original.Delete()
		original = None
		clone = None
		PAHClonifier.original_actors[node_index] = None
		PAHClonifier.cloned_actors[node_index] = None
		GoToState("")
	EndEvent
EndState


Actor Function SwitchClone()
	ObjectReference original_position_marker = original.PlaceAtMe(XMarkerHeading)
	original_position_marker.MoveTo(original)

	original.MoveTo(self)
	clone.MoveTo(original_position_marker)
	clone.SetPosition(original_position_marker.GetPositionX(), original_position_marker.GetPositionY(), original_position_marker.GetPositionZ())

	GoToState("switched")
	RegisterForSingleUpdate(0.3)
	return clone
EndFunction


Function do_clone()
	GoToState("cloning")

	ActorBase original_base = original.GetLeveledActorBase()
	ActorBase clone_base

	EncounterZone level_band_zone
	if original.GetLevel() < 10
		level_band_zone = PAH0to9Zone
	elseif original.GetLevel() < 20
		level_band_zone = PAH10to19Zone
	elseif original.GetLevel() < 30
		level_band_zone = PAH20to29Zone
	elseif original.GetLevel() < 40
		level_band_zone = PAH30to39Zone
	elseif original.GetLevel() < 50
		level_band_zone = PAH40to49Zone
	elseif original.GetLevel() < 60
		level_band_zone = PAH50to59Zone
	elseif original.GetLevel() < 0
		level_band_zone = PAH60to69Zone
	elseif original.GetLevel() < 0
		level_band_zone = PAH70to79Zone
	elseif original.GetLevel() < 0
		level_band_zone = PAH80to89Zone
	elseif original.GetLevel() < 0
		level_band_zone = PAH90to99Zone
	elseif original.GetLevel() < 0
		level_band_zone = PAH100to109Zone
	elseif original.GetLevel() < 0
		level_band_zone = PAH110to119Zone
	elseif original.GetLevel() < 0
		level_band_zone = PAH120to129Zone
	elseif original.GetLevel() < 0
		level_band_zone = PAH130to139Zone
	elseif original.GetLevel() < 0
		level_band_zone = PAH140to149Zone
	elseif original.GetLevel() < 0
		level_band_zone = PAH150to159Zone
	elseif original.GetLevel() < 0
		level_band_zone = PAH160to169Zone
	elseif original.GetLevel() < 0
		level_band_zone = PAH170to179Zone
	elseif original.GetLevel() < 0
		level_band_zone = PAH180to189Zone
	elseif original.GetLevel() < 0
		level_band_zone = PAH190to199Zone
	else
		level_band_zone = PAH200PlusZone
	endif

	int tries = 0

	while tries < 50
		clone = PlaceActorAtMe(original.GetActorBase(), 4, level_band_zone)
		clone_base = clone.GetLeveledActorBase()

		if actor_base_is_similar(original_base, clone_base)
			;# Copy gear across and set outfit
			clone.SetOutfit(PAHNothingOutfit)
			clone.SetOutfit(PAHNothingOutfit, true)
			clone.RemoveAllItems()

			Int i = original.GetNumItems()
			Form the_form

			while i > 0
				i -= 1
				the_form = original.GetNthForm(i)
				clone.AddItem(the_form, original.GetItemCount(the_form))
				if the_form as Armor != None
					clone.EquipItem(the_form, true)
				endif
			endwhile

			assign_factions()

			clone.SetAv("Aggression", 0)
			clone.SetAv("Confidence", 2)
			clone.SetAv("Assistance", 0)
			clone.IgnoreFriendlyHits(true)
			
			PAHClonifier.cloned_actors[node_index] = clone
			GoToState("cloned")
			RegisterForSingleUpdate(30.0)
			return
		else
			clone.Delete()
		endif

		tries += 1
	endwhile

	original = None
	clone = None
	GoToState("")
	PAHClonifier.original_actors[node_index] = None
EndFunction

Bool Function actor_base_is_similar(ActorBase actor_base_1, ActorBase actor_base_2)
	if (actor_base_1.GetSex() != actor_base_2.GetSex())
		return false
	endif
	if (actor_base_1.GetRace() != actor_base_2.GetRace())
		return false
	endif
	if (actor_base_1.GetFacePreset(0) != actor_base_2.GetFacePreset(0))
		return false
	endif
	if (actor_base_1.GetFacePreset(2) != actor_base_2.GetFacePreset(2))
		return false
	endif
	if (actor_base_1.GetFacePreset(3) != actor_base_2.GetFacePreset(3))
		return false
	endif		

	return true
EndFunction

Function assign_factions()
	clone.SetCrimeFaction(None)
	clone.RemoveFromAllFactions()
	clone.AddToFaction(PAHCleaned)
EndFunction