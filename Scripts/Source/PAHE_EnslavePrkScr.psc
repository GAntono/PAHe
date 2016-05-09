;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 6
Scriptname PAHE_EnslavePrkScr Extends Perk Hidden

;BEGIN FRAGMENT Fragment_1
Function Fragment_1(ObjectReference akTargetRef, Actor akActor)
;BEGIN CODE
If sendAssault
(akTargetRef as Actor).sendassaultalarm()
Utility.wait(1)
EndIf
PAH.Capture(akTargetRef as Actor)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

PAHCore Property PAH Auto

Bool Property sendAssault  Auto  
