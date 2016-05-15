Scriptname PAHActorAlias extends ReferenceAlias  

;### Constants ###
PAHCore Property PAH Auto

Actor Property actor_stub Auto

;*****
; remnants of the old mule system improperly named to be fixed later*********
PAHSlave Property slave_stub Auto
;*****
PAHSlaveMind Property mind_stub Auto

Faction Property PAHAccompanyingPlayer Auto
Faction Property PAHPosing  Auto  

Faction Property PAHAAUseCOPackage Auto
Faction Property PAHAAUseIdleMarker Auto
Faction Property PAHAAFleeFrom Auto
Faction Property PAHAAFollow Auto
Faction Property PAHAAStandStill Auto
Faction Property PAHAASandboxAtTarget Auto

Faction Property PAHNaked Auto
Faction Property PAHLeashed Auto

Float game_time_update_min = 10.0
Float game_time_update_max = 20.0

Static Property XMarker Auto

Idle Property IdleCoweringLoose Auto
Form Property PAHCowerIdleMarker Auto
Idle Property IdleOffsetArmsCrossedStart Auto
Idle Property IdleWarmArms Auto
Idle Property IdleNervous Auto
Idle Property IdleCivilWarCheer Auto
Idle Property IdleWipeBrow Auto
Idle Property PAHECoverSelf Auto

Keyword Property ArmorCuirass Auto
Keyword Property ClothingBody Auto
Keyword Property ArmorShield Auto
Keyword Property PAHRestraint Auto
Keyword Property PAHRestraintLeash Auto
Keyword Property PAHCountsAsNaked Auto
Keyword Property SexLabNoStrip Auto

Spell Property PAHLeashSpell Auto

;### Properties ###
Actor __the_actor
Actor Property the_actor
	Actor Function get()
		if __the_actor == None
			__the_actor = GetActorRef()
		endif
		return __the_actor
	EndFunction
	Function set(Actor value)
		__the_actor = value
	EndFunction
EndProperty

PAHSlave __slave
PAHSlave Property slave
	PAHSlave Function get()
		if __slave == None
			__slave = (self as ReferenceAlias) as PAHSlave
;****************************
;			the following is remnants of the backpack system improperly named to be fixed later*********
			if __slave == None
				__slave = slave_stub
			endif
;********************************
		endif
		return __slave
	EndFunction
EndProperty

PAHSlaveMind __mind
PAHSlaveMind Property mind
	PAHSlaveMind Function get()
		if __mind == None
			__mind = (self as ReferenceAlias) as PAHSlaveMind
			if __mind == None
				__mind = mind_stub
			endif
		endif
		return __mind
	EndFunction
EndProperty

Int __vLevel
Int Property vLevel
	Int Function get()
		return __vLevel
	EndFunction
	Function set(int value)
		If value > __vLevel && value < Game.GetPlayer().GetLevel()
			__vLevel = value
		EndIf
	EndFunction
EndProperty

Int __lvlMod
Int Property lvlMod
	Int Function get()
		return __lvlMod
	EndFunction
	Function set(int value)
		If value > __lvlMod && value < 4
			__lvlMod = value
		EndIf
	EndFunction
EndProperty

ReferenceAlias Property target_alias Auto

ObjectReference Property target
	ObjectReference Function get()
		return target_alias.GetRef()
	EndFunction
	Function set(ObjectReference value)
		target_alias.ForceRefTo(value)
	EndFunction
EndProperty

ObjectReference __target_marker
ObjectReference Property target_marker
	ObjectReference Function get()
		if __target_marker == None
			__target_marker = the_actor.PlaceAtMe(XMarker, 1)
		endif
		return __target_marker
	EndFunction
	Function set(ObjectReference ref)
		if __target_marker == None
			__target_marker = the_actor.PlaceAtMe(XMarker, 1)
		endif
	EndFunction
EndProperty

ObjectReference __temp_idle_marker
ObjectReference Property temp_idle_marker
	ObjectReference Function get()
		return __temp_idle_marker
	EndFunction
	Function set(ObjectReference value)
		if __temp_idle_marker != None
			__temp_idle_marker.Delete()
		endif
		__temp_idle_marker = value
		target = temp_idle_marker
	EndFunction
EndProperty

;### Setup and Teardown ###
Event OnBootstrap(string eventName = "", string strArg = "", float numArg = 0.0, Form sender = None)
	UnregisterForModEvent("PAHBootstrap")
	if GetActorRef() != None
		if GetActorRef().IsDisabled()
			GetActorRef().Enable()
			GetActorRef().MoveTo(Game.GetPlayer())
		endif
		AfterAssign()
	else
		BeforeClear()
	endif
