extends Node2D

@export var circleColor: Color

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _draw():
	var circleWidth = GameManager.playerRef.radarRange * GameManager.playerRef.rangeMultiplier * GameManager.playerRef.treatFindRangeMult * GameManager.level/10.0
	draw_arc(Vector2.ZERO, circleWidth, 0, TAU, 60, circleColor, 64)
