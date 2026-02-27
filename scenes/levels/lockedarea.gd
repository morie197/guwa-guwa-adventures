extends Polygon2D

@export var requiredAbility: String = "sprint"

# Called when the node enters the scene tree for the first time.
func _ready():
	if GameManager.abilities.has(requiredAbility):
		hide()
	else:
		show()
		GameManager.levelUp.connect(_hide)


func _hide():
	if GameManager.abilities.has(requiredAbility):
		hide()
	else:
		show()
		
