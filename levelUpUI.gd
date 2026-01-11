extends PanelContainer

const UPGRADE_SELECTION_UI = preload("uid://dwgfu70tl5d85")
const NEW_ABILITY_UI = preload("uid://bkgdqgkcf3kcv")

@onready var popups = $Popups

var selectionUI
var abilityUI

func _ready():
	GameManager.paused = true
	
	if AbilityData.ABILITIES.has(GameManager.level):
		abilityUI = NEW_ABILITY_UI.instantiate()
		popups.add_child(abilityUI)
	
	selectionUI = UPGRADE_SELECTION_UI.instantiate()
	selectionUI.UIManager = self
	popups.add_child(selectionUI)
	
func hideLevelUpUI():
	queue_free()
