Scriptname PAH_MCM extends SKI_ConfigBase

PAHCore Property PAH Auto
PAHBootstrapScript Property Reboot Auto

String version = "0.1H RC 5.1"
String testVersion = "test4"

Int maxSub_OID

Int fleeToggle_OID
Int healthToggle_OID
Int bleedOutToggle_OID
Int leashToggle_OID
Int rebootToggle_OID
Int statSpellToggle_OID
Int slaverRankSetting_OID
Int debugToggle_OID
Int resetSlaveList_OID
Int resetSlave_OID
Int hotKey_OID
Int whistleKey_OID
Int rename_OID
Int renameToggle_OID
Int alwaysAggroToggle_OID
Int showSlaveCountToggle_OID
Int _hotkey = -1
Int Property hotkey Hidden
	Int Function Get()
		return _hotkey
	EndFunction
EndProperty
Int _whistleKey = -1
Int Property whistleKey Hidden
	Int Function Get()
		return _whistleKey
	EndFunction
EndProperty

Int[] slave_OID

int Property runAwayValue = 60 Auto Hidden
int Property severity = 100 Auto Hidden
int Property followerTrainingEfficiency = 50 Auto Hidden

float Property postRapeDelay = 30.0 Auto Hidden

bool Property fleeToggle = true Auto Hidden
bool Property healthToggle = true Auto Hidden
bool Property bleedOutToggle = true Auto Hidden
bool Property leashToggle = false Auto Hidden
bool Property renameToggle = false Auto Hidden
bool Property statSpellToggle = false Auto Hidden
bool Property showSlaveCountToggle = false Auto Hidden
bool _debugToggle = true
bool Property debugToggle
	bool Function Get()
		return _debugToggle
	endFunction
endProperty

GlobalVariable Property globalHealthPerc Auto Hidden

Spell Property statSpell Auto

PAHSlave currentSlave = None
int currentSlave_OID = -1

int forcedReset = -1
string[] pageNames

Event OnGameReload()
	parent.OnGameReload()
EndEvent

Event OnConfigOpen()
	version = "0.1H RC 5.1"

	pageNames = new String[3]
	pageNames[0] = "Options"
	pageNames[1] = "Slaves"
	pageNames[2] = version + testVersion

	Pages = pageNames
EndEvent

event OnPageReset(string page)
	if page == pageNames[0]
		UpdateOptionsPage()
	elseIf page == pageNames[1]
		UpdateSlavesPage()
	else
		OnPageReset(pageNames[0])
	EndIf
EndEvent

Function UpdateOptionsPage()
	int disableFlag = OPTION_FLAG_DISABLED

	if !Reboot
		Reboot = Game.GetFormFromFile(0x000CF32, "paradise_halls.esm") As PAHBootstrapScript
	EndIf

	SetCursorFillMode(TOP_TO_BOTTOM)
	AddHeaderOption("Toggles")
;	fleeToggle_OID = AddToggleOption("$PAHE_SettingName_FleeToggle", fleeToggle, disableFlag)
;	healthToggle_OID = AddToggleOption("$PAHE_SettingName_HealthToggle", healthToggle, disableFlag)
;	bleedOutToggle_OID = AddToggleOption("$PAHE_SettingName_BleedOutToggle", bleedOutToggle, disableFlag)
	leashToggle_OID = AddToggleOption("$PAHE_SettingName_LeashToggle", leashToggle)
	alwaysAggroToggle_OID = AddToggleOption("$PAHE_SettingName_alwaysAggroToggle", PAH.bAlwaysAggressive)
	showSlaveCountToggle_OID = AddToggleOption("$PAHE_SettingName_showSlaveCountToggle", showSlaveCountToggle)
	If PAH.jcInstalled
		renameToggle_OID = AddToggleOption("$PAHE_SettingName_RenameToggle", renameToggle)
	EndIf

	AddHeaderOption("Sliders")
	AddSliderOptionST("SLAVE_runaway", "$PAHE_SettingName_RunAway", runAwayValue)
	AddSliderOptionST("CAP_health", "$PAHE_SettingName_HealthPerc", globalHealthPerc.getValue() * 100)
	AddSliderOptionST("RAPE_time", "$PAHE_SettingName_RapeTimer", postRapeDelay)
	AddSliderOptionST("PUN_severity", "$PAHE_SettingName_Severity", severity)
	AddSliderOptionST("FOL_efficiency", "$PAHE_SettingName_Follower", followerTrainingEfficiency)

