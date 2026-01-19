extends Node2D

var maxRadius: float :
	set(newMaxRadius):
		maxRadius = newMaxRadius
		
@export var circleColor: Color
@export var circleWidth: float = 15
@export var pointCount: int = 64
@export var radiusExpandSpeed: float = 200
		
var radius: float = 1

func _process(delta):
	if radius < maxRadius:
		radius += radiusExpandSpeed  * delta
		queue_redraw()
	else:
		queue_free()

func _draw():
	print("redraw")
	draw_arc(Vector2.ZERO, radius, 0, TAU, pointCount, circleColor, circleWidth)
