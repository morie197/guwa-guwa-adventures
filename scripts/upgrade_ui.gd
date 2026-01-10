extends Control

@onready var boxactive1 = $UpgradeContent/UpgradeInfo/indicators/indicatorinactive/indicatoractive
@onready var boxactive2 = $UpgradeContent/UpgradeInfo/indicators/indicatorinactive2/indicatoractive2
@onready var boxactive3 = $UpgradeContent/UpgradeInfo/indicators/indicatorinactive3/indicatoractive3
@onready var boxactive4 = $UpgradeContent/UpgradeInfo/indicators/indicatorinactive4/indicatoractive4
@onready var boxactive5 = $UpgradeContent/UpgradeInfo/indicators/indicatorinactive5/indicatoractive5

@onready var textName = $UpgradeContent/Text/name
@onready var descriptionText = $UpgradeContent/Text/Description

@onready var upgrade_button = $UpgradeContent/UpgradeInfo/upgradeButton

var upgradeSelectionUI

var percentage: int
var upgradeName: String
var description: String


# Called when the node enters the scene tree for the first time.
func _ready():
	upgrade_button.pressed.connect(_upgradeButtonPressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func initialize():
	textName.text = upgradeName
	descriptionText.text = description
	_updateUI()

func _updateUI():
	var level = GameManager.upgradeLevels[upgradeName]
	
	boxactive1.visible = false
	boxactive2.visible = false
	boxactive3.visible = false
	boxactive4.visible = false
	boxactive5.visible = false
	
	if level >= 1:
		boxactive1.visible = true
	if level >= 2:
		boxactive2.visible = true
	if level >= 3:
		boxactive3.visible = true
	if level >= 4:
		boxactive4.visible = true
	if level >= 5:
		boxactive5.visible = true
		
	if upgradeSelectionUI != null:
		upgradeSelectionUI.updateRemainingPoints()
		
func _upgradeButtonPressed():
	if GameManager.upgradeLevels[upgradeName] >= UpgradeData.UPGRADES[upgradeName]["levels"]:
		print("max level")
		return
	GameManager.upgradeLevels[upgradeName] += 1
	
	GameManager.availableUpgradePoints -= 1
	if GameManager.availableUpgradePoints == 0:
		if !upgradeSelectionUI.is_queued_for_deletion():
			upgradeSelectionUI.queue_free()
			GameManager.closeUpgrades()
			
	_updateUI()
