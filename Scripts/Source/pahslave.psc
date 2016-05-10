Scriptname PAHSlave extends ReferenceAlias
Import Utility

;### Constants ###
PAHCore Property PAH Auto
ReferenceAlias Property pah_stub Auto	Hidden
ReferenceAlias Property ReleaseMarker  Auto	Hidden

Faction Property PlayerFaction Auto
Faction Property PAHPlayerSlaveFaction Auto

Faction Property PAHBEFollowing Auto
Faction Property PAHBEWaiting Auto
Faction Property PAHBEFleeingAndCowering Auto
Faction Property PAHBERunningAway Auto
Faction Property PAHBEWaitingAtLeashPoint Auto
Faction Property PAHBETied Auto
Faction Property PAHBECalm Auto

Faction Property PAHSubmission Auto
Faction Property PAHTrainCombat Auto
Faction Property PAHTrainAnger Auto
Faction Property PAHTrainRespect Auto
Faction Property PAHTrainPose Auto

Faction Property PAHShouldBeRespectful Auto
Faction Property PAHShouldFightForPlayer Auto
Faction Property PAHShouldPose Auto

Faction Property PAHRespectful Auto
Faction Property PAHPosing Auto

Faction Property PAHSDMadeNaked Auto
Faction Property PAHSDClothedFromNaked Auto
Faction Property PAHSDArmorAdded Auto
Faction Property PAHSDWeaponAdded Auto
Faction Property PAHSDWeaponRemoved Auto
Faction Property PAHSDRestraintAdded Auto
Faction Property PAHSDRestraintRemoved Auto
Faction Property PAHSDFailedToFight Auto
Faction Property PAHSDFailedToPose Auto

Keyword Property PAHRestraint Auto
Keyword Property PAHPaingiver Auto

Package Property DoNothing Auto

Spell Property PAHLeashToSpell Auto
Message Property slaveName Auto

String name

;### Properties ###
PAHActorAlias __actor_alias
PAHActorAlias Property actor_alias
	PAHActorAlias Function get()
		if manual_control_mode
			UnregisterForModEvent(GetID() + "PAHEUpdateStrength")
			return pah_stub as PAHActorAlias
		endif

		if __actor_alias == None
			__actor_alias = (self as ReferenceAlias) as PAHActorAlias
			if __actor_alias == None
				return pah_stub as PAHActorAlias
			endif
		endif
		return __actor_alias
	EndFunction
EndProperty

PAHSlaveMind __mind
PAHSlaveMind Property mind
	PAHSlaveMind Function get()
		if __mind == None
			__mind = (self as ReferenceAlias) as PAHSlaveMind
			if __mind == None
				return pah_stub as PAHSlaveMind
			endif
		endif
		return __mind
	EndFunction
EndProperty

;Actor Property backpack_mule Auto	Hidden
Bool manual_control_mode = false

Function DisableAutomaticBehaviour(Bool value = true)
	if value
		EndBehaviour()
		actor_alias.StandStill()
	endif
	manual_control_mode = value
	if !value
		StartBehaviour()
	endif
EndFunction

; ### Setup and teardown ###

Event OnBootstrap(string eventName = "", string strArg = "", float numArg = 0.0, Form sender = None)
	UnregisterForModEvent("PAHBootstrap")
	if GetActorRef() != None
		AfterAssign()
	endif
EndEvent

Event AfterAssign()
										If PAH.enableDebug
											debug.trace("[PAHESlave] After Assign")
										EndIf
	__actor_alias = (self as ReferenceAlias) as PAHActorAlias
	__mind = None
	manual_control_mode = false
	actor_alias.AddToFaction(PAHPlayerSlaveFaction)
	actor_alias.AddToFaction(PlayerFaction)
	actor_alias.AddToFaction(PAH.dunPrisonerFaction)
	actor_alias.AddToFaction(PAH.WINeverFillAliasesFaction)
	If PAH.DLC1ThrallFaction != None
		actor_alias.AddToFaction(PAH.DLC1ThrallFaction)
	EndIf
	actor_alias.IgnoreFriendlyHits(true)
	actor_alias.SetNotShowOnStealthMeter(true)
	actor_alias.StopCombat()
	actor_alias.AllowCombat(false)
	actor_alias.allow_dialogue_in_combat = true

	submission = actor_alias.GetFactionRank(PAHSubmission)
	combat_training = actor_alias.GetFactionRank(PAHTrainCombat)
	anger_training = actor_alias.GetFactionRank(PAHTrainAnger)
	respect_training = actor_alias.GetFactionRank(PAHTrainRespect)
	pose_training = actor_alias.GetFactionRank(PAHTrainPose)
	should_be_respectful = actor_alias.IsInFaction(PAHShouldBeRespectful)
	should_fight_for_player = actor_alias.IsInFaction(PAHShouldFightForPlayer)
	sex_training = actor_alias.GetFactionRank(PAH.PAHTrainSex)
	oral_training = actor_alias.GetFactionRank(PAH.PAHTrainOral)
	vaginal_training = actor_alias.GetFactionRank(PAH.PAHTrainVaginal)
	anal_training = actor_alias.GetFactionRank(PAH.PAHTrainAnal)
	fear_training = actor_alias.GetFactionRank(PAH.PAHTrainFear)
;	setDisplayName(getActorRef().getDisplayName())
	
	ticks_since_last_punished = 0

	SetInitialBehaviour()
	OnUpdateGameTime()
										If PAH.enableDebug
											debug.trace("[PAHESlave] After Assign: " + self + " is " + GetActorRef())
										EndIf
EndEvent

Event BeforeClear()
	UnregisterForModEvent(GetID() + "PAHEUpdateStrength")
	__actor_alias = None
	__mind = None
EndEvent

Function Release()
	Actor self_ref = GetActorRef()
	If self_ref.WornHasKeyword(PAHRestraint)
		self_ref.removeItem(Game.GetFormFromFile(0x00046D72, "paradise_halls.esm") As Armor, akOtherContainer = Game.GetPlayer())
		self_ref.removeItem(Game.GetFormFromFile(0x00049326, "paradise_halls.esm") As Armor, akOtherContainer = Game.GetPlayer())
		self_ref.removeItem(Game.GetFormFromFile(0x0000BF0E, "paradise_halls.esm") As Armor, akOtherContainer = Game.GetPlayer())
	EndIf
	PAH.RemoveSlave(self)
EndFunction

