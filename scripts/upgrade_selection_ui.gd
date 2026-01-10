extends Control

const UPGRADE_UI = preload("uid://bdqibxl2ctiqt")

@onready var upgrade_selections = $upgradeSelection/UpgradeSelections
@onready var upgrade_points = $upgradeSelection/UpgradePoints

func _ready():
	GameManager.paused = true
	for k in UpgradeData.UPGRADES:
		var card = UPGRADE_UI.instantiate()
		upgrade_selections.add_child(card)
		
		card.upgradeSelectionUI = self
		card.percentage = UpgradeData.UPGRADES[k]["percentIncrease"]
		card.upgradeName = k
		card.description = UpgradeData.UPGRADES[k]["description"]
		card.initialize()

func updateRemainingPoints():
	upgrade_points.text = "Remaining Points: " + str(GameManager.availableUpgradePoints)
	
