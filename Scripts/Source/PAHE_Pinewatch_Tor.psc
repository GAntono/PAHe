Scriptname PAHE_Pinewatch_Tor extends ObjectReference  

PAHCore Property PAH Auto
Actor Property Torolf Auto
ObjectReference Property shackles Auto
Armor Property hood Auto
Faction Property banditFriendFaction Auto
Faction Property PAHECanBeCaptured Auto
Faction Property PAHSlaveFaction Auto

Actor clone

Event OnLoad()
	Torolf.removeAllItems()
	clone = PAH.clone(Torolf)
	clone.addItem(hood)
	clone.equipItem(hood)

	clone.moveTo(shackles)
	
	clone.AllowPCDialogue(false)
	clone.setDontMove(true)
	disable()
EndEvent