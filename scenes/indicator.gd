extends Node2D

var pointAtCoords: Vector2
var pointAt

var delayTime: float = 0

@onready var pointer = $TextureRect

#var originPosition

# Called when the node enters the scene tree for the first time.
func _ready():
	pointer.normaldisplayTime += delayTime


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pointAtCoords = pointAt.global_position
	global_position = GameManager.playerRef.global_position + (pointAtCoords - GameManager.playerRef.global_position).normalized() * 128
	
	look_at(pointAtCoords)
	#var vectorAngle = (global_position - pointAtCoords).normalized()
	#position = Vector2.ZERO
	#global_rotation = vectorAngle.rotated(PI / 2).angle()
	#global_position += Vector2(-vectorAngle.x, -vectorAngle.y) * 64