EndEvent

Event AfterAssign()
	the_actor = GetActorRef()
	if GetActorRef() != actor_stub
		BeforeClear()
		the_actor = GetActorRef()
		aggression = the_actor.GetAv("aggression") as Int
		confidence = the_actor.GetAv("confidence") as Int
		assistance = the_actor.GetAv("assistance") as Int

		ApplyEquipmentEffects()

		OnUpdateGameTime()
		OnUpdate()
	endif
EndEvent

Event BeforeClear()
	the_actor = None
	__slave = None
	__mind = None
	__target_marker = None
	current_action = ""
	accompanying_player = false
	leashed = false
EndEvent

Function RemoveFromGame()
	UnregisterForUpdate()
	the_actor.Disable()
	the_actor.DeleteWhenAble()
	PAH.RemoveSlave(self)
EndFunction

; ### Events ###

Event OnLoad()
	the_actor.SetCrimeFaction(None)
	UpdateActorAITraits()
	ApplyEquipmentEffects()

	RegisterForSingleUpdate(1.0)
	RegisterForSingleUpdateGameTime(SecondsToGameHours(Utility.RandomFloat(game_time_update_min, game_time_update_max)))
EndEvent

Event OnUpdate()
	If GetActorRef() != None
		If the_actor == None
			the_actor = GetActorRef()
		EndIf
		HandleCombatAllowedOnTick()
		OnActionUpdate()
		UpdateIsMovingOnTick()
		FinishDialogueOnTick()
		UnblockDialogueOnTick()
		RegisterForSingleUpdate(5.0)
	EndIf
EndEvent

Event OnUpdateGameTime()
	if the_actor != actor_stub
		If the_actor.isDisabled()
			the_actor.Enable()
		EndIf
		RegisterForSingleUpdateGameTime(SecondsToGameHours(Utility.RandomFloat(game_time_update_min, game_time_update_max)))
	endif
EndEvent

Event OnActivate(ObjectReference akActionRef)
	if akActionRef == Game.GetPlayer()
		HandleDialogueOnActivate()
 	endif
EndEvent

Event OnDialogueStart()
EndEvent

Event OnDialogueFinish()
EndEvent

Event OnDeath(Actor akKiller)
;	slave.backpack_mule.RemoveAllItems(the_actor, false)
	PAH.RemoveSlave(self)
EndEvent

;### Action handling ###

String __current_action = ""
String Property current_action
	String Function get()
		return __current_action
	EndFunction
	Function set(String value)
		EndAction()
		__current_action = value
		GoToState(__current_action)
		StartAction()
		the_actor.EvaluatePackage()
		SetAccompanyingPlayer()
	EndFunction
EndProperty

Bool Property accompanying_player
	Bool Function get()
		return IsInFaction(PAHAccompanyingPlayer)
	EndFunction
	Function set(Bool value)
		SetInFaction(PAHAccompanyingPlayer, value)
	EndFunction
EndProperty

Function StartAction()
EndFunction

Function EndAction()
EndFunction

Function OnActionUpdate()
EndFunction

int ticks_in_temp_idle_action = 0
Function StartTempIdleAction(Form idle_base, Idle lead_in_idle = None)
	ticks_in_temp_idle_action = 0
	if lead_in_idle != None
		the_actor.PlayIdle(lead_in_idle)
	endif
	temp_idle_marker = the_actor.PlaceAtMe(idle_base)
	AddToFaction(PAHAAUseIdleMarker)
EndFunction

Function StopTempIdleAction()
	RemoveFromFaction(PAHAAUseIdleMarker)
EndFunction

Function OnTempIdleActionUpdate()
	ticks_in_temp_idle_action += 1
	if ticks_in_temp_idle_action <= 2
		temp_idle_marker.MoveTo(the_actor)
		temp_idle_marker.SetAngle(the_actor.GetAngleX(), the_actor.GetAngleY(), the_actor.GetAngleZ())
	endif	
EndFunction

Function SetAccompanyingPlayer()
	accompanying_player = current_action == "follow" && target == Game.GetPlayer()
EndFunction

;### Action Definitions ###

Function StandStill()
;	target = None
	current_action = "stand_still"
EndFunction

State stand_still
	Function StartAction()
		AddToFaction(PAHAAStandStill)
	EndFunction

	Function EndAction()
		RemoveFromFaction(PAHAAStandStill)
	EndFunction