;===============================================================================
	SetCursorPosition(1)
	AddHeaderOption("Debug")

	string status = "Stopped"
	int flag = OPTION_FLAG_NONE
	if PAH.IsRunning()
		status = PAH.modStatus
		If status == "$PAHE_SettingName_RebootToggle_restarting"
			flag = OPTION_FLAG_DISABLED
		Else
			flag = OPTION_FLAG_NONE
		EndIf
	elseIf PAH.IsStarting()
		status = "Starting"
		flag = OPTION_FLAG_DISABLED
	endIf
	rebootToggle_OID = AddTextOption("$PAHE_SettingName_Status", status, flag)

	AddEmptyOption()
;	slaverRankSetting_OID = AddTextOption("$PAHE_SettingName_SlaverRankSetting", "$PAHE_SlaverSetting_" + PAH.slaverSetting)
;	AddTextOption("$PAHE_SettingName_SlaverRank", PAH.slaverRank, OPTION_FLAG_DISABLED)
	resetSlaveList_OID = AddTextOption("$PAHE_SettingName_SlaveCount", PAH.GetSlaveCount() + "/" + PAH.GetMaxSlaveCount())

	AddEmptyOption()
	statSpellToggle_OID = AddToggleOption("$PAHE_SettingName_StatSpellToggle", statSpellToggle)
	debugToggle_OID = AddToggleOption("$PAHE_SettingName_debugToggle", _debugToggle)

	AddHeaderOption("Keys")
	whistleKey_OID = AddKeyMapOption("$PAHE_SettingName_WhistleKey", whistleKey)
	hotKey_OID = AddKeyMapOption("$PAHE_SettingName_Hotkey", hotkey)
EndFunction

Function UpdateSlavesPage()
	SetCursorFillMode(TOP_TO_BOTTOM)
	int slaveCount = PAH.GetSlaveCount()
	int displayedSlaveIndex = -1

	If forcedReset != -1
		int j = 0
		while j < slaveCount
			if forcedReset == slave_OID[j]
				forcedReset = -1
				displayedSlaveIndex = j
				PAH.setSlaveName(j)
				ListSlaveStats(j)
				j = slaveCount
			EndIf
			j += 1
		EndWhile
	EndIf

	SetCursorPosition(0)
	AddHeaderOption("Slaves")
	slave_OID = PAH.GetIntArrayLength(PAH.GetSlaveCount())
	int i = 0
	while i < PAH.slaveArray.length
		slave_OID[i] = AddTextOption(i+1 + ": " + PAH.getSlaveName(i), "")
		If i == displayedSlaveIndex
			currentSlave_OID = slave_OID[i]
		EndIf
		i += 1
	endWhile
EndFunction

Function ListSlaveStats(int index)
	int magicNumber = 15 ;min number of colums
	SetCursorPosition(PAH.getMax(((index * 2) - magicNumber), 1) as Int)

	currentSlave = PAH.slaveArray[index]
	AddHeaderOption(index + 1 + ": " + currentSlave.GetActorRef().GetDisplayName())

	String occupation = "Slave"
	If currentSlave.GetActorRef().IsInFaction(currentSlave.PAHShouldFightForPlayer)
		If currentSlave.GetActorRef().IsInFaction(currentSlave.PAHBEFollowing)
			If PAH.isCaster(currentSlave)
				occupation = "$PAHE_Mage"
			Else
				occupation = "$PAHE_Fighter"
			EndIf
		else
			occupation = "$PAHE_Guard"
		endIf
	endIf
	AddTextOption("$PAHE_Occupation", occupation, OPTION_FLAG_DISABLED)

	string gender
	if currentSlave.GetActorRef().GetLeveledActorBase().GetSex() == 0
		gender = "$PAHE_Male"
	else
		gender = "$PAHE_Female"
	endIf
	AddTextOption("$PAHE_Gender", gender, OPTION_FLAG_DISABLED)

	String currentLoc
	If currentSlave.GetRef().GetParentCell()
		currentLoc = currentSlave.GetRef().GetParentCell().GetName()
	elseIf currentSlave.GetRef().GetCurrentLocation()
		currentLoc = currentSlave.GetRef().GetCurrentLocation().GetName()
	EndIf
	If currentLoc == ""
		float angle = Game.GetPlayer().GetAngleZ() + Game.GetPlayer().GetHeadingAngle(currentSlave.GetRef())
		while angle < 0
			angle = 360 - angle
		endWhile
		while angle > 360
			angle = angle - 360
		endWhile
		string direction
		if angle <= 22.5
			direction = "to your north."
		elseIf angle <= 67.5
			direction = "to your northeast."
		elseIf angle <= 112.5
			direction = "to your east."
		elseIf angle <= 157.5
			direction = "to your southeast"
		elseIf angle <= 202.5
			direction = "to your south."
		elseIf angle <= 247.5
			direction = "to your southwest."
		elseIf angle <= 292.5
			direction = "to your west."
		elseIf angle <= 337.5
			direction = "to your northwest."
		elseIf angle <= 360
			direction = "to your north."
		else
			direction = "in an unknown direction."
		EndIf

		float distance = currentSlave.GetRef().GetDistance(Game.GetPlayer())
		string units = " metres "
		distance = currentSlave.GetRef().GetDistance(Game.GetPlayer()) * 1.428 / 100
		if distance > 1000
			distance = distance / 1000
			units = " kilometres "
		endIf
		AddTextOption("$PAHE_Location", "Tamriel", OPTION_FLAG_DISABLED)
		AddTextOption("", (distance as int) + units + direction, OPTION_FLAG_DISABLED)
	Else
		AddTextOption("$PAHE_Location", currentLoc, OPTION_FLAG_DISABLED)
	EndIf

