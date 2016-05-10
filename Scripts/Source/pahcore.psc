Scriptname PAHCore extends Quest Conditional

import Game

PAH_MCM Property Config Auto
SexLabFramework Property SexLab Auto

ReferenceAlias[] Property slave_aliases Auto
PAHClonifierBaseScript Property clonifier Auto
PAHE_slaveCandidate Property slaveCandidate Auto

PAHPersonalityDefinition[] Property personality_definitions Auto
PAHPersonalityDefinition Property default_male_personality_definition Auto
PAHPersonalityDefinition Property default_female_personality_definition Auto

Weapon Property PAHWhip Auto

Faction Property PAHCleaned Auto
Faction Property PAHTrainAnal Auto Hidden
Faction Property PAHTrainSex Auto Hidden
Faction Property PAHTrainOral Auto Hidden
Faction Property PAHTrainVaginal Auto Hidden
Faction Property PAHTrainFear Auto Hidden

Faction Property PAHPlayerSlaveFaction Auto

Faction Property sexSlaves Auto Hidden
Faction Property Stormcloaks Auto
Faction Property ImperialSoldiers Auto
Faction Property Bandits Auto
Faction Property Necromancers Auto

Faction Property DLC1ThrallFaction Auto
Faction Property dunPrisonerFaction Auto
Faction Property WINeverFillAliasesFaction Auto

Faction Property currentFollowerFaction Auto
Faction Property currentHirelingFaction Auto

Keyword Property defeatActive Auto Hidden

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

Form Property CuffsRope Auto
Form Property CuffsLeather Auto
Form Property CuffsIron Auto
Form Property CuffsIronBrown Auto
Form Property CuffsSimpleBlack Auto
Form Property CuffsSimpleBrown Auto
Form Property WristLeather Auto
Form Property WristIron Auto
Form Property AnkleLeather Auto
Form Property AnkleIron Auto

ObjectReference Property CloneMarker Auto
Static Property XMarkerHeading Auto
Outfit Property PAHNothingOutfit Auto
Keyword _dd_collar
Keyword Property DD_Collar Hidden
	Keyword Function Get()
		return _dd_collar
	EndFunction
EndProperty

Actor Property player Auto

Spell Property WhistleSpell Auto
Spell Property CaptureSpell Auto
Idle Property defeatIdle Auto

EffectShader Property CaptureShader Auto

;# Conditional properties
int Property slave_count Auto Conditional
bool Property is_full Auto Conditional
bool Property bAlwaysAggressive Auto Conditional

String __modStatus
String Property modStatus
	String function get()
		If __modStatus == "running"
			return "$PAHE_SettingName_RebootToggle_running"
		ElseIf __modStatus == "stopped"
			return "$PAHE_SettingName_RebootToggle_stopped"
		ElseIf __modStatus == "restarting"
			return "$PAHE_SettingName_RebootToggle_restarting"
		Else 
			return "Unknown, click to restart mod"
		EndIf
	EndFunction
	Function set(String value)
		If value == "running" || value == "stopped" || value == "restarting"
			__modStatus = value
		EndIf
	EndFunction
EndProperty

;### Events
Event OnPlayerLoadGame()
	Debug.trace("====================PAHExtension: Startup Process.===================================")
	if !player
		player = Game.GetPlayer()
	EndIf
	Debug.trace("====================PAHExtension: Checking for soft dependencies.====================")
	sexSlaves = Game.GetFormFromFile(0xD6B, "SexSlavesForVanillaBandits.esp") As Faction
	If !sexSlaves
		sexSlaves = Game.GetFormFromFile(0xD6B, "MoreBanditCamps - SexSlaves.esp") As Faction
	EndIf
	DLC1ThrallFaction = Game.GetFormFromFile(0x162F7, "Dawnguard.esm") As Faction
	_dd_collar = Game.GetFormFromFile(0x3DF7, "Devious Devices - Assets.esm") As Keyword

	defeatActive = Game.GetFormFromFile(0x5c666, "SexLabDefeat.esp") as Keyword
	Debug.trace("====================PAHExtension: End of soft dependencies.==========================")
	registerKeys()
	updateSlaveArray()
	registerSlavesForEvents()
	Debug.trace("====================PAHExtension: Startup Process finished.==========================")
EndEvent

Event OnBootstrap()
	RegisterForSingleUpdate(0.5)
	SetObjectiveDisplayed(0)
EndEvent

Event OnUpdate()
	FalsifyClearingLeastPointOnTick()
	RegisterForSingleUpdate(0.5)
EndEvent

Function registerKeys()
	If Config.hotkey != -1
		RegisterForKey(Config.hotkey)
	EndIf
	If Config.whistleKey != -1
		RegisterForKey(config.whistleKey)
	EndIf
EndFunction

Function registerSlavesForEvents()
	int i = 0
	while i < slaveArray.length
;		PAHSlave slave = slaveArray[i]
;		slave.registerSexEvent()
		slaveArray[i].registerSexEvent()
		i += 1
	EndWhile
EndFunction

