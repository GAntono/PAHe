Scriptname PAHEFindSlaveRewardEff extends ActiveMagicEffect

PAHCore Property PAH Auto
FormList Property WouldFuckList Auto
FormList Property WouldNotFuckList Auto

Event OnEffectStart(Actor target, Actor caster)
	String cName = caster.getdisplayname()
	String tName = target.getdisplayname()
			Debug.trace("PAHE Cast: " + tName + " marked")
			Debug.trace("PAHE Cast " + tName + ": " + cName + " sexuality = " + PAH.SexLab.Stats.GetSkill(caster, "Sexuality"))
	bool isStraight = PAH.SexLab.Stats.IsStraight(caster)
			Debug.trace("PAHE Cast " + tName + ": " + cName + " is Straight: " + isStraight)
	bool isGay = false
	If !isStraight
		isGay = PAH.SexLab.Stats.IsGay(caster)
			Debug.trace("PAHE Cast " + tName + ": " + cName + " is gay: " + isGay)
	EndIf
	bool isSameSex = caster.getActorBase().getSex() == target.getActorBase().getSex()
			Debug.trace("PAHE Cast " + tName + ": " + cName + " is Same Sex: " + isSameSex)
	If (isStraight && isSameSex) || (isGay && !isSameSex)
			Debug.trace("PAHE Cast " + tName + ": genderPref failed")
			dispel()
		WouldNotFuckList.addForm(target)
	Else
			Debug.trace("PAHE Cast " + tName + ": genderPref done")
		int attraction = 55
		If PAH.attractionInstalled
				Debug.trace("PAHE Cast " + tName + ": " + cName + " attraction")
			attraction = (PAH.attractionInstalled as SLAttractionMainScript).GetActorAttraction(caster, target)
		EndIf
				Debug.trace("PAHE Cast " + tName + ": " + cName + " attraction done: " + attraction)
		
		int arousal = 50
		If PAH.arousedInstalled
				Debug.trace("PAHE Cast " + tName + ": " + cName + " arousal")
			arousal = (PAH.arousedInstalled as slaframeworkscr).GetActorArousal(caster)
		EndIf
				Debug.trace("PAHE Cast " + tName + ": " + cName + " arousal done: " + arousal)
		
		int value = (attraction * 2) + arousal
		If attraction * 2 + arousal < 130
				Debug.trace("PAHE Cast " + tName + ": " + tName + " rejected")
			dispel()
		Else
				Debug.trace("PAHE Cast " + tName + ": " + tName + " accepted")
		EndIf
	EndIf
				Debug.trace("PAHE Cast " + tName + ": " + tName + " done")
EndEvent