;	AddEmptyOption()
	AddTextOption("$PAHE_Health", (currentSlave.GetActorRef().GetAV("Health") / currentSlave.GetActorRef().GetAVPercentage("Health")) as Int, OPTION_FLAG_DISABLED)
	If occupation == "Mage" || occupation == "Guard"
		AddTextOption("$PAHE_Magicka", (currentSlave.GetActorRef().GetAV("Magicka") / currentSlave.GetActorRef().GetAVPercentage("Magicka")) as Int, OPTION_FLAG_DISABLED)
	EndIf

	AddHeaderOption("Slave Stats")
	AddTextOption("$PAHE_Submission", currentSlave.submission as Int, OPTION_FLAG_DISABLED)
	AddTextOption("$PAHE_Combat", currentSlave.combat_training as Int, OPTION_FLAG_DISABLED)
	AddTextOption("$PAHE_Anger", currentSlave.anger_training as Int, OPTION_FLAG_DISABLED)
	AddTextOption("$PAHE_Respect", currentSlave.respect_training as Int, OPTION_FLAG_DISABLED)
	AddTextOption("$PAHE_Sex", currentSlave.sex_training as Int, OPTION_FLAG_DISABLED)
	If debugToggle
;		AddTextOption("$PAHE_Fear", currentSlave.fear_training as Int, OPTION_FLAG_DISABLED)
		AddTextOption("Morality:", currentSlave.getActorRef().GetAV("Morality"), OPTION_FLAG_DISABLED)
		AddTextOption("Current mood: ", currentSlave.mind.mood, OPTION_FLAG_DISABLED)
		AddTextOption("Current state: ", currentSlave.behaviour, OPTION_FLAG_DISABLED)
	EndIf
	rename_OID = AddTextOption("", "Rename " + currentSlave.GetActorRef().getDisplayName())

	If debugToggle
		AddEmptyOption()
		maxSub_OID = AddTextOption("Max Submission:", currentSlave.GetActorRef().GetDisplayName())
		resetSlave_OID = AddTextOption("Reset Slave:", currentSlave.GetActorRef().GetDisplayName())
	EndIf
EndFunction

Event OnOptionHighLight(Int option)
	If (option == fleeToggle_OID)
		SetInfoText("$PAHE_SettingInfo_FleeToggle")
	ElseIf (option == healthToggle_OID)
		SetInfoText("$PAHE_SettingInfo_HealthToggle")
	ElseIf (option == bleedOutToggle_OID)
		SetInfoText("$PAHE_SettingInfo_BleedOutToggle")
	ElseIf (option == leashToggle_OID)
		SetInfoText("$PAHE_SettingInfo_LeashToggle")
	ElseIf (option == rebootToggle_OID)
		SetInfoText("$PAHE_SettingInfo_RebootToggle")
	ElseIf (option == statSpellToggle_OID)
		SetInfoText("$PAHE_SettingInfo_StatSpellToggle")
	ElseIf (option == slaverRankSetting_OID)
		SetInfoText("$PAHE_SlaverInfo_" + PAH.slaverSetting)
	ElseIf (option == debugToggle_OID)
		SetInfoText("$PAHE_SettingInfo_debugToggle")
	ElseIf (option == hotKey_OID)
		SetInfoText("$PAHE_SettingInfo_Hotkey")
	ElseIf (option == whistleKey_OID)
		SetInfoText("$PAHE_SettingInfo_WhistleKey")
	ElseIf (option == renameToggle_OID)
		SetInfoText("$PAHE_SettingInfo_RenameToggle")
	ElseIf (option == alwaysAggroToggle_OID)
		SetInfoText("$PAHE_SettingInfo_alwaysAggroToggle")
	ElseIf (option == showSlaveCountToggle_OID)
		SetInfoText("$PAHE_SettingInfo_showSlaveCountToggle")
	EndIf
