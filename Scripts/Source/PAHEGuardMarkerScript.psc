Scriptname PAHEGuardMarkerScript extends ReferenceAlias

Float Property X Auto
Float Property Y Auto
Float Property Z Auto
Float Property ROT_X Auto
Float Property ROT_Y Auto
Float Property ROT_Z Auto

ObjectReference Property targetDoor Auto

Bool Property pale Auto
Bool Property falkreath Auto
Bool Property hjaalmarch Auto

Bool Property custom_1 Auto Hidden
Bool Property custom_2 Auto Hidden
Bool Property custom_3 Auto Hidden

ObjectReference thisMarker

Bool Function OnQuestStart(bool HFInstalled)
	thisMarker = GetRef()
	If thisMarker
		If Pale || Falkreath || Hjaalmarch
			If HFInstalled
				If Pale
					targetDoor = Game.GetFormFromFile(0x00010DDF, "HearthFires.esm") as ObjectReference
				ElseIf Falkreath && HFInstalled
					targetDoor = Game.GetFormFromFile(0x00003221, "HearthFires.esm") as ObjectReference
				ElseIf Hjaalmarch && HFInstalled
					targetDoor = Game.GetFormFromFile(0x0000B852, "HearthFires.esm") as ObjectReference
				EndIf
			Else
				return false
			EndIf
		EndIf
		
		thisMarker.MoveTo(targetDoor)
		thisMarker.SetPosition(X, Y, Z)
		thisMarker.SetAngle(ROT_X, ROT_Y, ROT_Z)
		return hasCorrectCell() && hasCorrectPos() && hasCorrectAngle()
	EndIf
	return false
EndFunction

Bool Function hasCorrectCell()
	return thisMarker.getParentCell() == targetDoor.GetParentCell()
EndFunction

Bool Function hasCorrectPos()
	return thisMarker.GetPositionX() == X && thisMarker.GetPositionY() == Y && thisMarker.GetPositionZ() == Z
EndFunction

Bool Function hasCorrectAngle()
	return thisMarker.GetAngleX() == ROT_X && thisMarker.GetAngleY() == ROT_Y && thisMarker.GetAngleZ() == ROT_Z
EndFunction