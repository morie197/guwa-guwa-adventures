extends Control

@onready var damageText = $damageText

@export var riseSpeed: float = 5

var damageColor: Color = Color(1, 0.509, 0.509, 1)
var healColor: Color = Color(0.715, 1.0, 0.719, 1.0)

var healing: bool = false

func _ready():
	if healing:
		damageText.add_theme_color_override("default_color", healColor)
		print("healing")
	else:
		damageText.add_theme_color_override("default_color", damageColor)

func process(delta):
	position.y += riseSpeed * delta