Event OnKeyDown(Int KeyCode)
	If !Utility.IsInMenuMode()
		If KeyCode == Config.whistleKey
			WhistleSpell.Cast(player)
		ElseIf KeyCode == Config.hotKey
			getSlaveCandidateByKeypress()
		EndIf
	EndIf
EndEvent

Bool Function MarkTarget(Actor Target)
	Actor MarkedOne = (slaveCandidate.GetReference() As Actor)
	If (!MarkedOne || MarkedOne && (MarkedOne != Target))
		slaveCandidate.ForceRefTo(Target)
		(slaveCandidate as PAHE_slaveCandidate).Filled()
		CaptureShader.Play(Target, 0.5) ; MarkFXS
		Return True
	Endif
	Return False
EndFunction

Function getSlaveCandidateByKeypress()
	Actor Target = GetCurrentCrosshairRef() as Actor
	If Target
		If player.IsSneaking() && !player.IsDetectedBy(target) && !target.HasKeywordString("testChick") && !target.IsBleedingOut()
			OverwhelmTarget(target)
		Else
			CaptureSpell.Cast(player, Target)
		EndIf
	Else
		CaptureSpell.Cast(player)
	EndIf
EndFunction

Function OverwhelmTarget(Actor target)
	target.PlayIdleWithTarget(None, player)
	Utility.Wait(0.3)
EndFunction

;### Public
PAHSlave Function AddSlave(Actor slave_actor)
	SetObjectiveDisplayed(0)
	ReferenceAlias slave_alias

	slave_alias = GetSlave(slave_actor)
	If slave_alias != None
		return slave_alias as PAHSlave
	EndIf

	slave_alias = GetEmptyAlias()
	If slave_alias == None
		return None
	EndIf
	slave_alias.ForceRefTo(slave_actor)
	updateSlaveArray(slave_alias)

	(slave_alias as PAHActorAlias).AfterAssign()
	(slave_alias as PAHSlave).AfterAssign()
	(slave_alias as PAHSlaveMind).AfterAssign()

	return slave_alias as PAHSlave
EndFunction

Function RemoveSlave(ReferenceAlias slave_alias)
	(slave_alias as PAHSlaveMind).BeforeClear()
	(slave_alias as PAHSlave).BeforeClear()
	(slave_alias as PAHActorAlias).BeforeClear()

	updateSlaveArray(slave_alias, true)

	UpdateSlaveCount()
EndFunction

ReferenceAlias Function GetSlaveAlias(Actor slave_actor)
	Int i = 0
	While i < slave_aliases.length
		If slave_aliases[i] && slave_aliases[i].GetActorRef() == slave_actor
			return slave_aliases[i]
		EndIf
		i += 1
	EndWhile

	return None
EndFunction

PAHSlave Function GetSlave(Actor slave_actor)
	return GetSlaveAlias(slave_actor) as PAHSlave
EndFunction

Function PlayerEquipWeapon(Weapon weapon_to_equip)
	If player.GetItemCount(weapon_to_equip) > 0
		player.EquipItem(weapon_to_equip)
		player.DrawWeapon()
	EndIf
EndFunction

Function HandleLocationChange()
	; Actor player_ref = Game.GetPlayer()
	; Worldspace ws_ref = player_ref.GetWorldSpace()

	; int i = 0
	; while (i < slave_aliases.length)
	; 	If (slave_aliases[i] as PAHActorAlias).accompanying_player && !IsTogetherWith(slave_aliases[i].GetActorRef(), Game.GetPlayer())
	; 		slave_aliases[i].GetActorRef().MoveTo(player_ref)
	; 	EndIf
	; 	i += 1
	; endwhile
EndFunction

Function RegisterPersonalityDefinition(PAHPersonalityDefinition personality_definition)
	int i = 0
	While (i < personality_definitions.length)
		If personality_definitions[i] != None
			personality_definitions[i] = personality_definition
			return
		EndIf
		i += 1
	EndWhile
EndFunction

;### Private
ReferenceAlias Function GetEmptyAlias()
	Int i = 0
	While i < slave_aliases.length
		If slave_aliases[i].GetRef() == None
			return slave_aliases[i]
		EndIf
		i += 1
	EndWhile

	return None
EndFunction

Int Function GetSlaveCount()
	int count = 0;
	int i = 0
	While i < slave_aliases.length
		If slave_aliases[i].GetRef() != None
			count += 1
		EndIf
		i += 1
	EndWhile
	return count
EndFunction

Int Function GetMaxSlaveCount()
	return slave_aliases.length
EndFunction

PAHSlave Function GetSlaveByIndex(int index)
	If index < GetSlaveCount()
		return slaveArray[index]
	EndIf
	return None
EndFunction

PAHSlave[] _slave_array
PAHSlave[] Property slaveArray
	PAHSlave[] Function Get()
		If !_slave_array
			updateSlaveArray()
		EndIf
		return _slave_array
	endFunction
EndProperty

String[] _slave_names
String Function getSlaveName(int index)
	return _slave_names[index]
