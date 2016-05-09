Scriptname PAHFellglowSlaveCampQuest extends PAHSlaveValueAnalysisQuestScript  Conditional

Actor Property actor_jerrek  Auto

ObjectReference Property PAHJerrekInspectSlaveStartLocation  Auto  
ObjectReference Property PAHJerrekSlaveStandForInspectionStartLocation  Auto
ObjectReference Property PAHSlaveNoSaleReturnPoint Auto

Scene Property PAHFSCInspectSlaveScene  Auto
Scene Property PAHFSCTakeRAToCell1Scene Auto

PAHCore Property PAH Auto

Faction Property PAHPlayerSlaveFaction Auto
Faction Property PAHSlaveFaction Auto
Faction Property PAHFellglowSlaveFaction Auto
Faction Property PAHFSCCage1Faction Auto

Form Property Gold001 Auto

ReferenceAlias Property Alias_slave_up_for_sale Auto
ReferenceAlias[] Property just_sold_slave_aliases Auto
ReferenceAlias[] Property sold_slave_aliases Auto

ReferenceAlias Property alias_door_guard_1 Auto
ReferenceAlias Property alias_door_guard_2 Auto

ReferenceAlias Property prs_cell_1_slave Auto
ReferenceAlias Property prs_cell_1_slaver Auto

Int Property sell_stage = 0 Auto Conditional
Int Property can_take_more_slaves = 1 Auto Conditional

Actor[] Property slavers Auto
ReferenceAlias[] Property scene_aliases Auto
ReferenceAlias[] Property recent_acquisition_aliases Auto

ObjectReference Property CorpseDumpingPoint Auto
ObjectReference Property Cage1DumpPoint Auto

ObjectReference Property map_marker Auto

Function SetSellStage(int _sell_stage)
	sell_stage = _sell_stage

	if sell_stage == 0
		EndGuardSellRoomDoorScene()
	elseif sell_stage == 10
		; Jerrek walking to start position
		actor_jerrek.EvaluatePackage()
	elseif sell_stage == 20
		StartGuardSellRoomDoorScene()
		; Jerrek waiting for player at start position.
	elseif sell_stage == 60
		; Slave being inspected.
		Calculate(Alias_slave_up_for_sale.GetActorRef())
		PAHFSCInspectSlaveScene.Start()
	elseif sell_stage == 70
		;Offer being made
	elseif sell_stage == 80
		;Offer Accepted
		Game.GetPlayer().AddItem(Gold001, ((self as Quest) as PAHSlaveValueAnalysisQuestScript).Value)

		Actor slave = Alias_slave_up_for_sale.GetActorRef()

		PAH.GetSlave(slave).Release()

		Alias_slave_up_for_sale.GetActorRef().RemoveFromFaction(PAHPlayerSlaveFaction)
		Alias_slave_up_for_sale.GetActorRef().AddToFaction(PAHSlaveFaction)
		Alias_slave_up_for_sale.GetActorRef().AddToFaction(PAHFellglowSlaveFaction)

		FillEmptyJustSoldAlias(slave)
		Alias_slave_up_for_sale.Clear()
		slave.EvaluatePackage()

		StartPrsCell1Scene()

		if can_take_more_slaves
			SetSellStage(100)
		else
			SetSellStage(0)
		endif
	elseif sell_stage == 85
		;Offer Rejected
		Actor slave = Alias_slave_up_for_sale.GetActorRef()
		Alias_slave_up_for_sale.Clear()
		PAH.GetSlave(slave).EquipInventory()
		PAH.GetSlave(slave).DisableAutomaticBehaviour(false)
		slave.PathToReference(PAHSlaveNoSaleReturnPoint, 0.5)

		SetSellStage(100)
	elseif sell_stage == 100
		;Anymore Slaves?
	endif
EndFunction


Function StripSlave()
	(PAH.GetSlaveAlias(Alias_slave_up_for_sale.GetActorRef()) as PAHActorAlias).Strip()
EndFunction

Function DressSlave()
	(PAH.GetSlaveAlias(Alias_slave_up_for_sale.GetActorRef()) as PAHActorAlias).EquipInventory()
EndFunction


ReferenceAlias Function FillEmptyJustSoldAlias(Actor slave)
	ReferenceAlias ref_alias = GetEmptyJustSoldAlias()
	if ref_alias
		ref_alias.ForceRefTo(slave)
	endif
	UpdateCanTakeMoreSlaves()
	return ref_alias
