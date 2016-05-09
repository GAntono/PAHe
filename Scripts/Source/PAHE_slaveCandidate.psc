Scriptname PAHE_slaveCandidate extends ReferenceAlias

PAHCore Property PAH Auto
Actor Property player Auto

float preHitHealth
Actor candidate
int ticks

Function Filled()
	ticks = 0
	candidate = (GetReference() As Actor)
	preHitHealth = candidate.getAV("Health")
;	If candidate.IsInCombat() 
;		GoToState("InCombat")
;	ElseIf !Game.GetPlayer().IsDetectedBy(candidate)
;		GoToState("Unaware")
;	Else
		GoToState("Aware")
;	Endif
EndFunction

Event OnUpdate()
	If !player
		player = Game.GetPlayer()
	EndIf
	ticks += 1
	UpdateState()
EndEvent

Event UpdateState()
EndEvent

Function ChangeState(String _state)
	ticks = 0
	GotoState(_state)
EndFunction

State InCombat
	Event OnBeginState()
		RegisterForSingleUpdate(2)
	EndEvent
	Event UpdateState()
		clear()
	EndEvent
	Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)
		Float healthDmg = preHitHealth - candidate.GetAv("Health")
		If (healthDmg >= candidate.GetAV("Health") / 10 && !abHitBlocked) || candidate.GetAv("Health") < 0
			ChangeState("Defeated")
		Else
			preHitHealth = candidate.getAV("Health")
		EndIf
	EndEvent
EndState

State Unaware
	Event OnBeginState()
		RegisterForSingleUpdateGameTime(300)
	EndEvent
	Event UpdateState()
		clear()
	EndEvent
	Event OnHit(ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked)
		Float healthDmg = preHitHealth - candidate.GetAv("Health")
	EndEvent
EndState

State Aware
	Event OnBeginState()
		RegisterForSingleUpdate(2)
	EndEvent
	Event UpdateState()
		If candidate.IsInCombat()
			ChangeState("InCombat")
		ElseIf ticks < 150 && GetActorRef() && GetActorRef().Is3DLoaded()
			RegisterForSingleUpdate(2)
		Else
			clear()
		EndIf
	EndEvent
EndState

State Defeated
	Event OnBeginState()
		RegisterForSingleUpdate(2)
		candidate.StopCombatAlarm()
		If candidate.isOnMount()
			candidate.dismount()
		EndIf
		candidate.SetNoBleedoutRecovery(true)
		candidate.setDontMove(true)
		Debug.SendAnimationEvent(candidate, "BleedOutStart")
	EndEvent
	
	Event UpdateState()
		If ticks >= 150
			candidate.SetNoBleedoutRecovery(false)
			candidate.setDontMove(false)
			Debug.SendAnimationEvent(candidate, "BleedOutStop")
			If player.isDetectedBy(candidate)
				candidate.startCombat(player)
			EndIf
			Filled()
		ElseIf player.IsBleedingOut()
			OnUpdateGameTime()
		Else
			RegisterForSingleUpdate(2)
		EndIf
	EndEvent
EndState