Event OnLoad()
	registerForWhistle()
	actor_alias.IgnoreFriendlyHits(true)
	actor_alias.SetNotShowOnStealthMeter(true)
	actor_alias.StopCombat()
EndEvent

; ### Events ###

Event OnUpdate()
	If actor_alias && actor_alias != pah_stub
		Regen()
		TestShouldHaveFought()
		HandlePunishmentOnUpdate()
		BehaviourOnUpdate()
		ClearSDOnTick()
		PlayIdlesOnTick()
	EndIf
EndEvent

Event OnUpdateGameTime()
	SetPrehitStats()
EndEvent

Float prehit_health = 100.0
Float prehit_magicka = 100.0
Float prehit_stamina = 100.0

Function SetPrehitStats()
	prehit_health = actor_alias.GetAv("Health")
EndFunction

Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, \
  bool abBashAttack, bool abHitBlocked)
	Float health_damage = prehit_health - actor_alias.GetAv("Health")
	SetPrehitStats()
	If GetActorRef().IsInFaction(PAHBETied) && struggle
		TrainPose(0.75)
		struggle = false
		PlayTieUpAnimation()
	EndIf

	if akAggressor == Game.GetPlayer() && health_damage > 0
		HandlePunishmentOnHit()
	else
		If (akAggressor as Actor) && (akAggressor as Actor).IsPlayerTeammate()
;			Actor aggro = akAggressor as Actor
			If actor_alias.IsHostileToActor(akAggressor as Actor)
				actor_alias.StopCombatAlarm()
			EndIf
			actor_alias.IgnoreFriendlyHits(true)
		EndIf
		actor_alias.AllowCombatFor(10)
	endif
EndEvent

Event OnLeashEffect()
	WaitAtLeashPoint()
EndEvent

Event OnLeashed()
	WaitAtLeashPoint()
EndEvent

Event OnUnLeashed()
	FollowPlayer()
EndEvent

Event OnToldOff(string reason)
	If reason == "running_away" && behaviour == "run_away"
		FollowPlayer()
	ElseIf reason == "not_respectful"
		respectful = true
	EndIf
EndEvent

Event OnStartPunishment(String type, string reason)
	if reason == "running_away" && behaviour == "run_away"
		FollowPlayer()
	elseif reason == "not_respectful"
		respectful = true
	endif
EndEvent

Event OnEndPunishment(String type, Float severity, string reason = "")
EndEvent

Event OnGainLOS(Actor akViewer, ObjectReference akTarget)
EndEvent

; ### Behaviour Handling ###
String __behaviour = ""
String Property behaviour	Hidden
	String Function get()
		return __behaviour
	EndFunction
	Function set(String value)
		If actor_alias.CanChangeStates()
			__behaviour = value
			EndBehaviour()
			GoToState(__behaviour)
			StartBehaviour()
			actor_alias.EvaluatePackage()
		EndIf
	EndFunction
EndProperty

Function StartBehaviour()
EndFunction

Function EndBehaviour()
EndFunction

Function BehaviourOnUpdate()
EndFunction

Function SetInitialBehaviour()
	if actor_alias.IsInFaction(PAHBEFollowing)
		behaviour = "follow_player"
	elseif actor_alias.IsInFaction(PAHBEWaiting)
		behaviour = "wait"
	elseIf  actor_alias.IsInFaction(PAHBETied)
		cuffs = findCuffs()
		behaviour = "tied"
	else
		behaviour = "follow_player"
	endif
EndFunction

;### Behaviour Definition

Function PlayIdlesOnTick()
	If (actor_alias.CanIdle())
		if !actor_alias.is_moving && RandomFloat() < 0.05 && actor_alias.naked
			if RandomFloat() < 0.5
				actor_alias.WarmArms()
			elseif RandomFloat() < 0.5
				actor_alias.CrossArms()
			elseif RandomFloat() < 0.5
				actor_alias.LookAroundNervously()
	;		else
	;			actor_alias.coverSelf()
			endif
		endif
	EndIf
EndFunction

Function FollowPlayer()
	behaviour = "follow_player"
EndFunction

State follow_player
	Function StartBehaviour()
		actor_alias.AddToFaction(PAHBEFollowing)
		actor_alias.Follow(Game.GetPlayer())
		if(should_fight_for_player)
			actor_alias.GetActorRef().SetPlayerTeammate()
		endif
	EndFunction

	Function EndBehaviour()
		actor_alias.RemoveFromFaction(PAHBEFollowing)
		if actor_alias.GetActorRef().IsPlayerTeammate()
			actor_alias.GetActorRef().SetPlayerTeammate(false)
		endif
	EndFunction
EndState

Function Wait()
	behaviour = "wait"
EndFunction

State wait
	Function StartBehaviour()
		actor_alias.AddToFaction(PAHBEWaiting)
		actor_alias.StandStill()
	EndFunction

	Function BehaviourOnUpdate()
		If mind.StartMovingByFormula()
			WaitSandbox()
		EndIf
	EndFunction

	Function EndBehaviour()
		actor_alias.RemoveFromFaction(PAHBEWaiting)
	EndFunction
EndState

Function WaitSandbox()
	behaviour = "wait_sandbox"
EndFunction

State wait_sandbox
	Function StartBehaviour()
		actor_alias.AddToFaction(PAHBEWaiting)
		actor_alias.Sandbox()
		RegisterForSingleLOSGain(GetActorRef(), Game.GetPlayer())
	EndFunction
	
	Event OnGainLOS(Actor akViewer, ObjectReference akTarget)
		If randomFloat() < (submission / 100)
			TrainSubmission(0.5)
			wait()
		EndIf
	EndEvent

	Function EndBehaviour()
		UnregisterForLOS(GetActorRef(), Game.GetPlayer())
		actor_alias.RemoveFromFaction(PAHBEWaiting)
	EndFunction
EndState

Function FleeAndCower()
	behaviour = "flee_and_cower"
EndFunction

State flee_and_cower
	Function StartBehaviour()
		actor_alias.AddToFaction(PAHBEFleeingAndCowering)
		actor_alias.FleeFrom(Game.GetPlayer())
	EndFunction

	Function BehaviourOnUpdate()
		if actor_alias.current_action == "flee_from"
			if actor_alias.GetDistance(Game.GetPlayer()) > 500 && RandomFloat() < 0.7
				actor_alias.Cower()
			endif
		else
			if actor_alias.GetDistance(Game.GetPlayer()) < 150 && RandomFloat() < 0.5
				actor_alias.FleeFrom(Game.GetPlayer())
			endif
		endif
	EndFunction

	Function EndBehaviour()
		actor_alias.RemoveFromFaction(PAHBEFleeingAndCowering)
	EndFunction