EndFunction

ReferenceAlias Function GetEmptyJustSoldAlias()
	int i = 0

	While i < just_sold_slave_aliases.length
		if just_sold_slave_aliases[i].GetRef() == None
			return just_sold_slave_aliases[i]
		endif
		i += 1
	EndWhile

	return None
EndFunction


ReferenceAlias Function FillSoldSlaveAlias(Actor slave)
	ReferenceAlias ref_alias = GetEmptySoldSlaveAlias()
	if ref_alias == None
		ref_alias = sold_slave_aliases[Utility.RandomInt(0, sold_slave_aliases.length - 1)]
		ref_alias.GetActorRef().MoveTo(CorpseDumpingPoint)
		ref_alias.GetActorRef().KillEssential()
		ref_alias.GetActorRef().EndDeferredKill()
	endif
	ref_alias.ForceRefTo(slave)
EndFunction


ReferenceAlias Function GetEmptySoldSlaveAlias()
	int i = 0

	While i < sold_slave_aliases.length
		if sold_slave_aliases[i].GetRef() == None
			return sold_slave_aliases[i]
		endif
		i += 1
	EndWhile

	return None
EndFunction

Function UpdateCanTakeMoreSlaves()
	bool no_room = GetEmptyJustSoldAlias() == None
	if no_room
		can_take_more_slaves = 0
	else
		can_take_more_slaves = 1
	endif
EndFunction

Function OnResetTriggerEnter()
	ReferenceAlias ra_alias
	Actor slave
	
	int i = recent_acquisition_aliases.length
	while i > 0
		i -= 1
		ra_alias = recent_acquisition_aliases[i]
		slave = ra_alias.GetActorRef()
		if  slave != None
			ra_alias.clear()
			FillSoldSlaveAlias(slave)
			slave.AddToFaction(PAHFSCCage1Faction)
			slave.MoveTo(Cage1DumpPoint)
		endif
	endwhile

	UpdateCanTakeMoreSlaves()
	SetSellStage(0)
EndFunction

Function StartPrsCell1Scene()
	if prs_cell_1_slave.GetActorRef() == None
		Actor slaver = alias_door_guard_1.GetActorRef()
		if slaver == None
			slaver = alias_door_guard_2.GetActorRef()
		endif
		if slaver == None
			slaver = GetFreeSlaver()
		endif
		if slaver
			ReferenceAlias ra_alias = GetFilledRecentAqusitionAlias()
			if ra_alias
				prs_cell_1_slave.ForceRefTo(ra_alias.GetActorRef())
				FillSoldSlaveAlias(ra_alias.GetActorRef())
				ra_alias.Clear()
				prs_cell_1_slaver.ForceRefTo(slaver)
				PAHFSCTakeRAToCell1Scene.Start()
				UpdateCanTakeMoreSlaves()
			endif
		endif
	endif
EndFunction


Function StartGuardSellRoomDoorScene()
	alias_door_guard_1.ForceRefTo(GetFreeSlaver())
	alias_door_guard_2.ForceRefTo(GetFreeSlaver())
EndFunction

Function EndGuardSellRoomDoorScene()
	alias_door_guard_1.Clear()
	alias_door_guard_2.Clear()
EndFunction


Actor Function GetFreeSlaver()
	Actor slaver
	slaver = slavers[Utility.RandomInt(0, slavers.length)]
	if IsFree(slaver)
		return slaver
	endif
	slaver = slavers[Utility.RandomInt(0, slavers.length)]
	if IsFree(slaver)
		return slaver
	endif
	slaver = slavers[Utility.RandomInt(0, slavers.length)]
	if IsFree(slaver)
		return slaver
	endif
	
	int i = slavers.length
	while i > 0
		i -= 1
		if IsFree(slavers[i])
			return slavers[i]
		endif
	endwhile

	return none
EndFunction

Bool Function IsFree(Actor slaver)
	int i = scene_aliases.length
	while i > 0
		i -= 1
		if scene_aliases[i].GetActorRef() == slaver
			return false
		endif
	endwhile
	return true
EndFunction


ReferenceAlias Function GetFilledRecentAqusitionAlias()
	int i = recent_acquisition_aliases.length
	while i > 0
		i -= 1
		if recent_acquisition_aliases[i].GetActorRef() != None
			return recent_acquisition_aliases[i]
		endif
	endwhile
	return None
EndFunction

Function ShowMapMarker()
	map_marker.AddToMap(false)
EndFunction