EndFunction

Function setSlaveName(int index)
	PAHSlave slave = _slave_array[index]
	_slave_names[index] = slave.GetActorRef().getDisplayName()
EndFunction

Function updateSlaveArray(ReferenceAlias _alias = None, bool remove = false)
	PAHSlave[] tmp_slaveArray = new PAHSlave[1]
	String[] tmp_stringArray = new String[1]

	If !_slave_array || (!_alias && !remove)
		int slaveCount = GetSlaveCount()
		tmp_slaveArray = GetSlaveArrayLength(slaveCount)
		tmp_stringArray = GetStringArrayLength(slaveCount)
		int currentSlaveIndex = 0
		int i = 0
		While i < slave_aliases.length
			PAHSlave slave = slave_aliases[i] as PAHSlave
			If slave.GetActorRef() && slave.GetActorRef().GetFormID()
				tmp_slaveArray[currentSlaveIndex] = slave
				tmp_stringArray[currentSlaveIndex] = slave.GetActorRef().getDisplayName()
				currentSlaveIndex += 1
			EndIf
			i += 1
		EndWhile
	ElseIf _alias && _alias.GetActorRef().getFormID() && !remove
		int newArrayLength = _slave_array.length + 1
		tmp_slaveArray = GetSlaveArrayLength(newArrayLength)
		tmp_stringArray = GetStringArrayLength(newArrayLength)
		int i = 0
		While i < newArrayLength - 1
			tmp_slaveArray[i] = _slave_array[i]
			tmp_stringArray[i] = _slave_array[i].GetActorRef().getDisplayName()
			i += 1
		EndWhile
		tmp_slaveArray[i] = _alias as PAHSlave
		tmp_stringArray[i] = _alias.GetActorRef().getDisplayName()
	ElseIf remove && _alias
		int newArrayLength = _slave_array.length - 1
		tmp_slaveArray = GetSlaveArrayLength(newArrayLength)
		tmp_stringArray = GetStringArrayLength(newArrayLength)
		bool bNewArray = false
		int old_index = 0
		int new_index = 0
		While old_index < _slave_array.length
			If _slave_array[old_index] != None && _slave_array[old_index].GetActorRef() != None
				If _slave_array[old_index] as ReferenceAlias != _alias
					tmp_slaveArray[new_index] = _slave_array[old_index]
					tmp_stringArray[new_index] = _slave_array[old_index].GetActorRef().GetDisplayName()
					new_index += 1
				Else
					_alias.clear()
					bNewArray = true
				EndIf
			EndIf
			old_index += 1
		EndWhile
		If !bNewArray
			return
		EndIf
	EndIf

	If tmp_slaveArray && tmp_stringArray
		_slave_array = tmp_slaveArray
		_slave_names = tmp_stringArray
	EndIf

;		While new_index < newArrayLength && old_index < newArrayLength + 1
;			If _slave_array[old_index] != None && _slave_array[old_index].GetActorRef() != None
;				tmp_slaveArray[new_index] = _slave_array[old_index]
;				tmp_stringArray[new_index] = _slave_array[old_index].GetActorRef().GetDisplayName()
;				new_index += 1
;			EndIf
;			old_index += 1
;		EndWhile
EndFunction

;PAHSlave[] Function GetAllSlaves()
;	return _slave_array
;EndFunction

Int Function UpdateSlaveCount()
	If !slaveArray
		slave_count = GetSlaveCount()
	Else
		slave_count = slaveArray.length
	EndIf
	is_full = slave_count == slave_aliases.length
	If config.showSlaveCountToggle
		Debug.Notification("Active Slaves: " + slave_count as String + "/" + slave_aliases.length as String)
	EndIf
	return slave_count
EndFunction

; Function _handle_on_player_changed_action()
; 	If (Game.GetPlayer().GetCombatState() > 0) != player_in_combat || Game.GetPlayer().IsSneaking() != player_sneaking || Game.GetPlayer().IsWeaponDrawn() != player_weapon_drawn
; 		player_in_combat = Game.GetPlayer().GetCombatState() > 0
; 		player_sneaking = Game.GetPlayer().IsSneaking()
; 		player_weapon_drawn = Game.GetPlayer().IsWeaponDrawn()

; 		int i = 0
; 		While i < slave_aliases.length
; 			If slave_aliases[i].GetActorRef() != None
; 				slave_aliases[i].OnPlayerChangedAction()
; 			EndIf
; 			i += 1
; 		EndWhile
; 	EndIf
; EndFunction

;### Capture
bool considerFactions = false
bool issexSlaves = false

Function Capture(Actor captive)
	If captive != slaveCandidate.GetActorRef()
		Debug.SendAnimationEvent(captive, "BleedOutStart")
	EndIf
	Actor cleaned_captive = Clone(captive)
	If cleaned_captive != None
		cleaned_captive.AllowPCDialogue(false)
		AddSlave(cleaned_captive)
		UpdateSlaveCount()

