Scriptname RPNodes Hidden

import NiOverride

bool Function transferNode(Actor source, Actor target) Global
	float mag = GetNodeTransformScale(source, false, true, "NPC L Breast", "RandomPatches")
	
	If mag != 0
    		AddNodeTransformScale(target, false, true, "NPC L Breast", "RandomPatches", mag)
		AddNodeTransformScale(target, false, true, "NPC R Breast", "RandomPatches", mag)

		UpdateNodeTransform(target, false, true, "NPC L Breast")
		UpdateNodeTransform(target, false, true, "NPC R Breast")
		return true
	Else
		return false
	EndIf
EndFunction