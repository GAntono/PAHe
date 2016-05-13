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

Actor target

String animIn
String animOut

Function punish(Actor _target, Actor _player, String _tag = "", bool _aggressive = false, String _tag2 = "")
										If PAH.enableDebug
											Debug.trace("[PAHESex] punish(" + _target + ", " + _player + ", " + _tag + ", " + _aggressive + ", " + _tag2 + ")")
										EndIf
	target = _target
	String supress = ""
	animIn = ""
	animOut = ""
	String startAnim
	String tag = _tag
	bool aggressive = _aggressive || PAH.bAlwaysAggressive

	sslThreadModel Model = SexLab.NewThread()

	If target.IsInFaction(PAHBETied)
		If target.GetAV("Morality") < 2
			startAnim = "ZapWriPose07"
		Else
			startAnim = "ZapWriPose06"
		EndIf
;		animIn = ""
;		animOut = ""
		aggressive = true
		tag = tag + ",Wrists"
		supress = "SubSub"
	EndIf

	If _player.IsWeaponDrawn()
		aggressive = true
		_player.SheatheWeapon()
	EndIf

	If(aggressive)
		If(tag=="")
			tag = "Aggressive"
		Else
			tag = tag + ",Aggressive"
		EndIf
	EndIf

	train(_target, _tag, aggressive)

	bool animSet = false
	sslBaseAnimation[] anims
	actor[] activeActors = new actor[2]

;	If _player.GetActorBase().GetSex() == 0					; male player always penetrates
	If SexLab.GetGender(_player) == 0					; male player always penetrates
										If PAH.enableDebug
											Debug.trace("[PAHESex] Male PC")
										EndIf
		Model.AddActor(_target, IsVictim = aggressive)
		Model.AddActor(_player, IsVictim = false)
		If _tag2 != ""
			tag = _tag + "," + _tag2
		EndIf
		If supress==""
			supress = "Lesbian,FF"
		Else
			supress = supress + ",Lesbian,FF"
		EndIf
;	Else									; PC is not male -> PC is female
	ElseIf SexLab.GetGender(_player) == 1					; PC is not male -> PC is female
										If PAH.enableDebug
											Debug.trace("[PAHESex] Female PC")
										EndIf
		If _tag == "Oral"						; female player is licked
										If PAH.enableDebug
											Debug.trace("[PAHESex] Female Oral")
										EndIf
			Model.AddActor(_player, IsVictim = false)
			Model.AddActor(_target, IsVictim = aggressive)
			anims = new sslBaseAnimation[3]
			anims[0] = SexLab.GetAnimationByName("Zyn Licking")
			anims[1] = SexLab.GetAnimationByName("MitosFaceFemdom")
			anims[1] = SexLab.GetAnimationByName("LeitoCunnilingus")
			animSet = true
		ElseIf _tag == "Anal"
										If PAH.enableDebug
											Debug.trace("[PAHESex] Female Anal")
										EndIf
			If aggressive						; female player penetrates NPC
										If PAH.enableDebug
											Debug.trace("[PAHESex] Female Anal Aggressive")
										EndIf
				Model.AddActor(_target, IsVictim = aggressive)
				Model.AddActor(_player, IsVictim = false)
				tag = tag + ",fisting"
			Else
										If PAH.enableDebug
											Debug.trace("[PAHESex] Female Anal Consensual")
										EndIf
				Model.AddActor(_player, IsVictim = false)
				Model.AddActor(_target, IsVictim = aggressive)
				tag = tag + ",DoggyStyle"
			EndIf
		ElseIf _tag == "Vaginal"
										If PAH.enableDebug
											Debug.trace("[PAHESex] Female Vaginal")
										EndIf
			If _target.GetLeveledActorBase().GetSex() == 0		;female player, male NPC