EndState

Function RunAway()
	if CanRunAway()
		behaviour = "run_away"
	endif
EndFunction

State run_away
	Function StartBehaviour()
		next_punishment_reason = "running_away"
		actor_alias.AddToFaction(PAHBERunningAway)
		actor_alias.FleeFrom(Game.GetPlayer())
	EndFunction

	Function OnUpdateGameTime()
		if CanRunAway() && !PAH.IsTogetherWith(GetActorRef(), Game.GetPlayer())
			actor_alias.RemoveFromGame()
		endif
	EndFunction

	Function EndBehaviour()
		actor_alias.RemoveFromFaction(PAHBERunningAway)
	EndFunction

	Event OnLeashed()
	EndEvent
EndState

Bool Function CanRunAway()
	If PAH.Config.leashToggle
		return !(actor_alias.leashed || behaviour == "tied" || actor_alias.HasKeyword(PAH.defeatActive) || actor_alias.HasLeashEquipped())
	Else
		return !(actor_alias.leashed || behaviour == "tied" || actor_alias.HasKeyword(PAH.defeatActive))
	EndIf
EndFunction

Function WaitAtLeashPoint()
	behaviour = "wait_at_leash_point"
EndFunction

State wait_at_leash_point
	Function StartBehaviour()
		actor_alias.AddToFaction(PAHBEWaitingAtLeashPoint)
		actor_alias.SandboxAtLeash()
	EndFunction

	Function OnUpdateGameTime()
	EndFunction

	Function EndBehaviour()
		actor_alias.RemoveFromFaction(PAHBEWaitingAtLeashPoint)
	EndFunction
EndState

Function Tied()
	behaviour = "tied"
EndFunction

bool struggle
bool breakingRestraint
bool isIronCuffs
String pose
String strugglePose
String currentPose
Form cuffs
float gameTime

State tied
	Function StartBehaviour()
		If actor_alias.current_action == "follow"
			actor_alias.standStill()
		EndIf
		GetActorRef().AddToFaction(PAHBETied)
		GetActorRef().AddItem(cuffs, 1)
		GetActorRef().EquipItem(cuffs)
		ChangeTiePose("PAHETieUpEnter")
		RegisterForAnimEvent()
		RegisterForSingleUpdateGameTime(0.5)
		gameTime = GetCurrentGameTime()
		actor_alias.SetCanChangeStates(false)
	EndFunction
	Function OnUpdateGameTime()
		If cuffs
			If mind.StartMovingByFormula()
				RegisterForSingleLOSGain(GetActorRef(), Game.GetPlayer())
				If breakingRestraint
					TieUp(None, Enter = False)
					If !(canRunAway() && mind.RunAwayByFormula())
						waitSandbox()
					EndIf
				Else
					If mind.CanBreakRestraint(cuffs)
						breakingRestraint = true
					EndIf
					TrainSubmission(0.5)
					struggle = true
					PlayTieUpAnimation()
				EndIf
			Else
				UnregisterForLOS(GetActorRef(), Game.GetPlayer())
				TrainSubmission(0.5)
				TrainPose(0.5)
				struggle = false
				PlayTieUpAnimation()
			EndIf
	
			If (gameTime - GetCurrentGameTime()) * 24 >= 1
				gameTime = gameTime + (0.5 / 24)
				OnUpdateGameTime()
			Else
				RegisterForSingleUpdateGameTime(0.5)
			EndIf
		Else
			If randomFloat() > 0.5
				FollowPlayer()
			else
				wait()
			EndIf
		EndIf
	EndFunction
	Event OnAnimationEvent(ObjectReference akSource, string asEventName)
		Calm(GetActorRef())
		PlayTieUpAnimation()
	EndEvent
	Event OnLoad()
		GetActorRef().EquipItem(cuffs)
		Calm(GetActorRef())
		PlayTieUpAnimation()
	EndEvent
	
	Event OnGainLOS(Actor akViewer, ObjectReference akTarget)
		If randomFloat() < submission / 100
			TrainSubmission(0.5)
			struggle = false
			PlayTieUpAnimation()
		EndIf
	EndEvent

;	Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
;		If akBaseItem.HasKeyWordString("zbfWornDevice")
;			GetActorRef().EquipItem(akBaseItem, True)
;		Endif
;		PlayTieUpAnimation()
;	EndEvent
	Event OnObjectUnequipped(Form akBaseObject, ObjectReference akReference)
		If akBaseObject.HasKeyWordString("zbfWornDevice") && akBaseObject == cuffs
			EndBehaviour()
		EndIf
	EndEvent
	Function EndBehaviour()
		UnregisterForLOS(GetActorRef(), Game.GetPlayer())
		TieUp(None, Enter = False)
	EndFunction
EndState

Function PlayTieUpAnimation(Bool TieUp = True)
	If (GetActorRef().Is3DLoaded() && !GetActorRef().IsDead())
		If TieUp && !struggle
			Debug.SendAnimationEvent(GetActorRef(), Pose)
		elseIf TieUp
			Debug.SendAnimationEvent(GetActorRef(), strugglePose)
		Else
			Debug.SendAnimationEvent(GetActorRef(), "PAHETieUpExit")
		Endif
	Endif
EndFunction

Function ChangeTiePose(String ThePose, String TheStrugglePose = "")
	strugglePose = TheStrugglePose
	pose = ThePose
	bool perma = false
	If (Struggle && !Perma)
		currentPose = strugglePose
		StorageUtil.SetStringValue(GetActorRef(), "PAHEStateAnim", StrugglePose)
	Else
		currentPose = ThePose
		StorageUtil.SetStringValue(GetActorRef(), "PAHEStateAnim", ThePose)
	Endif
	PlayTieUpAnimation()
EndFunction

Function RegisterForAnimEvent(Bool On = True)
	If On
		RegisterForAnimationEvent(GetActorRef(), "staggerStop")
		RegisterForAnimationEvent(GetActorRef(), "GetUpEnd")
	Else
		UnregisterForAnimationEvent(GetActorRef(), "staggerStop")
		UnregisterForAnimationEvent(GetActorRef(), "GetUpEnd")
	Endif
EndFunction

