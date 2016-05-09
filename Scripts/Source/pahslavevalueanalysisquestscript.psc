Scriptname PAHSlaveValueAnalysisQuestScript extends Quest  Conditional

Int Property HealthRating Auto Conditional
Int Property PhysiqueRating Auto Conditional
Int Property IntellectRating Auto Conditional
Float Property RaceSexMultiplier Auto Conditional
Int Property TrainingRating Auto Conditional

Int Property Value Auto Conditional

Float Property OverallValueMultiplier Auto

Race Property ArgonianRace Auto
Race Property ArgonianRaceVampire Auto
Race Property BretonRace Auto
Race Property BretonRaceVampire Auto
Race Property DarkElfRace Auto
Race Property DarkElfRaceVampire Auto
Race Property HighElfRace Auto
Race Property HighElfRaceVampire Auto
Race Property ImperialRace Auto
Race Property ImperialRaceVampire Auto
Race Property KhajiitRace Auto
Race Property KhajiitRaceVampire Auto
Race Property NordRace Auto
Race Property NordRaceVampire Auto
Race Property OrcRace Auto
Race Property OrcRaceVampire Auto
Race Property RedguardRace Auto
Race Property RedguardRaceVampire Auto
Race Property WoodElfRace Auto
Race Property WoodElfRaceVampire Auto

Actor property slave Auto

Faction Property PAHSubmission Auto
Faction Property PAHTrainAnger Auto
Faction Property PAHTrainCombat Auto
Faction Property PAHTrainSex Auto
Faction Property PAHTrainRespect Auto

Function Calculate(Actor _slave)
	slave = _slave

	int base_health = Math.Ceiling(slave.GetBaseAv("health"))
	if base_health <= 100
		HealthRating = 1
	elseif base_health <= 200
		HealthRating = 2
	elseif base_health <= 300
		HealthRating = 3
	elseif base_health <= 400
		HealthRating = 4
	else
		HealthRating = 5
	endif

	int base_stamina = Math.Ceiling(slave.GetBaseAv("stamina"))
	if base_stamina <= 100
		PhysiqueRating = 1
	elseif base_stamina <= 200
		PhysiqueRating = 2
	elseif base_stamina <= 300
		PhysiqueRating = 3
	elseif base_stamina <= 400
		PhysiqueRating = 4
	else
		PhysiqueRating = 5
	endif
	
	int base_magicka = Math.Ceiling(slave.GetBaseAv("magicka"))
	if base_magicka <= 100
		IntellectRating = 1
	elseif base_magicka <= 200
		IntellectRating = 2
	elseif base_magicka <= 300
		IntellectRating = 3
	elseif base_magicka <= 400
		IntellectRating = 4
	else
		IntellectRating = 5
	endif

	Race slave_race = slave.GetRace()
	bool is_female = (slave.GetLeveledActorBase().GetSex() == 1)
	RaceSexMultiplier = 1.0
	if slave_race == ArgonianRaceVampire || slave_race == BretonRaceVampire || slave_race == DarkElfRaceVampire ||\
			slave_race == HighElfRaceVampire || slave_race == ImperialRaceVampire || slave_race == KhajiitRaceVampire ||\
			slave_race == NordRaceVampire || slave_race == OrcRaceVampire || slave_race == RedguardRaceVampire || slave_race == WoodElfRaceVampire
		RaceSexMultiplier = 0.3
	elseif slave_race == ArgonianRace 
		RaceSexMultiplier = 0.6
	elseif slave_race == BretonRace
		if is_female
			RaceSexMultiplier = 1.2
		else
			RaceSexMultiplier = 0.8
		endif
	elseif slave_race == DarkElfRace
		RaceSexMultiplier = 1
	elseif slave_race == HighElfRace
		if is_female
			RaceSexMultiplier = 1.3
		else
			RaceSexMultiplier = 0.7
		endif
	elseif slave_race == ImperialRace 
		RaceSexMultiplier = 1
	elseif slave_race == KhajiitRace 
		RaceSexMultiplier = 1.6
	elseif slave_race == NordRace
		if is_female
			RaceSexMultiplier = 1
		else
			RaceSexMultiplier = 1.4
		endif
	elseif slave_race == OrcRace
		RaceSexMultiplier = 1.2
	elseif slave_race == RedguardRace 
		RaceSexMultiplier = 1
	elseif slave_race == WoodElfRace 
		if is_female
			RaceSexMultiplier = 1.3
		else
			RaceSexMultiplier = 1
		endif
	endif
	
	 ; Ensure the Factions are filled.
    If (PAHSubmission == None)
        PAHSubmission = Game.GetFormFromFile(0x000047eb, "paradise_halls.esm") As Faction
    EndIf
    If (PAHTrainAnger == None)
        PAHTrainAnger = Game.GetFormFromFile(0x00055021, "paradise_halls.esm") As Faction
    EndIf
    If (PAHTrainCombat == None)
        PAHTrainCombat = Game.GetFormFromFile(0x0005a13a, "paradise_halls.esm") As Faction
    EndIf
    If (PAHTrainSex == None)
    	PAHTrainSex = Game.GetFormFromFile(0x00000d6b, "paradise_halls_SLExtension.esp") As Faction
    EndIf
    If (PAHTrainRespect == None)
        PAHTrainRespect = Game.GetFormFromFile(0x0005862b, "paradise_halls.esm") As Faction
    EndIf

	Float fTrainMod = 1.0
	fTrainMod *= ((slave.GetFactionRank(PAHSubmission) / 60.0) + 0.34)
	fTrainMod += (slave.GetFactionRank(PAHTrainAnger) / 200.0)
	fTrainMod += (slave.GetFactionRank(PAHTrainCombat) / 100.0)
	fTrainMod += (slave.GetFactionRank(PAHTrainSex) / 100.0)
	fTrainMod += (slave.GetFactionRank(PAHTrainRespect) / 150.0)
	TrainingRating = 0
	
	Float fWeightMod = (slave.GetLeveledActorBase().GetWeight() / 50.0) + 0.5

	Value = Math.Ceiling((slave.GetBaseAv("health") + slave.GetBaseAv("magicka") + slave.GetBaseAv("stamina")) * RaceSexMultiplier * OverallValueMultiplier * fTrainMod * fWeightMod)
EndFunction

Function ShowValue(Int offset = 0)
	Debug.MessageBox("Offer: " + (Value + offset) as String)
EndFunction