;			If SexLab.GetGender(_target) == 0			;female player, male NPC
										If PAH.enableDebug
											Debug.trace("[PAHESex] Female Vaginal Male Slave")
										EndIf
				Model.AddActor(_player, IsVictim = false)			; female player uses cowgirl
				Model.AddActor(_target, IsVictim = aggressive)
				tag = tag + ",Cowgirl"
			ElseIf aggressive					; female player penetrates NPC
										If PAH.enableDebug
											Debug.trace("[PAHESex] Female Vaginal Female Slave")
										EndIf
				Model.AddActor(_target, IsVictim = aggressive)
				Model.AddActor(_player, IsVictim = false)
				tag = tag + ",Fisting"
			Else
										If PAH.enableDebug
											Debug.trace("[PAHESex] Female Lesbian")
										EndIf
				Model.AddActor(_target, IsVictim = aggressive)
				Model.AddActor(_player, IsVictim = false)
				tag = tag + ",Lesbian,FF"
			EndIf
		EndIf
	Else									; sexlab creature tagged
										If PAH.enableDebug
											Debug.trace("[PAHESex] creature PC detected")
										EndIf
	
	EndIf

	If !animSet
		anims = SexLab.GetAnimationsByTags(2, tag, supress)
	EndIf

	Model.DisableUndressAnimation(target)

	Model.SetAnimations(anims)

	If startAnim
										If PAH.enableDebug
											Debug.trace("[PAHESexScript]: " + startAnim)
										EndIf
		model.SetStartAnimationEvent(target, startAnim)
	EndIf
	
	If aggressive
		RegisterForModEvent("HookAnimationEnd_PostRape", "PostRape")
		Model.SetHook("PostRape")
		Model.DisableRedress(target)
										If PAH.enableDebug
											Debug.trace("[PAHESex] Setting endAnim")
										EndIf
		setEndAnim(Model, true)
	Else
		RegisterForModEvent("HookAnimationEnd_PostFornicate", "PostFornicate")
		Model.SetHook("PostFornicate")
;		setEndAnim()
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

Function setEndAnim(sslThreadModel model, bool aggressive = false)
	If animIn == ""
		float random = Utility.RandomFloat()
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
	EndIf
										If PAH.enableDebug
											MiscUtil.PrintConsole("[PAHESexScript]: " + animIn)
										EndIf
	model.setEndAnimationEvent(target, animIn)
EndFunction

Function train(Actor _actor, String _tag, bool _aggressive)
	PAHSlave slave = PAH.GetSlave(_actor)
	float  multiplier = 1.0
	If _aggressive
		multiplier = 2.0
		int relRank = _actor.GetRelationShipRank(PlayerRef)
		_actor.SetRelationshipRank(PlayerRef, relRank - 1)
	Else
		int relRank = _actor.GetRelationShipRank(PlayerRef)
		_actor.SetRelationshipRank(PlayerRef, relRank + 1)
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

Event PostRape(int tid, bool hasPlayer)
	sslThreadController controller = SexLab.GetController(tid)
	Actor Victim = controller.VictimRef

	Victim.AllowPCDialogue(false)
	Victim.SetDontMove()

	Utility.wait(2.5)
	Debug.SendAnimationEvent(Victim, animIn)
	Utility.wait(PAH.config.postRapeDelay as float)
	Debug.SendAnimationEvent(Victim, animOut)
	Utility.wait(2.5)

	Victim.AllowPCDialogue(true)
	Victim.SetDontMove(false)
	reEquip(Victim, true)
	Utility.wait(1.5)
	If Victim.IsInFaction(PAHBETied)
		PAH.GetSlave(Victim).PlayTieUpAnimation()
	Else
		Debug.SendAnimationEvent(Victim, "IdleWipeBrow")
	EndIf
	UnregisterForModEvent("AnimationEnd_PostRape")
EndEvent

Event PostFornicate(int tid, bool hasPlayer)
	sslThreadController controller = SexLab.GetController(tid)
	Actor Victim = controller.Positions[0]
	If Victim == Game.GetPlayer()
		Victim = controller.Positions[0]
	EndIf

	Utility.wait(1.0)
	reEquip(Victim, false)
	Utility.wait(1.5)
	UnregisterForModEvent("AnimationEnd_PostFornicate")
EndEvent