;		int relRank = cleaned_captive.GetRelationShipRank(player)
;		cleaned_captive.SetRelationshipRank(player, relRank - 2)
		cleaned_captive.SetRelationshipRank(player, -2)

		If considerFactions
			If issexSlaves
				randomizeTraining(cleaned_captive)
			EndIf
			resetFactions()
		EndIf

		cleaned_captive.setAlpha(0.0)

		switchActors(captive, cleaned_captive)

		cleaned_captive.AllowPCDialogue(true)
		cleaned_captive.setAlpha(1)
	EndIf
EndFunction

Actor Function Clone(Actor original)
	If original.IsInFaction(PAHCleaned)
		return original
	EndIf

	ActorBase original_base = GetValidActorBase(original)
	Actor clone
	ActorBase clone_base

	considerFactions = getFactions(original)

	EncounterZone level_band_zone = getEncounterZone(original.getLevel())

	int tries = 0
	While tries < 100
		clone = CloneMarker.PlaceActorAtMe(original_base, 4, level_band_zone)

		If actor_base_is_similar(original_base, clone.GetLeveledActorBase())
			
			;# Copy gear across and set outfit
			clone.SetOutfit(PAHNothingOutfit)
			clone.SetOutfit(PAHNothingOutfit, true)
			clone.RemoveAllItems()
		
			Int i = original.GetNumItems()
			Form the_form

			While i > 0
				i -= 1
				the_form = original.GetNthForm(i)
				If !(defeatActive && the_form.HasKeyword(Keyword.GetKeyword("DefeatWornDevice")))
					clone.AddItem(the_form, original.GetItemCount(the_form))
					If the_form as Armor != None
						clone.EquipItem(the_form, true)
					EndIf
				EndIf
			EndWhile
										
			copySexStats(clone, original)
			clone.SetCrimeFaction(None)
			clone.RemoveFromAllFactions()
		
			clone.IgnoreFriendlyHits(true)
			If Config.renameToggle
				If !original_base.IsUnique()
					string gender
					If clone.GetLeveledActorBase().getSex() == 0
						gender = "Male"
					Else
						gender = "Female"
					EndIf
					string sRace = clone.getRace().getName()
		
					int jNames = JValue.readFromFile("Data/PAHE/" + gender + sRace + ".txt")
					int rInt = Utility.RandomInt(0, JArray.count(jnames) - 1)
					string name = JArray.getStr(jnames, rInt)
	
					If name != ""
						clone.SetDisplayName(name)
					Else
						Debug.trace("[PAHCore] Line 520 No name found for " + gender + sRace)
					EndIf
				Else
					clone.setDisplayName(original.getDisplayName())
				EndIf
			EndIf
			setSLSkills(original, clone)
			return clone
		Else
			clone.Delete()
		EndIf
		tries += 1
	EndWhile
;	original_base = GetValidActorBase(original)
;	clone = createClone(CloneMarker.PlaceActorAtMe(GetValidActorBase(original), 4, level_band_zone), original)
	return None
EndFunction

ActorBase function GetValidActorBase(actor akActor)
	ActorBase base = akActor.GetActorBase()
	ActorBase base_leveled = akActor.GetLeveledActorBase()

	if base != base_leveled
		return base_leveled.GetTemplate()
	else
		return base
	endIf
endFunction

Function setSLSkills(Actor source, Actor target)
	SexLab.Stats.SetSkill(target, "TimeSpent", SexLab.Stats.GetSkill(source, "TimeSpent"))
	SexLab.Stats.SetSkill(target, "Sexuality", SexLab.Stats.GetSkill(source, "Sexuality"))
	SexLab.Stats.setSkill(target, "Males" , SexLab.Stats.GetSkill(source, "Males"))
	SexLab.Stats.setSkill(target, "Females", SexLab.Stats.GetSkill(source, "Females"))
	SexLab.Stats.setSkill(target, "Creatures", SexLab.Stats.GetSkill(source, "Creatures"))
	SexLab.Stats.setSkill(target, "Masturbation", SexLab.Stats.GetSkill(source, "Masturbation"))
	SexLab.Stats.setSkill(target, "Aggressor", SexLab.Stats.GetSkill(source, "Aggressor"))
	SexLab.Stats.setSkill(target, "Victim", SexLab.Stats.GetSkill(source, "Victim"))
EndFunction

Function switchActors(Actor original, Actor clone)
	clone.MoveTo(original)
	clone.SetPosition(original.GetPositionX(), original.GetPositionY(), original.GetPositionZ())

	RPNodes.transferNode(original, clone)
	original.Disable()
	original.MoveTo(CloneMarker)
	original.EnableNoWait()
	If original == slaveCandidate.getActorRef()
		slaveCandidate.clear()
	EndIf
	original.EndDeferredKill()
	original.KillEssential(player)
	Debug.SendAnimationEvent(clone, "BleedOutStart")
EndFunction