EndState

Function Follow(ObjectReference ref_to_follow)
	target = ref_to_follow
	current_action = "follow"
EndFunction

State follow
	Function StartAction()
		AddToFaction(PAHAAFollow)
	EndFunction

	Function EndAction()
		RemoveFromFaction(PAHAAFollow)
	EndFunction
EndState

Function FleeFrom(ObjectReference ref_to_flee_from)
	target = ref_to_flee_from
	current_action = "flee_from"
EndFunction

State flee_from
	Function StartAction()
		AddToFaction(PAHAAFleeFrom)
	EndFunction

	Function EndAction()
		RemoveFromFaction(PAHAAFleeFrom)
	EndFunction
EndState

Function Cower()
	current_action = "cower"
EndFunction

State cower
	Function StartAction()
		StartTempIdleAction(PAHCowerIdleMarker, IdleCoweringLoose)
	EndFunction

	Function OnActionUpdate()
		OnTempIdleActionUpdate()
	EndFunction

	Function EndAction()
		StopTempIdleAction()
	EndFunction
EndState

Function Sandbox()
	If target_marker
		target_marker.MoveTo(the_actor)
		target = target_marker
		current_action = "sandbox"
	Else
		Debug.trace("PAHExtension: This should never happen!")
		Debug.traceStack("PAHExtension: TargetMarker for " + self + " is None")
	EndIf
EndFunction

Function SandboxAtLeash()
	If leash_point
		target = leash_point
		current_action = "sandbox"
	EndIf
EndFunction

State sandbox
	Function StartAction()
		AddToFaction(PAHAASandboxAtTarget)
	EndFunction

	Function EndAction()
		RemoveFromFaction(PAHAASandboxAtTarget)
	EndFunction
EndState

;### Idles ###

Function CrossArms()
	If (CanIdle())
		the_actor.PlayIdle(IdleOffsetArmsCrossedStart)
	EndIf
EndFunction

Function WarmArms()
	If (CanIdle())
		the_actor.PlayIdle(IdleWarmArms)
	EndIf
EndFunction

Function LookAroundNervously()
	If (CanIdle())
		the_actor.PlayIdle(IdleNervous)
	EndIf
EndFunction

Function MakeAggressiveGesture()
	If (CanIdle())
		the_actor.PlayIdle(IdleCivilWarCheer)
	EndIf
EndFunction

Function WipeBrow()
	If (CanIdle())
		the_actor.PlayIdle(IdleWipeBrow)
	EndIf
EndFunction

Function IdleCower()
	If (CanIdle())
		the_actor.PlayIdle(IdleCoweringLoose)
	EndIf
EndFunction

Function coverSelf()
	If (CanIdle())
		If (the_actor.GetLeveledActorBase().GetSex() == 1)
			Debug.SendAnimationEvent(Target, "PAHEZaZCoverSelfF")
		Else
			Debug.SendAnimationEvent(Target, "PAHEZaZCoverSelfM")
		Endif
	EndIf
EndFunction

;### Dialogue ###
Bool Property allow_dialogue_in_combat = false Auto
Bool Property in_dialogue = false Auto
Bool dialogue_blocked = false
Int dialogue_blocked_for = 0

Function SayTopic(Topic topic_to_say, ObjectReference say_to = None)
	if !dialogue_blocked
		if say_to
			the_actor.SetLookAt(say_to)
		endif
		the_actor.Say(topic_to_say)
		dialogue_blocked_for = 5
		dialogue_blocked = true
		the_actor.AllowPCDialogue(false)
	endif
EndFunction

Function UnblockDialogue()
	dialogue_blocked = false
	the_actor.AllowPCDialogue(true)
	the_actor.ClearLookAt()
EndFunction

Function UnblockDialogueOnTick()
	if dialogue_blocked
		dialogue_blocked_for -= 1
		if dialogue_blocked_for == 0
			UnblockDialogue()
		endif
	endif
EndFunction

Function FinishDialogueOnTick()
	if in_dialogue && !the_actor.IsInDialogueWithPlayer()
		in_dialogue = false
		OnDialogueFinish()
	endif 
EndFunction

Function HandleDialogueOnActivate()
	if the_actor.IsInCombat()
		if allow_dialogue_in_combat
