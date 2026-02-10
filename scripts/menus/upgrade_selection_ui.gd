extends PanelContainer

const UPGRADE_UI = preload("uid://bdqibxl2ctiqt")

@onready var upgrade_selections = $contents/UpgradeSelections
@onready var upgrade_points = $contents/UpgradePoints

var UIManager

func _ready():
	for k in GameManager.upgradeSet:
		var card = UPGRADE_UI.instantiate()
		upgrade_selections.add_child(card)
		
		card.upgradeSelectionUI = self
		card.percentage = GameManager.upgradeSet[k]["percentIncrease"]
		card.upgradeName = k
		card.description = GameManager.upgradeSet[k]["description"]
		card.initialize()
	reset_size()

func updateRemainingPoints():
	upgrade_points.text = "Remaining Points: " + str(GameManager.availableUpgradePoints)
	
