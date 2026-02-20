extends Node2D

var pointAtCoords: Vector2
var pointAt

var delayTime:
	set(newDelay):
		print("nya")
		delayTime = newDelay
		pointer.normaldisplayTime += delayTime
		pointer.normaldisplayTimer = pointer.normaldisplayTime

@onready var pointer = $TextureRect

#var originPosition

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pointAtCoords = pointAt.global_position
	look_at(pointAtCoords)
	global_position = GameManager.playerRef.global_position + (pointAtCoords - GameManager.playerRef.global_position).normalized() * 128
	
	
	#var vectorAngle = (global_position - pointAtCoords).normalized()
	#position = Vector2.ZERO
	#global_rotation = vectorAngle.rotated(PI / 2).angle()
	#global_position += Vector2(-vectorAngle.x, -vectorAngle.y) * 64
