Scriptname PAHDiag extends Quest  

PAHCore Property PAH Auto

PAHSlave Function GetSlave(Actor slave_actor)
	return PAH.GetSlave(slave_actor)
EndFunction

Function SetNextPunishmentReason(Actor slave_actor, String reason)
	PAH.GetSlave(slave_actor).SetNextPunishmentReason(reason)
EndFunction

Function OnInventoryDialogueComplete(Actor slave_actor)
	PAH.GetSlave(slave_actor).OnInventoryDialogueComplete()
EndFunction

Function UnblockDialogue(Actor slave_actor)
	PAH.GetSlave(slave_actor).UnblockDialogue()
EndFunction

Function ClearAllSD(Actor slave_actor)
	PAH.GetSlave(slave_actor).ClearAllSD()
EndFunction

Function ClearEquipmentSD(Actor slave_actor)
	PAH.GetSlave(slave_actor).ClearEquipmentSD()
EndFunction

Function Follow(Actor slave_actor)
	removeRestraint(slave_actor)
	PAH.GetSlave(slave_actor).FollowPlayer()
EndFunction

Function Wait(Actor slave_actor)
	PAH.GetSlave(slave_actor).Wait()
EndFunction

Function Strip(Actor slave_actor)
	PAH.GetSlave(slave_actor).Strip()
EndFunction

Function OpenInventory(Actor slave_actor)
	PAH.GetSlave(slave_actor).OpenInventory()
EndFunction

Function EquipInventory(Actor slave_actor)
	PAH.GetSlave(slave_actor).EquipInventory()
EndFunction

Function restrain(Actor target, String pose, String strugglePose, Form cuff)
	Form _cuff = cuff
	If cuff == PAH.CuffsLeather
		_cuff = Game.GetFormFromFile(0x800E4, "Skyrim.esm") as Form
	EndIf
	If _cuff != PAH.CuffsRope
		If target.GetItemCount(_cuff) >= 1
			target.removeItem(_cuff, 1)
		Else
			Game.GetPlayer().removeItem(_cuff, 1)
		EndIf
	EndIf
	PAHSlave slave = PAH.GetSlave(target)
	slave.TieUp(cuff, Aggressor = Game.GetPlayer(), DoAnimation = true)
	slave.ChangeTiePose(pose, strugglePose)
EndFunction

Function changePose(Actor target, String pose)
	PAH.GetSlave(target).ChangeTiePose(pose, pose)
EndFunction

Function removeRestraint(Actor slave)
	PAH.GetSlave(slave).TieUp(None, Aggressor = Game.GetPlayer(), DoAnimation = true, Enter = false)
EndFunction

Function OpenBackpack(Actor slave_actor)
	PAH.GetSlave(slave_actor).OpenBackpack()
EndFunction

Function CommandDoCombat(Actor slave_actor)
	PAHSlave slave = PAH.GetSlave(slave_actor)
	slave.should_fight_for_player = true
	slave.fights_for_player = true
	If (slave.behaviour == "follow_player")
		slave_actor.SetPlayerTeammate()
	EndIf
EndFunction

Function CommandNoLongerDoCombat(Actor slave_actor)
	PAHSlave slave = PAH.GetSlave(slave_actor)
	slave.should_fight_for_player = false
	slave.fights_for_player = false
	if (slave_actor.IsPlayerTeammate())
		slave_actor.SetPlayerTeammate(false)
	endif
EndFunction

Function CommandToBeRespectful(Actor slave_actor)
	PAHSlave slave = PAH.GetSlave(slave_actor)
	slave.should_be_respectful = true
	slave.respectful = true
EndFunction

Function CommandNoLongerRespectful(Actor slave_actor)
	PAHSlave slave = PAH.GetSlave(slave_actor)
	slave.should_be_respectful = false
	slave.respectful = false
EndFunction

Function CommandToPose(Actor slave_actor)
	CommandNoLongerDoCombat(slave_actor)
	PAHSlave slave = PAH.GetSlave(slave_actor)
	slave.should_pose = true
EndFunction

Function SetPose(Actor slave_actor, int rank)
	PAHSlave slave = PAH.GetSlave(slave_actor) as PAHSlave
	slave.setPose(rank)
EndFunction

Function CommandNoLongerPose(Actor slave_actor)
	PAHSlave slave = PAH.GetSlave(slave_actor)
	slave.should_pose = false
EndFunction

Function TellOff(Actor slave_actor, string reason = "")
	PAH.GetSlave(slave_actor).TellOff(reason)
EndFunction

Function PlayerEquipWhip()
	PAH.PlayerEquipWeapon(PAH.PAHWhip)
EndFunction

Function SetAfraid(Actor slave_actor)
	PAH.GetSlave(slave_actor).SetAfraid()
EndFunction

Function Release(Actor slave_actor)
	PAH.GetSlave(slave_actor).releaseSlave()
EndFunction