;			the_actor.SetRelationshipRank(Game.GetPlayer(), 4)
			the_actor.StopCombatAlarm()
			the_actor.Activate(Game.GetPlayer(), abDefaultProcessingOnly = true)
			in_dialogue = true
			SetCanIdle(True)
			SetCanChangeStates(True)
			OnDialogueStart()
		endif
	else
;		the_actor.SetRelationshipRank(Game.GetPlayer(), 4)
		in_dialogue = true
		SetCanIdle(True)
		SetCanChangeStates(True)
		OnDialogueStart()
	endif	
EndFunction

;### Traits ###

Int __aggression
Int Property aggression
	Int Function get()
		return __aggression
	EndFunction
	Function set(Int value)
		__aggression = value
		the_actor.SetAv("aggression", __aggression)
	EndFunction
EndProperty

Int __confidence
Int Property confidence
	Int Function get()
		return __confidence
	EndFunction
	Function set(Int value)
		__confidence = value
		the_actor.SetAv("confidence", __confidence)
	EndFunction
EndProperty

Int __assistance
Int Property assistance
	Int Function get()
		return __assistance
	EndFunction
	Function set(Int value)
		__assistance = value
		the_actor.SetAv("assistance", __assistance)
	EndFunction
EndProperty

Function UpdateActorAITraits()
	the_actor.SetAv("Aggression", aggression)
	the_actor.SetAv("Confidence", confidence)
	the_actor.SetAv("Assistance", assistance)
EndFunction

;### Combat Handling ###

Bool combat_allowed = false
Int combat_allowed_for = 0

Function UpdateUsingCOPackage()
	SetInFaction(PAHAAUseCOPackage, !(combat_allowed || combat_allowed_for > 0))
	EvaluatePackage()
EndFunction

Function AllowCombat(Bool should_allow)
	combat_allowed = should_allow
	UpdateUsingCOPackage()
EndFunction

Function AllowCombatFor(int num_ticks)
	combat_allowed_for = num_ticks
	UpdateUsingCOPackage()
EndFunction

Function HandleCombatAllowedOnTick()
	if combat_allowed_for > 0
		combat_allowed_for -= 1
		if combat_allowed == 0
			UpdateUsingCOPackage()
		endif
	endif
EndFunction

;### Inventory and restraints ###

Bool __naked = false
Bool Property naked
	Bool Function get()
		return IsInFaction(PAHNaked)
	EndFunction
	Function set(Bool value)
		__naked = value
		SetInFaction(PAHNaked, __naked)
	EndFunction
EndProperty

Function SetNakedState()
	naked = the_actor.WornHasKeyword(PAHCountsAsNaked) || !(the_actor.WornHasKeyword(ArmorCuirass) || the_actor.WornHasKeyword(ClothingBody))
EndFunction

Function Strip()
	Form the_form
	Int i = the_actor.GetNumItems()
	while i > 0
		i -= 1
		the_form = the_actor.GetNthForm(i)
		if the_actor.IsEquipped(the_form) && !the_form.HasKeyword(PAHRestraint) && !the_form.HasKeyword(SexLabNoStrip)
			the_actor.UnequipItem(the_form)
		endif
	endwhile
	SetNakedState()
	ApplyEquipmentEffects()
EndFunction

Function EquipInventory(bool equip_collar = true)
	Form the_form
	Int i = the_actor.GetNumItems()
	while i > 0
		i -= 1
		the_form = the_actor.GetNthForm(i)
		if (the_form as Armor) != None && !the_form.HasKeyword(ArmorShield)
			the_actor.EquipItem(the_form, true)
		endif
		if the_form.HasKeyword(PAHRestraint)
			the_actor.EquipItem(the_form, true)
		endif
	endwhile

	SetNakedState()
	ApplyEquipmentEffects()
EndFunction

Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
	if akSourceContainer == Game.GetPlayer() as ObjectReference
		Bool bForceEquip = !toBackpack
		Keyword kwDeviousInventory = Keyword.GetKeyword("zad_InventoryDevice")
		If ((kwDeviousInventory != None) && (akBaseItem.HasKeyword(kwDeviousInventory)))
			If (!(PAH.DD_Collar != None && akBaseItem.HasKeyword(PAH.DD_Collar)))
				bForceEquip = False
			EndIf
		EndIf
		if (bForceEquip)
			Armor item_as_armor = akBaseItem as Armor
			if item_as_armor && item_as_armor.getFormID()
				Form item_already_in_slot = the_actor.GetWornForm(item_as_armor.GetSlotMask())
				if item_already_in_slot && item_already_in_slot.getFormID()
					if !item_already_in_slot.HasKeyword(PAHRestraint)
						the_actor.UnEquipItem(item_already_in_slot)
					else
						return
					endIf
				endif
				the_actor.EquipItem(akBaseItem, true)

			elseif akBaseItem && akBaseItem.GetFormId() && (akBaseItem as Weapon) && (akBaseItem as Weapon).GetFormID()
				the_actor.EquipItem(akBaseItem)
			endif
		endif
		SetNakedState()
		the_actor.QueueNiNodeUpdate()
		ApplyEquipmentEffects()
	endif
