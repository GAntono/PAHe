;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 2
Scriptname PAHE_SexDialogueSCR Extends TopicInfo Hidden

;BEGIN FRAGMENT Fragment_1
Function Fragment_1(ObjectReference akSpeakerRef)
Actor akSpeaker = akSpeakerRef as Actor
;BEGIN CODE
(GetOwningQuest() as PAHPunishmentRapeScript).punish(akSpeaker, Game.getPlayer(), tag1, aggressive, tag2)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

String Property tag1  Auto  
String Property tag2  Auto  
Bool Property aggressive  Auto  
