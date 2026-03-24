extends Control

@onready var upgrade_level_text = $UpgradeContent/UpgradeInfo/upgradeLevel

@onready var textName = $UpgradeContent/Text/name
@onready var descriptionText = $UpgradeContent/Text/Description

@onready var upgrade_button = $UpgradeContent/UpgradeInfo/maxedOutIndicator/upgradeButton
@onready var maxed_out_indicator = $UpgradeContent/UpgradeInfo/maxedOutIndicator

var upgradeSelectionUI

var percentage: int
var upgradeName: String
var upgradeText: String
var description: String

# Called when the node enters the scene tree for the first time.
func _ready():
	upgrade_button.pressed.connect(_upgradeButtonPressed)
	maxed_out_indicator.pressed.connect(_upgradeButtonPressed)


func initialize():
	#textName.text = "+" + str(GameManager.upgradeSet[upgradeName]["percentIncrease"]) + "% " + upgradeName
	textName.text = upgradeText
	if upgradeText.length() > 7:
		textName.add_theme_font_size_override("normal_font_size", 38)
	descriptionText.text = description
	_updateUI()

func _updateUI():
	var level
	

	if GameManager.upgradeSet == UpgradeData.POSTGAMEUPGRADES:
		level = GameManager.postgameUpgradeLevels[upgradeName]
		if GameManager.postgameUpgradeLevels[upgradeName] >= GameManager.upgradeSet[upgradeName]["levels"]:
			upgrade_level_text.add_theme_color_override("default_color", Color.RED)
			upgrade_button.visible = false
	else:
		level = GameManager.upgradeLevels[upgradeName]
		if GameManager.upgradeLevels[upgradeName] >= GameManager.upgradeSet[upgradeName]["levels"]:
			upgrade_level_text.add_theme_color_override("default_color", Color.RED)
			upgrade_button.visible = false

	upgrade_level_text.text = str(level) + " / " +  str(GameManager.upgradeSet[upgradeName]["levels"])

	if upgradeSelectionUI != null:
		upgradeSelectionUI.updateRemainingPoints()
		
func _upgradeButtonPressed():
	if GameManager.upgradeSet == UpgradeData.POSTGAMEUPGRADES:
		if GameManager.postgameUpgradeLevels[upgradeName] >= GameManager.upgradeSet[upgradeName]["levels"]:
			upgradeSelectionUI.UIManager.masterUIManager.max_level_sound.play()
			return
		else:
			GameManager.postgameUpgradeLevels[upgradeName] += 1
	else:
		if GameManager.upgradeLevels[upgradeName] >= GameManager.upgradeSet[upgradeName]["levels"]:
			upgradeSelectionUI.UIManager.masterUIManager.max_level_sound.play()
			return
		else:
			GameManager.upgradeLevels[upgradeName] += 1
	upgradeSelectionUI.UIManager.masterUIManager.upgraded_sound.play()
	GameManager.availableUpgradePoints -= 1
	if GameManager.availableUpgradePoints == 0:
		upgradeSelectionUI.UIManager.hideLevelUpUI()
		GameManager.closeUpgrades()
			
	_updateUI()