Bool Function TieUp(Form cuff, Actor Aggressor = None, Bool DoAnimation = False, Bool UnCalm = True, Bool Enter = True)
	;/ Tie up a NPC, the duration can be specified, if not it will use the MCM setting
	the tying up animation can be disabled to make it instant, if so the aggressor need to be specified as well
	or this will be ignored. Untie the Target if Tied is False, do nothing if the Target isn't tied./;
	Actor target = GetActorRef()
	If Enter && cuff
		cuffs = cuff
		If cuffs == PAH.CuffsIron || cuffs == PAH.CuffsIronBrown || cuffs == PAH.CuffsSimpleBlack || cuffs == PAH.CuffsSimpleBrown || cuffs == PAH.WristIron || cuffs == PAH.AnkleIron
			isIronCuffs = true
		Else
			isIronCuffs = false
		EndIf
		If !Target.IsInFaction(PAHBETied)
			Calm(Target)
			Target.SetRestrained()
			Target.SetDontMove()
			StorageUtil.SetStringValue(Target, "PAHEState", "Tied")
			If (DoAnimation && Aggressor)
				aggressor.setDontMove()
				If (aggressor == Game.GetPlayer() && aggressor.IsWeaponDrawn())
					aggressor.SheatheWeapon()
					While aggressor.IsWeaponDrawn()
						Utility.Wait(0.5)
					EndWhile
				EndIf
				Debug.SendAnimationEvent(Aggressor, "PAHETyingUpAnim")
				tied()
				Utility.Wait(1.0)
				aggressor.setDontMove(false)
			Else
				tied()
			Endif
			Return True
		Elseif Target.IsInFaction(PAHBETied)
			Calm(Target)
		Endif
	Else
		If Target.IsInFaction(PAHBETied)
			If (DoAnimation && Aggressor)
				aggressor.SetLookAt(target)
				target.SetLookAt(aggressor)
				aggressor.setDontMove()
				If (aggressor == Game.GetPlayer() && aggressor.IsWeaponDrawn())
					aggressor.SheatheWeapon()
					While aggressor.IsWeaponDrawn()
						Utility.Wait(0.5)
					EndWhile
				EndIf
				If isIronCuffs
					Debug.SendAnimationEvent(Aggressor, "PAHETyingUpAnim")
				Else
					Debug.SendAnimationEvent(Aggressor, "BoundStandingCutNPC")
				EndIf
				Utility.wait(1.0)
				aggressor.setDontMove(false)
			Endif
			RegisterForAnimEvent(False)

			If Target.GetItemCount(cuffs) > 0
				If isIronCuffs
					If Aggressor
						Target.RemoveItem(cuffs, aiCount = 1, akOtherContainer = Aggressor)
					Else
						Target.UnequipItem(cuffs)
					EndIf
				Else
					Target.RemoveItem(cuffs)
				EndIf
			EndIf

			If UnCalm
				Debug.SendAnimationEvent(Target, "PAHETieUpExit")
				Calm(False)
			Endif

			Target.SetRestrained(False)
			Target.SetDontMove(False)
			breakingRestraint = false
			StorageUtil.UnsetStringValue(Target, "PAHEState")
			StorageUtil.UnsetStringValue(Target, "PAHEStateAnim")
			Target.RemoveFromFaction(PAHBETied)
			actor_alias.SetCanChangeStates(true)
			Return True
		Endif
	Endif
	Return False
EndFunction

Bool Function Calm(Bool Enter = True)
	Actor Target = GetActorRef()
	If Enter
		If !Target.IsInFaction(PAHBECalm)
			Target.AddToFaction(PAHBECalm)
			Target.StopCombat()
			Target.StopCombatAlarm()
			ActorUtil.AddPackageOverride(Target, DoNothing, 100, 1)
			Target.EvaluatePackage()
			Return True
		Else
			Target.StopCombatAlarm()
		Endif
	Else
		If Target.IsInFaction(PAHBECalm)
			Target.RemoveFromFaction(PAHBECalm)
			ActorUtil.RemovePackageOverride(Target, DoNothing)
			Target.EvaluatePackage()
			Return True
		Endif
	Endif
	Return False
EndFunction

Form Function findCuffs()
	If actor_alias.getItemCount(PAH.CuffsIronBrown) > 0
		return PAH.CuffsIronBrown
	ElseIf actor_alias.getItemCount(PAH.CuffsIron) > 0
		return PAH.CuffsIron
	ElseIf actor_alias.getItemCount(PAH.CuffsSimpleBrown) > 0
		return PAH.CuffsSimpleBrown
	ElseIf actor_alias.getItemCount(PAH.CuffsSimpleBlack) > 0
		return PAH.CuffsSimpleBlack
	ElseIf actor_alias.getItemCount(PAH.CuffsLeather) > 0
		return PAH.CuffsLeather
	ElseIf actor_alias.getItemCount(PAH.CuffsRope) > 0
		return PAH.CuffsRope
	ElseIf actor_alias.getItemCount(PAH.AnkleIron) > 0
		return PAH.AnkleIron
	ElseIf actor_alias.getItemCount(PAH.AnkleLeather) > 0
		return PAH.AnkleLeather
	ElseIf actor_alias.getItemCount(PAH.WristIron) > 0
		return PAH.WristIron
	ElseIf actor_alias.getItemCount(PAH.WristLeather) > 0
		return PAH.WristLeather
	Else
		return None
	EndIf
EndFunction

bool property bla auto Conditional

;### Orders ###
Bool __should_fight_for_player = False
Bool Property should_fight_for_player	Hidden
	Bool Function get()
		return __should_fight_for_player
	EndFunction
	Function set(Bool value)
		If value
			UpdateStrength()
			actor_alias.RemoveFromFaction(PAH.dunPrisonerFaction)
			RegisterForModEvent(GetID() + "PAHEUpdateStrength", "UpdateStrength")
		Else
			actor_alias.AddToFaction(PAH.dunPrisonerFaction)
			UnregisterForModEvent(GetID() + "PAHEUpdateStrength")
		EndIf
		__should_fight_for_player = value
		actor_alias.SetInFaction(PAHShouldFightForPlayer, __should_fight_for_player)
		registerForWhistle()
	EndFunction
EndProperty

Bool __should_be_respectful = False
Bool Property should_be_respectful	Hidden
	Bool Function get()
		return __should_be_respectful
	EndFunction
	Function set(Bool value)
		__should_be_respectful = value
		actor_alias.SetInFaction(PAHShouldBeRespectful, __should_be_respectful)
	EndFunction
EndProperty