EndEvent

Event OnOptionSelect(Int option)
	If CurrentPage == pageNames[1]
		If (option == rename_OID)
			UILIB_1 UILib = ((Self as Form) as UILIB_1)
			String suggestedName = currentSlave.GetActorRef().getDisplayName()
			If PAH.jcInstalled
				string gender
				If currentSlave.GetActorRef().GetLeveledActorBase().getSex() == 0
					gender = "Male"
				Else
					gender = "Female"
				EndIf
				
				string sRace = currentSlave.GetActorRef().getRace().getName()
				string filename = gender + sRace

				int jNames = JValue.readFromFile("Data/PAHE/" + filename + ".txt")
				int rInt = Utility.RandomInt(0, JArray.count(jNames) - 1)
				String name = JArray.getStr(jNames, rInt)
	
				If name != ""
					suggestedName = name
				EndIf
			EndIf

			String sResult = UILib.ShowTextInput("Rename Slave", suggestedName)
			If sResult != ""
				currentSlave.SetDisplayName(sResult)
				forcedReset = currentSlave_OID
				ForcePageReset()
			EndIf
		ElseIf (option == resetSlave_OID)
			ShowMessage("Close all menus to continue...", false)
			Utility.wait(0.1)
			currentSlave.resetSlave()
		ElseIf (option == maxSub_OID)
			currentSlave.submission = 100
			forcedReset = currentSlave_OID
			ForcePageReset()
		Else
			forcedReset = option
			ForcePageReset()
		EndIf
	Else
		If (option == fleeToggle_OID)
			fleeToggle = !fleeToggle
			SetToggleOptionValue(fleeToggle_OID, fleeToggle)
		ElseIf (option == healthToggle_OID)
			healthToggle = !healthToggle
			SetToggleOptionValue(healthToggle_OID, healthToggle)
		ElseIf (option == bleedOutToggle_OID)
			bleedOutToggle = !bleedOutToggle
			SetToggleOptionValue(bleedOutToggle_OID, bleedOutToggle)
		ElseIf (option == renameToggle_OID)
			renameToggle = !renameToggle
			SetToggleOptionValue(renameToggle_OID, renameToggle)
		ElseIf (option == leashToggle_OID)
			leashToggle = !leashToggle
			SetToggleOptionValue(leashToggle_OID, leashToggle)
		ElseIf (option == showSlaveCountToggle_OID)
			showSlaveCountToggle = !showSlaveCountToggle
			SetToggleOptionValue(showSlaveCountToggle_OID, showSlaveCountToggle)
		ElseIf (option == rebootToggle_OID)
			SetTextOptionValue(rebootToggle_OID, "Restarting")
			SetOptionFlags(rebootToggle_OID, OPTION_FLAG_DISABLED)
			ShowMessage("Close all menus to continue...", false)
			Utility.wait(0.1)
			Reboot.Boot()
		ElseIf (option == statSpellToggle_OID)
			statSpellToggle = !statSpellToggle
			If statSpellToggle
				Game.GetPlayer().AddSpell(statSpell)
			else
				Game.GetPlayer().RemoveSpell(statSpell)
			endIf
			SetToggleOptionValue(statSpellToggle_OID, statSpellToggle)
		ElseIf (option == slaverRankSetting_OID)
			PAH.slaverSetting += 1
			SetTextOptionValue(slaverRankSetting_OID, "$PAHE_SlaverSetting_" + PAH.slaverSetting)
		ElseIf (option == debugToggle_OID)
			_debugToggle = !_debugToggle
			SetToggleOptionValue(debugToggle_OID, _debugToggle)
		ElseIf (option == resetSlaveList_OID)
			PAH.updateSlaveArray()
		ElseIf (option == alwaysAggroToggle_OID)
			PAH.bAlwaysAggressive = !PAH.bAlwaysAggressive
			SetToggleOptionValue(alwaysAggroToggle_OID, PAH.bAlwaysAggressive)
		EndIf
	EndIf
