Scriptname PAHInfoEffect extends activemagiceffect

PAHCore Property PAH Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
		Int index = 0
		Debug.OpenUserLog("PAHLog")
		While (index < PAH.slave_aliases.length + 1)
				Debug.TraceUser("PAHLog", "Index: " + PAH.slave_aliases[index], 0)
				index += 1
		EndWhile
		Debug.CloseUserLog("PAHLog")
		Debug.MessageBox("System Info Done. Found " + index + " aliases")
EndEvent