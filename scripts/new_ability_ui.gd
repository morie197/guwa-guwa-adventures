extends VBoxContainer

@onready var description = $abilityMenu/info/Description
@onready var new_ability_text = $newAbilityText

func _ready():
	new_ability_text.text = "New ability unlocked: " + str(AbilityData.ABILITIES[GameManager.level]["name"]) + "!"
	description.text = AbilityData.ABILITIES[GameManager.level]["description"]
