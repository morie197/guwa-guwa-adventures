extends Node2D

@onready var quack_detector = $quackDetector
@onready var collider = $collider


# Called when the node enters the scene tree for the first time.
func _ready():
	quack_detector.area_entered.connect(_quack_detected)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _quack_detected(area):
	collider.set_collision_layer_value(1, false)
	quack_detector.set_collision_mask_value(6, false)
	print("alright")
	hide()