Bool __should_pose = False
Bool Property should_pose	Hidden
	Bool Function get()
		return __should_pose
	EndFunction
	Function set(Bool value)
		If value != __should_pose
			__should_pose = value
			actor_alias.SetInFaction(PAHShouldPose, __should_pose)
		EndIf
	EndFunction
EndProperty

Function TestShouldHavePosed()
	If should_pose && !actor_alias.IsInFaction(PAHPosing)
		next_punishment_reason = "didnt_pose"
		AddSD(PAHSDFailedToPose, 60)
	EndIf
EndFunction

Function releaseSlave()
	Actor releasedSlave = actor_alias.the_actor
	Release()
	releasedSlave.RemoveFromAllFactions()
	releasedSlave.PathToReference(ReleaseMarker.GetReference(), 1)
	releasedSlave.DeleteWhenAble()
EndFunction

; ### Pose Handling ###
Bool __is_posing = False
Bool Property is_posing	Hidden
	Bool Function get()
		return __is_posing
	EndFunction
	Function set(Bool value)
		If value != __is_posing
			__is_posing = value
			actor_alias.SetInFaction(PAHPosing, __is_posing)
		EndIf
	EndFunction
EndProperty

State pose
	Function StartBehaviour()
		actor_alias.AddToFaction(PAHPosing)
	EndFunction
	Function EndBehaviour()
		actor_alias.RemoveFromFaction(PAHPosing)
	EndFunction
EndState

Function SetPose(int rank)
	behaviour = "pose"
	actor_alias.SetFactionRank(PAHPosing, rank)
	actor_alias.evaluatePackage()
EndFunction

; ### Combat Handling ###
Bool __fights_for_player = False
Bool Property fights_for_player	Hidden
	Bool Function get()
		return __fights_for_player
	EndFunction
	Function set(Bool value)
		If value != __fights_for_player
			__fights_for_player = value
			actor_alias.AllowCombat(__fights_for_player)
		EndIf
	EndFunction
EndProperty

bool bHasFought

Function TestShouldHaveFought()
	If Game.GetPlayer().IsInCombat() && should_fight_for_player
		If !fights_for_player
			next_punishment_reason = "didnt_fight"
			AddSD(PAHSDFailedToFight, 60)
		Else
			bHasFought = true
		EndIf
	ElseIf bHasFought
		TrainCombat(1)
		bHasFought = false
	EndIf
EndFunction

Event PAHEWhistle(string eventName, string strArg, float numArg, Form sender)
	If GetRef().GetDistance(Game.GetPlayer()) <= 2048
		If eventName == "PAHEWhistle_wait"
			wait()
		ElseIf eventName == "PAHEWhistle_follow"
			followPlayer()
		EndIf
	EndIf
EndEvent

Event UpdateStrength(string eventName = "", string strArg = "", float numArg = 0.0, Form sender = None)
	Actor _player = Game.GetPlayer()
	Actor _slave = GetActorRef()

	ActorBase original_base = PAH.GetValidActorBase(_slave)
	Actor clone
	ActorBase clone_base

	int encounterLevel = (_player.getLevel() * actor_alias.getFactionRank(PAHTrainCombat) as float / 100) as Int
	EncounterZone level_band_zone = PAH.getEncounterZone(encounterLevel)

	int tries = 0
	While tries < 50
		Int LevelMod = (actor_alias.getFactionRank(PAHTrainCombat) / 33) as Int
		clone = PAH.CloneMarker.PlaceActorAtMe(original_base, LevelMod, level_band_zone)
		If clone
			If clone.getLevel() > actor_alias.vLevel || LevelMod > actor_alias.lvlMod
				_slave.setAV("Health", PAH.getMax(actor_alias.GetBaseAV("Health"), clone.GetBaseAV("Health")))
				_slave.setAV("Magicka", PAH.getMax(actor_alias.GetBaseAV("Magicka"), clone.GetBaseAV("Magicka")))
				_slave.setAV("Stamina", PAH.getMax(actor_alias.GetBaseAV("Stamina"), clone.GetBaseAV("Stamina")))

				_slave.setAV("OneHanded", PAH.getMax(actor_alias.GetBaseAV("OneHanded"), clone.GetBaseAV("OneHanded")))
				_slave.setAV("TwoHanded", PAH.getMax(actor_alias.GetBaseAV("TwoHanded"), clone.GetBaseAV("TwoHanded")))
				_slave.setAV("Block", PAH.getMax(actor_alias.GetBaseAV("Block"), clone.GetBaseAV("Block")))
				_slave.setAV("HeavyArmor", PAH.getMax(actor_alias.GetBaseAV("HeavyArmor"), clone.GetBaseAV("HeavyArmor")))
				_slave.setAV("LightArmor", PAH.getMax(actor_alias.GetBaseAV("LightArmor"), clone.GetBaseAV("LightArmor")))
				_slave.setAV("Sneak", PAH.getMax(actor_alias.GetBaseAV("Sneak"), clone.GetBaseAV("Sneak")))
				_slave.setAV("Alteration", PAH.getMax(actor_alias.GetBaseAV("Alteration"), clone.GetBaseAV("Alteration")))
				_slave.setAV("Conjuration", PAH.getMax(actor_alias.GetBaseAV("Conjuration"), clone.GetBaseAV("Conjuration")))
				_slave.setAV("Destruction", PAH.getMax(actor_alias.GetBaseAV("Destruction"), clone.GetBaseAV("Destruction")))
				_slave.setAV("Illusion", PAH.getMax(actor_alias.GetBaseAV("Illusion"), clone.GetBaseAV("Illusion")))
				_slave.setAV("Restoration", PAH.getMax(actor_alias.GetBaseAV("Restoration"), clone.GetBaseAV("Restoration")))

				actor_alias.vLevel = clone.getLevel()
				actor_alias.lvlMod = LevelMod
			EndIf
			tries = 50
			clone.Delete()
		ElseIf !clone && PAH.enableDebug
			debug.trace("[PAHESlave] Update Strength " + _slave.GetDisplayName() + ": No clone")
		EndIf
		tries += 1
	EndWhile
EndEvent

; ### Attributed ###
Function Regen()
	actor_alias.RestoreAv("Health", 3.0)
EndFunction

; ### Dialogue ###
Bool __respectful = False
Bool Property respectful	Hidden
	Bool Function get()
		return __respectful
	EndFunction
	Function set(Bool value)
		If value != __respectful
			__respectful = value
			actor_alias.SetInFaction(PAHRespectful, __respectful)
		EndIf
	EndFunction
EndProperty

