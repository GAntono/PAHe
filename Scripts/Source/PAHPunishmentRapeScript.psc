Scriptname PAHPunishmentRapeScript extends Quest

PAHCore Property PAH Auto
SexLabFramework Property SexLab Auto
Actor Property PlayerRef Auto

Faction Property TrainSex Auto
Faction Property TrainOral Auto
Faction Property TrainVaginal Auto
Faction Property TrainAnal Auto
Faction Property PAHBETied Auto

Form[] Property victimForm Auto Hidden

Function punish(Actor _target, Actor _player, String _tag = "", bool _aggressive = false, String _tag2 = "")
										If PAH.enableDebug
											Debug.trace("[PAHESex] punish(" + _target + ", " + _player + ", " + _tag + ", " + _aggressive + ", " + _tag2 + ")")
										EndIf
	String supress = ""
	String tag = _tag
	bool aggressive = _aggressive || PAH.bAlwaysAggressive

	If _target.IsInFaction(PAHBETied)
		aggressive = true
		tag = tag + "Tied, Wrists, Armbinder, DomSub"
		supress = "SubSub"
	EndIf

	If(aggressive)
		tag = tag + ", Aggressive"
	EndIf

;	train(_target, _tag, aggressive)

	If _player.IsWeaponDrawn()
		_player.SheatheWeapon()
	EndIf

	sslThreadModel Model = SexLab.NewThread()
	bool animSet = false
	sslBaseAnimation[] anims = new sslBaseAnimation[1]
	actor[] activeActors = new actor[2]

	If _player.GetActorBase().GetSex() == 0					; male player always penetrates
										If PAH.enableDebug
											Debug.trace("[PAHESex] Male PC")
										EndIf
		Model.AddActor(_target, aggressive)
		Model.AddActor(_player, false)
		If _tag2 != ""
			tag = _tag + ", " + _tag2
		EndIf
		supress = supress + "Lesbian, FF"
	Else									; PC is not male -> PC is female
										If PAH.enableDebug
											Debug.trace("[PAHESex] Female PC")
										EndIf
		If _tag == "Oral"						; female player is licked
										If PAH.enableDebug
											Debug.trace("[PAHESex] Female Oral")
										EndIf
			Model.AddActor(_player, false)
			Model.AddActor(_target, aggressive)
			anims[0] = SexLab.GetAnimationByName("Zyn Licking")
			animSet = true
		ElseIf _tag == "Anal"
										If PAH.enableDebug
											Debug.trace("[PAHESex] Female Anal")
										EndIf
			If aggressive						; female player penetrates NPC
										If PAH.enableDebug
											Debug.trace("[PAHESex] Female Anal Aggressive")
										EndIf
				Model.AddActor(_target, aggressive)
				Model.AddActor(_player, false)
				tag = tag + ", fisting"
			Else
										If PAH.enableDebug
											Debug.trace("[PAHESex] Female Anal Consensual")
										EndIf
				Model.AddActor(_player, false)
				Model.AddActor(_target, aggressive)
				tag = tag + ", Doggy"
			EndIf
		ElseIf _tag == "Vaginal"
										If PAH.enableDebug
											Debug.trace("[PAHESex] Female Vaginal")
										EndIf
			If _target.GetLeveledActorBase().GetSex() == 0		;female player, male NPC
										If PAH.enableDebug
											Debug.trace("[PAHESex] Female Vaginal Male Slave")
										EndIf
				Model.AddActor(_player, false)			; female player uses cowgirl
				Model.AddActor(_target, aggressive)
				tag = tag + ", Cowgirl"
			ElseIf aggressive					; female player penetrates NPC
										If PAH.enableDebug
											Debug.trace("[PAHESex] Female Vaginal Female Slave")
										EndIf
				Model.AddActor(_target, aggressive)
				Model.AddActor(_player, false)
				tag = tag + ", Fisting"
			Else
										If PAH.enableDebug
											Debug.trace("[PAHESex] Female Lesbian")
										EndIf
				Model.AddActor(_target, aggressive)
				Model.AddActor(_player, false)
				tag = tag + ", Lesbian, FF"
			EndIf
		EndIf
	EndIf

	If !animSet
		anims = SexLab.GetAnimationsByTags(2, tag, supress)
	EndIf

	Model.DisableUndressAnimation(_target)

	Model.SetAnimations(anims)
	If aggressive
		RegisterForModEvent("AnimationEnd_PostRape", "PostRape")
		Model.SetHook("PostRape")
	Else
		RegisterForModEvent("AnimationEnd_PostFornicate", "PostFornicate")
		Model.SetHook("PostFornicate")
	EndIf

	PAHSlave slave = PAH.GetSlave(_target)
	If slave.GetReasonForPunishment() != ""
		slave.StartPunishment("sex")
		slave.EndPunishment()
	EndIf

	Model.StartThread()