Function randomizeTraining(Actor _actor)
	PAHSlave slave = GetSlave(_actor)
	If issexSlaves
		slave.TrainAnger(Utility.RandomFloat(0.0, 30.0))
		slave.TrainRespect(Utility.RandomFloat(0.0, 30.0))
		slave.TrainOral(Utility.RandomFloat(5.0, 30.0))
		slave.TrainAnal(Utility.RandomFloat(5.0, 30.0))
		slave.TrainVaginal(Utility.RandomFloat(5.0, 30.0))
	EndIf
	slave.TrainSubmission((slave.combat_training + slave.anger_training + slave.respect_training + slave.sex_training)/6)
EndFunction

bool Function getFactions(Actor _actor)
	If sexSlaves != None && _actor.IsInFaction(sexSlaves)
		issexSlaves = true
	EndIf
	return issexSlaves
EndFunction

Function resetFactions()
	considerFactions = false
	issexSlaves = false
EndFunction

Bool Function actor_base_is_similar(ActorBase actor_base_1, ActorBase actor_base_2)
    If (actor_base_1.GetSex() != actor_base_2.GetSex())
        return false
    ElseIf (actor_base_1.GetRace() != actor_base_2.GetRace())
        return false
    ElseIf (actor_base_1.GetFacePreset(0) != actor_base_2.GetFacePreset(0))
        return false
    ElseIf (actor_base_1.GetFacePreset(2) != actor_base_2.GetFacePreset(2))
        return false
    ElseIf (actor_base_1.GetFacePreset(3) != actor_base_2.GetFacePreset(3))
        return false
    EndIf

    return true
EndFunction

;### Leashing
Bool __clearing_leash_point = false
Bool Property clearing_leash_point
	Bool Function Get()
		return __clearing_leash_point
	EndFunction
	Function Set(Bool value)
		__clearing_leash_point = value
		clearing_leash_point_timer = 0
	EndFunction
EndProperty

Int clearing_leash_point_timer = 0
Function FalsifyClearingLeastPointOnTick()
	clearing_leash_point_timer += 1
	If clearing_leash_point_timer == 2
		clearing_leash_point = false
	EndIf
EndFunction

Bool Function LeashPointInUse(ObjectReference leash_point)
	int i = 0
	While (i < slave_aliases.length)
		If (slave_aliases[i] as PAHActorAlias).leash_point == leash_point
			return true
		EndIf
		i += 1
	EndWhile
	return false
EndFunction

Function ClearLeashPoint(ObjectReference leash_point)
	int i = 0
	While (i < slave_aliases.length)
		If (slave_aliases[i] as PAHActorAlias).leash_point == leash_point
			(slave_aliases[i] as PAHActorAlias).leash_point = None
		EndIf
		i += 1
	EndWhile
EndFunction

;### Utility
Bool Function IsTogetherWith(ObjectReference subject_ref, ObjectReference object_ref)
	If object_ref.IsInInterior()
		return subject_ref.GetParentCell() == object_ref.GetParentCell()
	Else
		return subject_ref.GetWorldSpace() == object_ref.GetWorldSpace() && subject_ref.GetDistance(object_ref) < 10000
	EndIf
EndFunction

Bool Function isCaster(PAHSlave slave_actor)
	Actor base = slave_actor.getActorRef()
	float fighterSkill = getMax(base.GetActorValue("OneHanded"), base.GetActorValue("TwoHanded"))
	float magicSkill = getMax(base.GetActorValue("Conjuration"), base.GetActorValue("Destruction"))

	return magicSkill > fighterSkill
EndFunction

float Function getMax(float value_1, float value_2)
	If value_1 > value_2
		return value_1
	Else
		return value_2
	EndIf
EndFunction

bool Function IsEvenInt(int value)
	float half = value / 2
	half = half - (half as Int)
	return half == 0.0
EndFunction

Bool Function IsFollower(Actor Target)
	Return (Target.isPlayerTeammate() || Target.IsInFaction(currentFollowerFaction) || Target.IsInFaction(currentHirelingFaction))
EndFunction

int _slaverRank = 0
int Property slaverRank
	int Function Get()
		return _slaverRank
	EndFunction
EndProperty

int _slaverRankTicks = 0
Function tickSlaverRank()
	_slaverRankTicks += 1
EndFunction

int _slaverSetting = 0
int slaverSettingCount = 4
int Property slaverSetting
	int Function Get()
		return _slaverSetting
	EndFunction
	Function Set(int value)
		If value >= 0
			If value < slaverSettingCount
				_slaverSetting = value
			ElseIf value == slaverSettingCount
				_slaverSetting = 0
			EndIf
		EndIf
	EndFunction
EndProperty

bool Property enableDebug
	bool Function Get()
		return Config.debugToggle
	endFunction
EndProperty

