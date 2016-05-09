;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 1
Scriptname PAHE_RewardSexScr Extends TopicInfo Hidden

;BEGIN FRAGMENT Fragment_0
Function Fragment_0(ObjectReference akSpeakerRef)
Actor akSpeaker = akSpeakerRef as Actor
;BEGIN CODE
PAHSlave target = targetSlaveRef as PAHSlave
akSpeaker.pathtoreference(target.GetActorRef(), 0.5)
If target.actorWouldFuck(akSpeaker)
	(DialogueQuest as PAHPunishmentRapeScript).punish(targetSlaveRef.GetActorRef(), akSpeaker)
Else
	(DialogueQuest as PAHPunishmentRapeScript).punish(targetSlaveRef.GetActorRef(), akSpeaker, _aggressive = true)
EndIf
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Quest Property DialogueQuest Auto
ReferenceAlias Property targetSlaveRef Auto