EndEvent

Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
	SetNakedState()
	ApplyEquipmentEffects()
EndEvent

;### Effective inventory ###

Bool __leashed = false
Bool Property leashed
	Bool Function Get()
		return __leashed
	EndFunction
	Function set(Bool value)
		if !__leashed && value
			OnLeashed()
		elseif __leashed && !value
			OnUnleashed()
		endif
		__leashed = value
		SetInFaction(PAHLeashed, __leashed)
		SetHasSpell(PAHLeashSpell, __leashed)
	EndFunction
EndProperty

ObjectReference __leash_point
ObjectReference	Property leash_point
	ObjectReference Function get()
		return __leash_point
	EndFunction
	Function set(ObjectReference value)
		PAHLeashPointScript old_leash_point = __leash_point as PAHLeashPointScript
		__leash_point = value
		if old_leash_point != None && !PAH.LeashPointInUse(old_leash_point)
			old_leash_point.Remove()
		endif
		OnLeashPointChanged()
	EndFunction
EndProperty

Function ApplyEquipmentEffects()
	OnLeashPointChanged()
EndFunction

Function OnLeashPointChanged()
	leashed = HasLeashEquipped() && leash_point != None
EndFunction

Bool Function HasLeashEquipped()
	return WornHasKeyword(PAHRestraintLeash)
EndFunction

Event OnLeashed()
	slave.OnLeashed()
	mind.OnLeashed()
EndEvent

Event OnUnleashed()
	slave.OnUnleashed()
	mind.OnUnleashed()
EndEvent

Event OnLeashEffect()
	slave.OnLeashEffect()
	mind.OnLeashEffect()
EndEvent

;### Informative getters

Bool Function PlayerIsFacing()
	float heading_angle = Game.GetPlayer().GetHeadingAngle(the_actor)
	return heading_angle < 80 && heading_angle > -80
EndFunction

Bool __is_moving
Bool Property is_moving
	Bool Function get()
		return __is_moving
	EndFunction
EndProperty

Float last_pos_x
Float last_pos_y
Function UpdateIsMovingOnTick()
	Float pos_x = the_actor.GetPositionX()
	Float pos_y = the_actor.GetPositionY()

	__is_moving = (pos_x - 10) > last_pos_x || (pos_x + 10) < last_pos_x || (pos_y - 10) > last_pos_y || (pos_y + 10) < last_pos_y

	last_pos_x = pos_x
	last_pos_y = pos_y
EndFunction

;### Actor interface ###

Bool Function IsAssigned()
	return the_actor != actor_stub
EndFunction

Function SetInFaction(Faction the_faction, Bool add_to)
	if add_to
		the_actor.AddToFaction(the_faction)
	else
		the_actor.RemoveFromFaction(the_faction)
	endif
EndFunction

Function AddToFaction(Faction the_faction)
	the_actor.AddToFaction(the_faction)
EndFunction

Function RemoveFromFaction(Faction the_faction)
	the_actor.RemoveFromFaction(the_faction)
EndFunction

Function SetFactionRank(Faction the_faction, Int rank)
	the_actor.SetFactionRank(the_faction, rank)
EndFunction

Bool Function IsInFaction(Faction the_faction)
	return the_actor.IsInFaction(the_faction)
EndFunction

Function SetRelationshipRank(Actor with_who, Int rank)
	the_actor.SetRelationshipRank(with_who, rank)
EndFunction

Int Function GetRelationshipRank(Actor with_who)
	return the_actor.GetRelationshipRank(with_who)
EndFunction

Int Function GetFactionRank(Faction the_faction)
	return the_actor.GetFactionRank(the_faction)
EndFunction

Function SetHasSpell(Spell the_spell, Bool add_to)
	if add_to
		the_actor.AddSpell(the_spell)
	else
		the_actor.RemoveSpell(the_spell)
	endif
EndFunction

Function AddSpell(Spell the_spell)
	the_actor.AddSpell(the_spell)