Function copySexStats(Actor target, Actor source)
	SexLab.ActorAdjustBy(target, "Sexuality", (SexLab.GetActorStatInt(source, "Sexuality") - SexLab.GetActorStatInt(target, "Sexuality")))
	SexLab.ActorAdjustBy(target, "Foreplay", (SexLab.GetActorStatInt(source, "Foreplay") - SexLab.GetActorStatInt(source, "Foreplay")))
	SexLab.ActorAdjustBy(target, "Vaginal", (SexLab.GetActorStatInt(source, "Vaginal") - SexLab.GetActorStatInt(source, "Vaginal")))
	SexLab.ActorAdjustBy(target, "Anal", (SexLab.GetActorStatInt(source, "Anal") - SexLab.GetActorStatInt(target, "Anal")))
	SexLab.ActorAdjustBy(target, "Oral", (SexLab.GetActorStatInt(source, "Oral") - SexLab.GetActorStatInt(target, "Oral")))
	SexLab.ActorAdjustBy(target, "Pure", (SexLab.GetActorStatInt(source, "Pure") - SexLab.GetActorStatInt(target, "Pure")))
	SexLab.ActorAdjustBy(target, "Lewd", (SexLab.GetActorStatInt(source, "Lewd") - SexLab.GetActorStatInt(target, "Lewd")))
EndFunction

EncounterZone Function getEncounterZone(int _level)
	If _level < 10
		return PAH0to9Zone
	ElseIf _level < 20
		return PAH10to19Zone
	ElseIf _level < 30
		return PAH20to29Zone
	ElseIf _level < 40
		return PAH30to39Zone
	ElseIf _level < 50
		return PAH40to49Zone
	ElseIf _level < 60
		return PAH50to59Zone
	ElseIf _level < 70
		return PAH60to69Zone
	ElseIf _level < 80
		return PAH70to79Zone
	ElseIf _level < 90
		return PAH80to89Zone
	Else
		return PAH200PlusZone
	EndIf
EndFunction

int[] Function GetIntArrayLength(Int dl)
	If dl > 64
		return new int[128]
	ElseIf dl <= 32
		If dl <= 16
			If dl <= 8
				If dl <= 4
					If dl <= 2
						If dl == 1
							return new int[1]
						ElseIf dl == 2
							return new int[2]
						Else
							return None
						EndIf
					Else
						If dl == 3
							return new int[3]
						Else
							return new int[4]
						EndIf
					EndIf
				Else
					If dl <= 6
						If dl == 5
							return new int[5]
						Else
							return new int[6]
						EndIf
					Else
						If dl == 7
							return new int[7]
						Else
							return new int[8]
						EndIf
					EndIf
				EndIf
			Else
				If dl <= 12
					If dl <= 10
						If dl == 9
							return new int[9]
						Else
							return new int[10]
						EndIf
					Else
						If dl == 11
							return new int[11]
						Else
							return new int[12]
						EndIf
					EndIf
				Else
					If dl <= 14
						If dl == 13
							return new int[13]
						Else
							return new int[14]
						EndIf
					Else
						If dl == 15
							return new int[15]
						Else
							return new int[16]
						EndIf
					EndIf
				EndIf
			EndIf
		Else
			If dl <= 24
				If dl <= 20
					If dl <= 18
						If dl == 17
							return new int[17]
						Else
							return new int[18]
						EndIf
					Else
						If dl == 19
							return new int[19]
						Else
							return new int[20]
						EndIf
					EndIf
				Else
					If dl <= 22
						If dl == 21
							return new int[21]
						Else
							return new int[22]
						EndIf
					Else
						If dl == 23
							return new int[23]
						Else
							return new int[24]
						EndIf
					EndIf
				EndIf
			Else
				If dl <= 28
					If dl <= 26
						If dl == 25
							return new int[25]
						Else
							return new int[26]
						EndIf
					Else
						If dl == 27
							return new int[27]
						Else
							return new int[28]
						EndIf
					EndIf
				Else
					If dl <= 30
						If dl == 29
							return new int[29]
						Else
							return new int[30]
						EndIf
					Else
						If dl == 31
							return new int[31]
						Else
							return new int[32]
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
	Else
		If dl <= 48
			If dl <= 40
				If dl <= 36
					If dl <= 34
						If dl == 33
							return new int[33]
						Else
							return new int[34]
						EndIf
					Else
						If dl == 35
							return new int[35]
						Else
							return new int[36]
						EndIf
					EndIf
				Else
					If dl <= 38
						If dl == 37
							return new int[37]
						Else
							return new int[38]
						EndIf
					Else
						If dl == 39
							return new int[39]
						Else
							return new int[40]
						EndIf
					EndIf
				EndIf
			Else
				If dl <= 44
					If dl <= 42
						If dl == 41
							return new int[41]
						Else
							return new int[42]
						EndIf
					Else
						If dl == 43
							return new int[43]
						Else
							return new int[44]
						EndIf
					EndIf
				Else
					If dl <= 46
						If dl == 45
							return new int[45]
						Else
							return new int[46]
						EndIf
					Else
						If dl == 47
							return new int[47]
						Else
							return new int[48]
						EndIf
					EndIf
				EndIf
			EndIf
		Else
			If dl <= 56
				If dl <= 52
					If dl <= 50
						If dl == 49
							return new int[49]
						Else
							return new int[50]
						EndIf
					Else
						If dl == 51
							return new int[51]
						Else
							return new int[52]
						EndIf
					EndIf
				Else
					If dl <= 54
						If dl == 53
							return new int[53]
						Else
							return new int[54]
						EndIf
					Else
						If dl == 55
							return new int[55]
						Else
							return new int[56]
						EndIf
					EndIf
				EndIf
			Else
				If dl <= 60
					If dl <= 58
						If dl == 57
							return new int[57]
						Else
							return new int[58]
						EndIf
					Else
						If dl == 59
							return new int[59]
						Else
							return new int[60]
						EndIf
					EndIf
				Else
					If dl <= 62
						If dl == 61
							return new int[61]
						Else
							return new int[62]
						EndIf
					Else
						If dl == 63
							return new int[63]
						Else
							return new int[64]
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf
EndFunction