int ticks_for_special_dialogue = 0
Function AddSD(Faction dialogue_faction, int duration = 10)
	if ticks_for_special_dialogue < duration
		ticks_for_special_dialogue = duration
	endif
	actor_alias.AddToFaction(dialogue_faction)
EndFunction

Function ClearAllSD()
	ticks_for_special_dialogue = 0
	actor_alias.RemoveFromFaction(PAHSDArmorAdded)
	actor_alias.RemoveFromFaction(PAHSDClothedFromNaked)
	actor_alias.RemoveFromFaction(PAHSDMadeNaked)
	actor_alias.RemoveFromFaction(PAHSDRestraintAdded)
	actor_alias.RemoveFromFaction(PAHSDRestraintRemoved)
	actor_alias.RemoveFromFaction(PAHSDWeaponAdded)
	actor_alias.RemoveFromFaction(PAHSDWeaponRemoved)
	actor_alias.RemoveFromFaction(PAHSDFailedToFight)
	actor_alias.RemoveFromFaction(PAHSDFailedToPose)
EndFunction

Function ClearEquipmentSD()
	actor_alias.RemoveFromFaction(PAHSDArmorAdded)
	actor_alias.RemoveFromFaction(PAHSDClothedFromNaked)
	actor_alias.RemoveFromFaction(PAHSDMadeNaked)
	actor_alias.RemoveFromFaction(PAHSDRestraintAdded)
	actor_alias.RemoveFromFaction(PAHSDRestraintRemoved)
	actor_alias.RemoveFromFaction(PAHSDWeaponAdded)
	actor_alias.RemoveFromFaction(PAHSDWeaponRemoved)
EndFunction

Function ClearSpecialDialogue(Faction dialogue_faction)
	actor_alias.RemoveFromFaction(dialogue_faction)
EndFunction

Function ClearSDOnTick()
	if ticks_for_special_dialogue > 0
		ticks_for_special_dialogue -= 1
		if ticks_for_special_dialogue == 0
			ClearAllSD()
		endif
	endif
EndFunction

; ### Punishment ###
String next_punishment_reason = ""
String punishment_reason = ""
String punishment_type = ""
Bool end_punishment_on_next_tick = false

Bool Property punishment_active = false Auto	Hidden
Int Property ticks_since_last_punished = 1000 Auto	Hidden

Function HandlePunishmentOnUpdate()
	if punishment_active
		ticks_since_last_punished = 0
		if punishment_type == "pain"
			HandlePainPunishmentOnUpdate()
		endif
	else
		ticks_since_last_punished += 1
	endif
EndFunction

Function HandlePunishmentOnHit()
	if !punishment_active
		StartPunishment("pain")
	endif

	end_punishment_on_next_tick = false
	mind.OnExperiencePain()
EndFunction

Function StartPunishment(String type = "pain", string reason = "")
	if reason == ""
		punishment_reason = GetReasonForPunishment()
	else
		punishment_reason = reason
	endif
	next_punishment_reason = ""
	punishment_type = type
	punishment_active = true
	ticks_since_last_punished = 0

	OnStartPunishment(type, punishment_reason)
	mind.OnStartPunishment(type, punishment_reason)
EndFunction

Function EndPunishment()
	punishment_active = false

	Float severity = 0.0

	if punishment_type == "pain"
		severity = PAH.Config.severity
	ElseIf punishment_type == "sex"
		severity = PAH.Config.severity / 2
	endif

	TrainAfterPunished(punishment_type, severity, punishment_reason)
	OnEndPunishment(punishment_type, severity, punishment_reason)
	mind.OnEndPunishment(punishment_type, severity, punishment_reason)
EndFunction

String Function GetReasonForPunishment()
	if next_punishment_reason != ""
		return next_punishment_reason
	ElseIf behaviour == "run_away"
		return "running_away"
	ElseIf mind.mood == "angry"
		return "angry"
	ElseIf should_be_respectful && !respectful
		return "not_respectful"
	ElseIf should_pose && !is_posing
		return "didnt_pose"
	Else
		return ""
	endif
EndFunction

Function SetNextPunishmentReason(String reason)
	next_punishment_reason = reason
EndFunction

Function HandlePainPunishmentOnUpdate()
	if end_punishment_on_next_tick
		EndPunishment()
	else
		end_punishment_on_next_tick = true
	endif
EndFunction

Function TellOff(string reason = "")
	TrainAfterTellingOff(reason)
	OnToldOff(reason)
	mind.OnToldOff(reason)
EndFunction

; ### Training ###
Event handleSexEvent(Form TrackedForm, int tid)
	sslThreadController controller = PAH.SexLab.GetController(tid)
	sslBaseAnimation anim = controller.Animation
	
	While anim == None
		Utility.wait(1)
		anim = controller.Animation
	EndWhile

	int trainCount = 0
	bool bTrainAnal = false
	bool bTrainOral = false
	bool bTrainVaginal = false

	int multiplier = 1
	If (controller.GetVictim() == GetActorRef())
		multiplier = 2
	EndIf
	If anim.HasTag("Anal")
		trainCount += 1
		bTrainAnal = true
	EndIf
	If anim.HasTag("Oral")
		trainCount += 1
		bTrainOral = true
	EndIf
	If anim.HasTag("Vaginal")
		trainCount += 1
		bTrainVaginal = true
	EndIf

	If bTrainAnal
		trainAnal(5 * multiplier / trainCount)
	EndIf
	If bTrainOral
		trainOral(5 * multiplier / trainCount)
	EndIf
	If bTrainVaginal
		trainVaginal(5 * multiplier / trainCount)
	EndIf
EndEvent

Function registerSexEvent()
	PAH.SexLab.untrackActor(getActorRef(), "PAH" + getActorRef().GetFormID())
	UnregisterForModEvent("PAH" + getActorRef().GetFormID() + "_Added")

	PAH.SexLab.trackActor(getActorRef(), "PAH" + getActorRef().GetFormID())
	RegisterForModEvent("PAH" + getActorRef().GetFormID() + "_Added", "handleSexEvent")
EndFunction

Float __submission = 0.0
Float Property submission	Hidden
	Float Function get()
		return __submission
	EndFunction
	Function set(Float value)
		If __submission < PAH.Config.runAwayValue && value >= PAH.Config.runAwayValue
			PAH.tickSlaverRank()
		endIf
		__submission = value
		if __submission > 100
			__submission = 100
		elseif __submission < 0
			__submission = 0
		endif
		actor_alias.SetFactionRank(PAHSubmission, __submission as Int)
	EndFunction
