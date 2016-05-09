;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 1
Scriptname PAHE_TIE_SCR Extends TopicInfo Hidden

;BEGIN FRAGMENT Fragment_0
Function Fragment_0(ObjectReference akSpeakerRef)
Actor akSpeaker = akSpeakerRef as Actor
;BEGIN CODE
String str
If akSpeaker.GetAV("Morality") < 2
	str = "07"
Else	
	str = "06"
EndIf
(GetOwningQuest() as PAHDiag).restrain(akSpeaker, "ZapWriPose" + str, "ZapWriStruggle" + str, cuff)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

Armor Property cuff  Auto  