EndFunction

Function unEquip(Actor _actor, bool _aggressive = false)
	If _aggressive
		victimForm = SexLab.StripActor(_actor, _actor)
	Else
		victimForm = SexLab.StripActor(_actor)
	EndIf
EndFunction

Function reEquip(Actor _actor, bool _aggressive = false)
	If victimForm.Length > 1
		If _aggressive
			SexLab.UnstripActor(_actor, victimForm, _actor)
		Else
			SexLab.UnstripActor(_actor, victimForm)
		EndIf
	EndIf
	PAHActorAlias slave_alias = PAH.getSlaveAlias(_actor) as PAHActorAlias
	slave_alias.EquipInventory()
	victimForm = new Form[1]
EndFunction

Function train(Actor _actor, String _tag, bool _aggressive)
	PAHSlave slave = PAH.GetSlave(_actor)
	float  multiplier = 1.0
	If _aggressive
		multiplier = 2.0
		int relRank = _actor.GetRelationShipRank(PlayerRef)
		_actor.SetRelationshipRank(PlayerRef, relRank - 1)
	EndIf
	
	If _tag == "Oral" || _tag == "oral"
		slave.trainOral(5 * multiplier)
	ElseIf _tag == "Vaginal" || _tag == "vaginal"
		slave.trainVaginal(5 * multiplier)
	ElseIf _tag == "Anal" || _tag == "anal"
		slave.trainAnal(5 * multiplier)
	Else
		MiscUtil.PrintConsole(_tag + "-training failed")
	EndIf
EndFunction

Event PostRape(string eventName, string argString, float argNum, form sender)
	Actor Victim = SexLab.HookVictim(argString)
	float random = Utility.RandomFloat()
	Victim.AllowPCDialogue(false)
	Victim.SetDontMove()
	String animIn = ""
	String animOut = ""
	If random < 0.17
										If PAH.enableDebug
											Debug.trace("[PAHESexScript]: PAHEEstrusTrauma")
										EndIf
		animIn = "PAHEEstrusTrauma"
		animOut = "PAHEEstrusTraumaUp"
	ElseIf random < 0.33
										If PAH.enableDebug
											Debug.trace("[PAHESexScript]: PAHETraumaEnter")
										EndIf
		animIn = "PAHETraumaEnter"
		animOut = "PAHETraumaExit"
	ElseIf random < 0.5
										If PAH.enableDebug
											Debug.trace("[PAHESexScript]: PAHEEstrusExhaustedFront")
										EndIf
		animIn = "PAHEEstrusExhaustedFront"
		animOut = "PAHEWounded02Exit"
	ElseIf random < 0.67
										If PAH.enableDebug
											Debug.trace("[PAHESexScript]: PAHEEstrusExhaustedBack")
										EndIf
		animIn = "PAHEEstrusExhaustedBack"
		animOut = "PAHEWounded02Exit"
	ElseIf random < 0.83
										If PAH.enableDebug
											Debug.trace("[PAHESexScript]: ZaZAPCSHFE3")
										EndIf
		animIn = "ZaZAPCSHFE3"
		animOut = "PAHEWounded02Exit"
	Else
										If PAH.enableDebug
											Debug.trace("[PAHESexScript]: IdleWounded_02")
										EndIf
		animIn = "IdleWounded_02"
		animOut = "PAHEWounded02Exit"
	EndIf
										If PAH.enableDebug
											Debug.trace("[PAHESexScript]: Starting postRape Animation; Timer: " + PAH.config.postRapeDelay)
										EndIf
	Debug.SendAnimationEvent(Victim, animIn)
	Utility.wait(2.5)
	Debug.SendAnimationEvent(Victim, animIn)
	Utility.wait(PAH.config.postRapeDelay as float)
	Debug.SendAnimationEvent(Victim, animOut)
	Utility.wait(2.5)

										If PAH.enableDebug
											Debug.trace("[PAHESexScript]: Stoping postRape Animation")
										EndIf
	Victim.AllowPCDialogue(true)
	Victim.SetDontMove(false)
	reEquip(Victim, true)
	Utility.wait(1.5)
	If Victim.IsInFaction(PAHBETied)
		PAH.GetSlave(victim).PlayTieUpAnimation()
	Else
		Debug.SendAnimationEvent(Victim, "IdleWipeBrow")
	EndIf
	UnregisterForModEvent("AnimationEnd_PostRape")
EndEvent	

Event PostFornicate(string eventName, string argString, float argNum, form sender)
	Actor Victim = SexLab.HookActors(argString)[0]
	If Victim == Game.GetPlayer()
		Victim = SexLab.HookActors(argString)[1]
	EndIf

	Utility.wait(1.0)
	reEquip(Victim, false)
	Utility.wait(1.5)
	UnregisterForModEvent("AnimationEnd_PostFornicate")
EndEvent
