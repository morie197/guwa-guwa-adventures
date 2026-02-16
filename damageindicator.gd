extends Control

@onready var damageText = $damageText

@export var riseSpeed: float = 5

func process(delta):
	position.y += riseSpeed * delta