EndProperty

Function TrainSubmission(Float base_ammount)
	Float multiplier = 0.1 + (0.9*(1-(submission/100)))
	submission += (base_ammount * multiplier)
EndFunction

Float __combatTraining = 0.0
int combatTrainingPlayerLevel = 0
Float Property combat_training	Hidden
	Float Function get()
		return __combatTraining
	EndFunction
	Function set(Float value)
		float initialTraining = __combatTraining
		__combatTraining = value
		If __combatTraining > 100
			__combatTraining = 100
		ElseIf __combatTraining < 0
			__combatTraining = 0
		EndIf
		actor_alias.SetFactionRank(PAHTrainCombat, __combatTraining as Int)

		actor_alias.aggression = 1
		actor_alias.assistance = 2
		
		If (initialTraining / 10) as Int < (__combatTraining / 10) as Int
			UpdateStrength()
		EndIf
		
		If __combatTraining >= 60
			actor_alias.confidence = 4
		ElseIf __combatTraining >= 40
			actor_alias.confidence = 3
		ElseIf __combatTraining >= 20
			actor_alias.confidence = 2
		Else
			actor_alias.confidence = 1
		EndIf
	EndFunction
EndProperty

Function TrainCombat(Float base_ammount)
	Float multiplier = 0.1 + (0.9*(1-(combat_training/100)))
	combat_training += (base_ammount * multiplier)
EndFunction

Float __anger_training = 0.0
Float Property anger_training	Hidden
	Float Function get()
		return __anger_training
	EndFunction
	Function set(Float value)
		__anger_training = value
		if __anger_training > 100
			__anger_training = 100
		elseif __anger_training < 0
			__anger_training = 0
		endif
		actor_alias.SetFactionRank(PAHTrainAnger, __anger_training as Int)
	EndFunction
EndProperty

Function TrainAnger(Float base_ammount)
	Float multiplier = (1-(anger_training/100))
	anger_training += (base_ammount * multiplier)
EndFunction

Float __respect_training = 0.0
Float Property respect_training	Hidden
	Float Function get()
		return __respect_training
	EndFunction
	Function set(Float value)
		__respect_training = value
		if __respect_training > 100
			__respect_training = 100
		elseif __respect_training < 0
			__respect_training = 0
		endif
		actor_alias.SetFactionRank(PAHTrainRespect, __respect_training as Int)
	EndFunction
EndProperty

Function TrainRespect(Float base_ammount)
	Float multiplier = 0.1 + (0.9*(1-(respect_training/100)))
	respect_training += (base_ammount * multiplier)
EndFunction

Float __pose_training = 0.0
Float Property pose_training	Hidden
	Float Function get()
		return __pose_training
	EndFunction
	Function set(Float value)
		__pose_training = value
		if __pose_training > 100
			__pose_training = 100
		elseif __pose_training < 0
			__pose_training = 0
		endif
		actor_alias.SetFactionRank(PAHTrainPose, __pose_training as Int)
	EndFunction
EndProperty

Function TrainPose(Float base_ammount)
	Float multiplier = 0.1 + (0.9*(1-(pose_training/100)))
	pose_training += (base_ammount * multiplier)
EndFunction

Float __oral_training = 0.0
Float Property oral_training	Hidden
	Float Function get()
		return __oral_training
	EndFunction
	Function set(Float value)
		__oral_training = value
		if __oral_training > 100
			__oral_training = 100
		elseif __oral_training < 0
			__oral_training = 0
		endif
		actor_alias.SetFactionRank(PAH.PAHTrainOral, __oral_training as Int)
	EndFunction
EndProperty

Function TrainOral(Float base_amount)
	Float multiplier = 0.1 + (0.9*(1-(oral_training/100)))
	oral_training += (base_amount * multiplier)
	sex_training = 0.0
EndFunction

Float __vaginal_training = 0.0
Float Property vaginal_training	Hidden
	Float Function get()
		return __vaginal_training
	EndFunction
	Function set(Float value)
		__vaginal_training = value
		if __vaginal_training > 100
			__vaginal_training = 100
		elseif __vaginal_training < 0
			__vaginal_training = 0
		endif
		actor_alias.SetFactionRank(PAH.PAHTrainVaginal, __vaginal_training as Int)
	EndFunction
EndProperty

Function TrainVaginal(Float base_amount)
	Float multiplier = 0.1 + (0.9*(1-(vaginal_training/100)))
	vaginal_training += (base_amount * multiplier)
	sex_training = 0.0
EndFunction

Float __anal_training = 0.0
Float Property anal_training	Hidden
	Float Function get()
		return __anal_training
	EndFunction
	Function set(Float value)
		__anal_training = value
		if __anal_training > 100
			__anal_training = 100
		elseif __anal_training < 0
			__anal_training = 0
		endif
		actor_alias.SetFactionRank(PAH.PAHTrainAnal, __anal_training as Int)
	EndFunction
EndProperty

Function TrainAnal(Float base_amount)
	Float multiplier = 0.1 + (0.9*(1-(anal_training/100)))
	anal_training += (base_amount * multiplier)
	sex_training = 0.0
EndFunction

Float __sex_training = 0.0
Float Property sex_training	Hidden
	Float Function get()
		return __sex_training
	EndFunction
	Function set(Float value)
		If actor_alias.GetSex() == 0
			__sex_training = (oral_training + anal_training) / 2
		Else
			__sex_training = (oral_training + vaginal_training + anal_training) / 3
		EndIf

		if __sex_training > 100
			__sex_training = 100
		elseif __sex_training < 0
			__sex_training = 0
		endif
		actor_alias.SetFactionRank(PAH.PAHTrainSex, __sex_training as Int)
	EndFunction
EndProperty

Function TrainSex(Float base_amount)
	sex_training = 0
EndFunction

Float __fear_training = 0.0
Float Property fear_training	Hidden
	Float Function Get()
		return __fear_training
	EndFunction
	Function Set(Float value)
		if value > 100
			__fear_training = 100
		ElseIf value < 0
			__fear_training = 0
		Else
			__fear_training = value
		EndIf
		actor_alias.SetFactionRank(PAH.PAHTrainFear, __fear_training as Int)
	EndFunction
EndProperty

Function TrainFear(Float base_ammount)
	Float multiplier = 0.1 + (0.9*(1-(fear_training/100)))
	fear_training += (base_ammount * multiplier)
EndFunction

