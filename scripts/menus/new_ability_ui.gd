extends PanelContainer

@onready var description = $contents/abilityMenu/info/PanelContainer/Description
@onready var new_ability_text = $contents/PanelContainer/newAbilityText


func _ready():
	new_ability_text.text = "New ability unlocked: " + str(AbilityData.ABILITIES[GameManager.level]["name"]) + "!"
	description.text = AbilityData.ABILITIES[GameManager.level]["description"]
