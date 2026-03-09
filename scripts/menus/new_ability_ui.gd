extends PanelContainer

@onready var description = $contents/abilityMenu/info/PanelContainer/Description
@onready var new_ability_text = $contents/PanelContainer/newAbilityText


func _ready():
	new_ability_text.text = tr("NEW_ABILITY_TEXT") % tr(str(AbilityData.ABILITIES[GameManager.level]["displayName"]))
	#description.text = AbilityData.ABILITIES[GameManager.level]["description"]