Function TrainAfterPunished(string type, Float severity, String reason = "")
	if reason == "angry"
		TrainSubmission(severity * 0.15)
		TrainAnger(severity * 0.2)

	elseif reason == "not_respectful"
		TrainSubmission(severity * 0.15)
		TrainRespect(severity * 0.4)

	elseif reason == "running_away"
		TrainSubmission(severity * 0.2)

	elseif reason == "didnt_fight"
		TrainSubmission(severity * 0.15)
		TrainCombat(severity * 0.3)

	ElseIf reason == "didnt_pose"
		TrainSubmission(severity * 0.15)
		TrainPose(severity * 0.2)

	ElseIf reason == "no_sex"
		TrainSubmission(severity * 0.15)
		TrainOral(severity * 0.1)
		TrainVaginal(severity * 0.1)
		TrainAnal(severity * 0.1)

	Else
		TrainSubmission(severity * 0.05)
	EndIf

	If type == "pain"
		TrainFear(severity * 0.03)
	EndIf

	actor_alias.setRelationshipRank(Game.GetPlayer(), actor_alias.getRelationshipRank(Game.GetPlayer()) - 1)
EndFunction

Function TrainAfterTellingOff(string reason)
	if reason != ""
		TrainSubmission(10)

		if reason == "not_respectful"
			TrainRespect(20)

		ElseIf reason == "didnt_fight"
			TrainCombat(20)

		ElseIf reason == "didnt_pose"
			TrainPose(20)

		ElseIf reason == "no_sex"
			TrainSex(20)

		EndIf
	EndIf
EndFunction

; ### Inventory behaviour ###
Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
	if akSourceContainer == Game.GetPlayer() as ObjectReference
		Armor item_as_armor = akBaseItem as Armor
		if item_as_armor != None
			Form item_already_in_slot = actor_alias.GetWornForm(item_as_armor.GetSlotMask())
			if item_already_in_slot != None && item_already_in_slot.HasKeyword(PAHRestraint)
				return
			endif
			if akBaseItem.HasKeyword(PAHRestraint)
				restraint_added = true
				actor_alias.setRelationshipRank(Game.GetPlayer(), actor_alias.getRelationshipRank(Game.GetPlayer()) - 1)
			else
				armor_added = true
			endif

		elseif akBaseItem as Weapon != None
			weapon_added = true
		endif
	endif
EndEvent

Event OnItemRemoved(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
	if akBaseItem.HasKeyword(PAHRestraint)
		restraint_removed = true
	elseif (akBaseItem as Armor) != None
		armor_removed = true
	elseif (akBaseItem as Weapon) != None
		weapon_removed = true
	endif
EndEvent

Bool was_naked = false
Bool armor_added = false
Bool armor_removed = false
Bool weapon_added = false
Bool weapon_removed = false
Bool restraint_added = false
Bool restraint_removed = false

Function OnInventoryDialogueComplete()
	if actor_alias.naked && !was_naked
		AddSD(PAHSDMadeNaked)
	elseif !actor_alias.naked && was_naked
		AddSD(PAHSDClothedFromNaked)
	endif

	if armor_added
		AddSD(PAHSDArmorAdded)
	endif

	if weapon_added
		AddSD(PAHSDWeaponAdded)
	elseif weapon_removed
		AddSD(PAHSDWeaponRemoved)
	endif

	if restraint_added && !restraint_removed
		AddSD(PAHSDRestraintAdded)
	elseif restraint_removed && !restraint_added
		AddSD(PAHSDRestraintRemoved)
	endif

	was_naked = false
	armor_added = false
	armor_removed = false
	weapon_added = false
	weapon_removed = false
	restraint_added = false
	restraint_removed = false
EndFunction

Function OpenBackpack()
	actor_alias.OpenBackpack()
EndFunction

;### Mind interface ###
Function SetAfraid()
	mind.mood = "afraid"
EndFunction

;### Actor Alias interface ###
Function Strip()
	actor_alias.Strip()
EndFunction

Function EquipInventory()
	actor_alias.EquipInventory()
EndFunction

Function OpenInventory()
	actor_alias.OpenInventory()
EndFunction

Function UnblockDialogue()
	actor_alias.UnblockDialogue()
EndFunction

;### Utility ###
int Function actorWouldFuck(Actor target)
	Actor thisActor = getActorRef()
	If PAH.SexLab.IsStraight(thisActor) && target.getActorBase().getSex() == thisActor.getActorBase().getSex()
		return -1
	ElseIf PAH.SexLab.IsGay(thisActor) && target.getActorBase().getSex() != thisActor.getActorBase().getSex()
		return -1
	EndIf

	int attraction = 55
	If PAH.attractionInstalled
		attraction = (PAH.attractionInstalled as SLAttractionMainScript).GetActorAttraction(thisActor, target)
	EndIf
	int arousal = 50
	If PAH.arousedInstalled
		arousal = (PAH.arousedInstalled as slaFrameworkScr).GetActorArousal(thisActor)
	EndIf
	
	int value = attraction * 2 + arousal
	If attraction * 2 + arousal >= 150
		return attraction * 2 + arousal
	EndIf
	return -1
EndFunction

Float Function InverseDecayByY(Float y_value, Float half_life = 60.0, Float max_val = 1.0, Float min_val = 0.0)
	return max_val-(((max_val - min_val) / ((y_value/half_life) + 1)) + min_val)
EndFunction

Function registerForWhistle()
	If should_fight_for_player
		RegisterForModEvent("PAHEWhistle_follow", "PAHEWhistle")
		RegisterForModEvent("PAHEWhistle_wait", "PAHEWhistle")
	Else
		UnregisterForModEvent("PAHEWhistle_follow")
		UnregisterForModEvent("PAHEWhistle_wait")
	EndIf
EndFunction

Function resetSlave()
	String beh = behaviour
	behaviour = "follow_player"
	EndBehaviour()
	behaviour = "wait"
	EndBehaviour()
	behaviour = "wait_sandbox"
	EndBehaviour()
	behaviour = "flee_and_cower"
	EndBehaviour()
	behaviour = "run_away"
	EndBehaviour()
	behaviour = "wait_at_leash_point"
	EndBehaviour()
	behaviour = "tied"
	EndBehaviour()

	behaviour = beh
	Debug.Notification(actor_alias.getDisplayName() + " reset")
EndFunction

Function setDisplayName(string newName)
	name = newName
	GetActorRef().setDisplayName(name)
	slaveName.setName(name)
EndFunction

String Function getName()
	return name
EndFunction