String[] Function GetStringArrayLength(Int dl)
	If dl > 64
		return new String[128]
	ElseIf dl <= 32
		If dl <= 16
			If dl <= 8
				If dl <= 4
					If dl <= 2
						If dl == 1
							return new String[1]
						ElseIf dl == 2
							return new String[2]
						Else
							return None
						EndIf
					Else
						If dl == 3
							return new String[3]
						Else
							return new String[4]
						EndIf
					EndIf
				Else
					If dl <= 6
						If dl == 5
							return new String[5]
						Else
							return new String[6]
						EndIf
					Else
						If dl == 7
							return new String[7]
						Else
							return new String[8]
						EndIf
					EndIf
				EndIf
			Else
				If dl <= 12
					If dl <= 10
						If dl == 9
							return new String[9]
						Else
							return new String[10]
						EndIf
					Else
						If dl == 11
							return new String[11]
						Else
							return new String[12]
						EndIf
					EndIf
				Else
					If dl <= 14
						If dl == 13
							return new String[13]
						Else
							return new String[14]
						EndIf
					Else
						If dl == 15
							return new String[15]
						Else
							return new String[16]
						EndIf
					EndIf
				EndIf
			EndIf
		Else
			If dl <= 24
				If dl <= 20
					If dl <= 18
						If dl == 17
							return new String[17]
						Else
							return new String[18]
						EndIf
					Else
						If dl == 19
							return new String[19]
						Else
							return new String[20]
						EndIf
					EndIf
				Else
					If dl <= 22
						If dl == 21
							return new String[21]
						Else
							return new String[22]
						EndIf
					Else
						If dl == 23
							return new String[23]
						Else
							return new String[24]
						EndIf
					EndIf
				EndIf
			Else
				If dl <= 28
					If dl <= 26
						If dl == 25
							return new String[25]
						Else
							return new String[26]
						EndIf
					Else
						If dl == 27
							return new String[27]
						Else
							return new String[28]
						EndIf
					EndIf
				Else
					If dl <= 30
						If dl == 29
							return new String[29]
						Else
							return new String[30]
						EndIf
					Else
						If dl == 31
							return new String[31]
						Else
							return new String[32]
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
	Else
		If dl <= 48
			If dl <= 40
				If dl <= 36
					If dl <= 34
						If dl == 33
							return new String[33]
						Else
							return new String[34]
						EndIf
					Else
						If dl == 35
							return new String[35]
						Else
							return new String[36]
						EndIf
					EndIf
				Else
					If dl <= 38
						If dl == 37
							return new String[37]
						Else
							return new String[38]
						EndIf
					Else
						If dl == 39
							return new String[39]
						Else
							return new String[40]
						EndIf
					EndIf
				EndIf
			Else
				If dl <= 44
					If dl <= 42
						If dl == 41
							return new String[41]
						Else
							return new String[42]
						EndIf
					Else
						If dl == 43
							return new String[43]
						Else
							return new String[44]
						EndIf
					EndIf
				Else
					If dl <= 46
						If dl == 45
							return new String[45]
						Else
							return new String[46]
						EndIf
					Else
						If dl == 47
							return new String[47]
						Else
							return new String[48]
						EndIf
					EndIf
				EndIf
			EndIf
		Else
			If dl <= 56
				If dl <= 52
					If dl <= 50
						If dl == 49
							return new String[49]
						Else
							return new String[50]
						EndIf
					Else
						If dl == 51
							return new String[51]
						Else
							return new String[52]
						EndIf
					EndIf
				Else
					If dl <= 54
						If dl == 53
							return new String[53]
						Else
							return new String[54]
						EndIf
					Else
						If dl == 55
							return new String[55]
						Else
							return new String[56]
						EndIf
					EndIf
				EndIf
			Else
				If dl <= 60
					If dl <= 58
						If dl == 57
							return new String[57]
						Else
							return new String[58]
						EndIf
					Else
						If dl == 59
							return new String[59]
						Else
							return new String[60]
						EndIf
					EndIf
				Else
					If dl <= 62
						If dl == 61
							return new String[61]
						Else
							return new String[62]
						EndIf
					Else
						If dl == 63
							return new String[63]
						Else
							return new String[64]
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf
EndFunction

