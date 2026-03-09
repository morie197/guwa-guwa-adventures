extends VBoxContainer

const UPGRADE_SELECTION_UI = preload("uid://dwgfu70tl5d85")
const NEW_ABILITY_UI = preload("uid://bkgdqgkcf3kcv")



var masterUIManager
var selectionUI
var abilityUI

func _ready():
	GameManager.paused = true
	if AbilityData.ABILITIES.has(GameManager.level):
		abilityUI = NEW_ABILITY_UI.instantiate()
		add_child(abilityUI)
		
	%levelUpText.text = tr("DUCK_TREAT_OBTAINED")
	
	var upgradeLevelsCap: bool = false
	if GameManager.upgradeSet == UpgradeData.POSTGAMEUPGRADES:
		if GameManager.postgameUpgradeLevels["power"] + GameManager.postgameUpgradeLevels["reach"] + GameManager.postgameUpgradeLevels["resistance"] >= 30:
			upgradeLevelsCap = true
	else:
		if GameManager.upgradeLevels["speed"] + GameManager.upgradeLevels["endurance"] + GameManager.upgradeLevels["range"] >= 60:
			upgradeLevelsCap = true
	if upgradeLevelsCap:
		GameManager.closeUpgrades()
		queue_free()
		return
	selectionUI = UPGRADE_SELECTION_UI.instantiate()
	selectionUI.UIManager = self
	add_child(selectionUI)

func hideLevelUpUI():
	queue_free()
