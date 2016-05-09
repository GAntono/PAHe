Scriptname PAHE_PinewoodScr extends ObjectReference

SexLabFramework Property SexLab Auto
PAHCore Property PAH Auto
Actor[] Property bandits Auto
ObjectReference Property marker Auto

Faction Property banditFriend Auto
Faction Property PAHECanBeCaptured Auto
Faction Property PAHSlaveFaction Auto

Actor refIngrid
bool running
bool isAnimating
sslThreadModel model

Event OnLoad()
	Utility.wait(0.1)
	If !running
		doThings()
	EndIf
EndEvent

Function doThings()
	If !running
		running = true
		Utility.wait(1)

		Actor clone

		float[] coords = new float[3]

		If !clone
			refIngrid = (self as ObjectReference) as Actor

			coords[0] = refIngrid.GetPositionX()
			coords[1] = refIngrid.GetPositionY()
			coords[2] = refIngrid.GetPositionZ()

			refIngrid.removeAllItems()

			clone = PAH.clone(refIngrid)
		EndIf

		If clone
			Debug.notification("Clone: " + clone)
			MiscUtil.PrintConsole("Clone: " + clone)
			clone.addToFaction(banditFriend)
			clone.addToFaction(PAHECanBeCaptured)

			clone.MoveTo(refIngrid)
			clone.SetPosition(coords[0], coords[1], coords[2])

			refIngrid.MoveTo(PAH.CloneMarker)
			refIngrid.KillEssential()

			int actorCount = 0
			int i = 0
			While (i < bandits.Length)
				If bandits[i].GetLeveledActorBase().GetSex() == 0
					actorCount += 1
				EndIf
				i += 1
			EndWhile

			i = 0
			while (i < bandits.Length)
				while isAnimating
					Utility.wait(1)
				EndWhile

				If !bandits[i].isDead() && bandits[i].GetLeveledActorBase().GetSex() == 0
					model = SexLab.NewThread()
					model.addActor(clone, IsVictim = true)
					model.DisableUndressAnimation(clone)
					model.SetStartAnimationEvent(clone, "IdleWounded_02")
					model.setEndAnimationEvent(clone, "IdleWounded_02")
					isAnimating = true

					While !(bandits[i].is3DLoaded() && clone.is3DLoaded())
						Utility.wait(1)
					EndWhile
					model.addActor(bandits[i])

					sslBaseAnimation[] anims
					If actorCount > 1
						float random = Utility.RandomFloat()
						If random > 0.75
							addActor(model, 1)
							anims = Sexlab.GetAnimationsByDefault(Males = 2, Females = 1, IsAggressive = true, UsingBed = false, RestrictAggressive = true)
						ElseIf actorCount >= 3 && random > 0.625
							addActor(model, 2)
							anims = Sexlab.GetAnimationsByDefault(Males = 3, Females = 1, IsAggressive = true, UsingBed = false, RestrictAggressive = true)
						EndIf
					EndIf
	
					If !anims
						anims = Sexlab.GetAnimationsByDefault(Males = 1, Females = 1, IsAggressive = true, UsingBed = false, RestrictAggressive = true)
					EndIf

	
					model.SetAnimations(anims)
					RegisterForModEvent("HookAnimationEnd_postPinRape", "postRape")
					model.setHook("postPinRape")
					model.centerOnObject(marker)
					bandits[i].pathToReference(clone, 0.2)
					model.StartThread()
				EndIf
				i += 1
				If i == bandits.Length
					i = 0
				EndIf
			EndWhile
		EndIf
	EndIf
EndFunction

Event postRape(int tid, bool hasPlayer)
	UnregisterForModEvent("HookAnimationEnd_postPinRape")

	sslThreadController controller = SexLab.GetController(tid)
	Actor Victim = controller.VictimRef

	Victim.AllowPCDialogue(false)
	Victim.SetDontMove()

	Utility.wait(10)
	isAnimating = false
EndEvent

Function addActor(sslThreadModel _model, int actors)
	int added = 0
	While (added < actors)
		int index = Utility.randomInt(0, bandits.Length - 1)
		If !bandits[index].isDead() && bandits[index].GetLeveledActorBase().GetSex() == 0 && !_model.hasActor(bandits[index])
			_model.addActor(bandits[index])
			added += 1
		EndIf
	EndWhile
EndFunction