PAHSlave[] Function GetSlaveArrayLength(Int dl)
	If dl > 64
		return new PAHSlave[128]
	ElseIf dl <= 32
		If dl <= 16
			If dl <= 8
				If dl <= 4
					If dl <= 2
						If dl == 1
							return new PAHSlave[1]
						ElseIf dl == 2
							return new PAHSlave[2]
						Else
							return None
						EndIf
					Else
						If dl == 3
							return new PAHSlave[3]
						Else
							return new PAHSlave[4]
						EndIf
					EndIf
				Else
					If dl <= 6
						If dl == 5
							return new PAHSlave[5]
						Else
							return new PAHSlave[6]
						EndIf
					Else
						If dl == 7
							return new PAHSlave[7]
						Else
							return new PAHSlave[8]
						EndIf
					EndIf
				EndIf
			Else
				If dl <= 12
					If dl <= 10
						If dl == 9
							return new PAHSlave[9]
						Else
							return new PAHSlave[10]
						EndIf
					Else
						If dl == 11
							return new PAHSlave[11]
						Else
							return new PAHSlave[12]
						EndIf
					EndIf
				Else
					If dl <= 14
						If dl == 13
							return new PAHSlave[13]
						Else
							return new PAHSlave[14]
						EndIf
					Else
						If dl == 15
							return new PAHSlave[15]
						Else
							return new PAHSlave[16]
						EndIf
					EndIf
				EndIf
			EndIf
		Else
			If dl <= 24
				If dl <= 20
					If dl <= 18
						If dl == 17
							return new PAHSlave[17]
						Else
							return new PAHSlave[18]
						EndIf
					Else
						If dl == 19
							return new PAHSlave[19]
						Else
							return new PAHSlave[20]
						EndIf
					EndIf
				Else
					If dl <= 22
						If dl == 21
							return new PAHSlave[21]
						Else
							return new PAHSlave[22]
						EndIf
					Else
						If dl == 23
							return new PAHSlave[23]
						Else
							return new PAHSlave[24]
						EndIf
					EndIf
				EndIf
			Else
				If dl <= 28
					If dl <= 26
						If dl == 25
							return new PAHSlave[25]
						Else
							return new PAHSlave[26]
						EndIf
					Else
						If dl == 27
							return new PAHSlave[27]
						Else
							return new PAHSlave[28]
						EndIf
					EndIf
				Else
					If dl <= 30
						If dl == 29
							return new PAHSlave[29]
						Else
							return new PAHSlave[30]
						EndIf
					Else
						If dl == 31
							return new PAHSlave[31]
						Else
							return new PAHSlave[32]
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
	Else
		If dl <= 48
			If dl <= 40
				If dl <= 36
					If dl <= 34
						If dl == 33
							return new PAHSlave[33]
						Else
							return new PAHSlave[34]
						EndIf
					Else
						If dl == 35
							return new PAHSlave[35]
						Else
							return new PAHSlave[36]
						EndIf
					EndIf
				Else
					If dl <= 38
						If dl == 37
							return new PAHSlave[37]
						Else
							return new PAHSlave[38]
						EndIf
					Else
						If dl == 39
							return new PAHSlave[39]
						Else
							return new PAHSlave[40]
						EndIf
					EndIf
				EndIf
			Else
				If dl <= 44
					If dl <= 42
						If dl == 41
							return new PAHSlave[41]
						Else
							return new PAHSlave[42]
						EndIf
					Else
						If dl == 43
							return new PAHSlave[43]
						Else
							return new PAHSlave[44]
						EndIf
					EndIf
				Else
					If dl <= 46
						If dl == 45
							return new PAHSlave[45]
						Else
							return new PAHSlave[46]
						EndIf
					Else
						If dl == 47
							return new PAHSlave[47]
						Else
							return new PAHSlave[48]
						EndIf
					EndIf
				EndIf
			EndIf
		Else
			If dl <= 56
				If dl <= 52
					If dl <= 50
						If dl == 49
							return new PAHSlave[49]
						Else
							return new PAHSlave[50]
						EndIf
					Else
						If dl == 51
							return new PAHSlave[51]
						Else
							return new PAHSlave[52]
						EndIf
					EndIf
				Else
					If dl <= 54
						If dl == 53
							return new PAHSlave[53]
						Else
							return new PAHSlave[54]
						EndIf
					Else
						If dl == 55
							return new PAHSlave[55]
						Else
							return new PAHSlave[56]
						EndIf
					EndIf
				EndIf
			Else
				If dl <= 60
					If dl <= 58
						If dl == 57
							return new PAHSlave[57]
						Else
							return new PAHSlave[58]
						EndIf
					Else
						If dl == 59
							return new PAHSlave[59]
						Else
							return new PAHSlave[60]
						EndIf
					EndIf
				Else
					If dl <= 62
						If dl == 61
							return new PAHSlave[61]
						Else
							return new PAHSlave[62]
						EndIf
					Else
						If dl == 63
							return new PAHSlave[63]
						Else
							return new PAHSlave[64]
						EndIf
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf
EndFunction