EndFunction

Function RemoveSpell(Spell the_spell)
	the_actor.RemoveSpell(the_spell)
EndFunction

Function EvaluatePackage()
	the_actor.EvaluatePackage()
EndFunction

Function IgnoreFriendlyHits(Bool should_ignore = true)
	the_actor.IgnoreFriendlyHits(should_ignore)
EndFunction

Function SetNotShowOnStealthMeter(Bool should_not_show = true)
	the_actor.SetNotShowOnStealthMeter(should_not_show)
EndFunction

Bool toBackpack	= false
Function OpenBackpack()
	openInventory(true)
EndFunction

Function OpenInventory(bool _toBackpack = false)
	toBackpack = _toBackpack
	the_actor.OpenInventory(true)
EndFunction

Function EquipItem(Form the_form, Bool block_uneqip = false)
	the_actor.EquipItem(the_actor, block_uneqip)
EndFunction

Function UnequipAll()
	the_actor.UnequipAll()
EndFunction

Function UnequipItem(Form the_form)
	the_actor.UnequipItem(the_form)
EndFunction

Int Function GetNumItems()
	return the_actor.GetNumItems()
EndFunction

Form Function GetNthForm(int i)
	return the_actor.GetNthForm(i)
EndFunction

Bool Function IsEquipped(Form the_item)
	return the_actor.IsEquipped(the_item)
EndFunction

Bool Function WornHasKeyword(Keyword the_keyword)
	return the_actor.WornHasKeyword(the_keyword)
EndFunction

Form Function GetWornForm(int slotmask)
	return the_actor.GetWornForm(slotmask)
EndFunction

Function StopCombat()
	the_actor.StopCombat()
EndFunction

Function StopCombatAlarm()
	the_actor.StopCombatAlarm()
EndFunction

VoiceType Function GetVoiceType()
	return the_actor.GetVoiceType()
EndFunction

Float Function GetDistance(ObjectReference other)
	return the_actor.GetDistance(other)
EndFunction

Float Function GetAv(String actor_value)
	return the_actor.GetAv(actor_value)
EndFunction

Float Function GetBaseAV(String actor_value)
	return the_actor.getBaseAV(actor_value)
EndFunction

Function RestoreAv(String actor_value, Float ammount)
	the_actor.RestoreAv(actor_value, ammount)
EndFunction

Bool Function IsInCell(Cell _cell)
	return the_actor.getParentCell() == _cell
EndFunction

Bool Function HasKeyword(Keyword _key)
	return the_actor.HasKeyword(_key)
EndFunction

Bool Function IsHostileToActor(Actor akAggressor)
	return the_actor.IsHostileToActor(akAggressor)
EndFunction

String Function GetDisplayName()
	return the_actor.GetDisplayName()
EndFunction

Int Function getItemCount(Form akItem)
	return the_actor.getItemCount(akItem)
EndFunction

Int Function getSex()
	return the_actor.GetActorBase().GetSex()
EndFunction

;### Utility ###

Float function SecondsToGameHours(Float seconds)
	return seconds / 180
EndFunction

;### RSN Added ###
Bool bDisableIdles = False
Bool bDisableStateChange = False
Bool bEnableMoodChange = true

Bool Function CanIdle()
    Bool bCanIdle = !bDisableIdles
 
    If (bCanIdle)
        Keyword ZazKeywordForBoundWrists = Keyword.GetKeyword("zbfEffectWrist")
        Keyword kwDeviousBoundArms = Keyword.GetKeyword("zad_DeviousArmbinder")
 
        If ((ZazKeywordForBoundWrists != None) && (the_actor.WornHasKeyword(ZazKeywordForBoundWrists)))
            bCanIdle = False
        ElseIf ((kwDeviousBoundArms != None) && (the_actor.WornHasKeyword(kwDeviousBoundArms)))
            bCanIdle = False
	ElseIf (the_actor.IsInFaction(PAHPosing))
		bCanIdle = False
        EndIf
    EndIf

    Return bCanIdle
EndFunction

Function SetCanIdle(Bool bEnabled)
	bDisableIdles = !bEnabled
EndFunction

Bool Function CanChangeStates()
	Return !bDisableStateChange
EndFunction

Function SetCanChangeStates(Bool bEnabled)
	bDisableStateChange = !bEnabled
EndFunction

Bool Function CanChangeMood()
	return bEnableMoodChange
EndFunction

Function setCanChangeMood(bool value)
	bEnableMoodChange = value
EndFunction