EndEvent

Event OnOptionKeyMapChange(int option, int keyCode, string conflictControl, string conflictName)
	If (option == hotKey_OID)
		_hotKey = keyCode
		SetKeyMapOptionValue(hotKey_OID, hotkey)
		PAH.RegisterForKey(hotKey)
	ElseIf (option == whistleKey_OID)
		_whistleKey = keyCode
		SetKeyMapOptionValue(whistleKey_OID, whistleKey)
		PAH.RegisterForKey(whistleKey)
	EndIf
EndEvent

event OnOptionDefault(int option)
	If (option == hotKey_OID)
		PAH.UnregisterForKey(_hotKey)
		_hotkey = -1
		SetKeyMapOptionValue(hotKey_OID, hotkey)
	ElseIf (option == whistleKey_OID)
		PAH.UnregisterForKey(_whistleKey)
		_whistleKey = -1
		SetKeyMapOptionValue(whistleKey_OID, whistleKey)
	EndIf
EndEvent

State SLAVE_runaway
	Event OnSliderOpenST()
		SetSliderDialogStartValue(runAwayValue)
		SetSliderDialogDefaultValue(60)
		SetSliderDialogRange(0, 100)
		SetSliderDialogInterval(1)
	EndEvent
	Event OnSliderAcceptST(float value)
		runAwayValue = value As int
		SetSliderOptionValueST(runAwayValue)
	EndEvent
	Event OnDefaultST()
		runAwayValue = 60
		SetSliderOptionValueST(runAwayValue)
	EndEvent
	Event OnHighlightST()
		SetInfoText("$PAHE_SettingInfo_RunAway")
	EndEvent
EndState

State CAP_health
	Event OnSliderOpenST()
		SetSliderDialogStartValue(globalHealthPerc.getValue() * 100)
		SetSliderDialogDefaultValue(50)
		SetSliderDialogRange(1, 100)
		SetSliderDialogInterval(1)
	EndEvent
	Event OnSliderAcceptST(float value)
		globalHealthPerc.setValue((value/100))
		SetSliderOptionValueST(globalHealthPerc.getValue() * 100)
	EndEvent
	Event OnDefaultST()
		globalHealthPerc.setValue(50 / 100)
		SetSliderOptionValueST(globalHealthPerc.getValue() * 100)
	EndEvent
	Event OnHighlightST()
		SetInfoText("$PAHE_SettingInfo_HealthPerc")
	EndEvent
EndState

State RAPE_time
	Event OnSliderOpenST()
		SetSliderDialogStartValue(postRapeDelay)
		SetSliderDialogDefaultValue(30)
		SetSliderDialogRange(5, 120)
		SetSliderDialogInterval(0.5)
	EndEvent
	Event OnSliderAcceptST(float value)
		postRapeDelay = value
		SetSliderOptionValueST(postRapeDelay)
	EndEvent
	Event OnDefaultST()
		postRapeDelay = 30
		SetSliderOptionValueST(postRapeDelay)
	EndEvent
	Event OnHighlightST()
		SetInfoText("$PAHE_SettingInfo_RapeTimer")
	EndEvent
EndState

State PUN_severity
	Event OnSliderOpenST()
		SetSliderDialogStartValue(severity)
		SetSliderDialogDefaultValue(100)
		SetSliderDialogRange(0, 100)
		SetSliderDialogInterval(1)
	EndEvent
	Event OnSliderAcceptST(float value)
		severity = value as Int
		SetSliderOptionValueST(severity)
	EndEvent
	Event OnDefaultST()
		severity = 100
		SetSliderOptionValueST(severity)
	EndEvent
	Event OnHighlightST()
		SetInfoText("$PAHE_SettingInfo_Severity")
	EndEvent
EndState

State FOL_efficiency
	Event OnSliderOpenST()
		SetSliderDialogStartValue(followerTrainingEfficiency)
		SetSliderDialogDefaultValue(50)
		SetSliderDialogRange(0, 100)
		SetSliderDialogInterval(1)
	EndEvent
	Event OnSliderAcceptST(float value)
		followerTrainingEfficiency = value as Int
		SetSliderOptionValueST(followerTrainingEfficiency)
	EndEvent
	Event OnDefaultST()
		followerTrainingEfficiency = 50
		SetSliderOptionValueST(followerTrainingEfficiency)
	EndEvent
	Event OnHighlightST()
		SetInfoText("$PAHE_SettingInfo_Follower")
	EndEvent
EndState