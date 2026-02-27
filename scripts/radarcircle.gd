extends Node2D

var maxRadius: float :
	set(newMaxRadius):
		maxRadius = newMaxRadius
		
@export var circleColor: Color
@export var circleWidth: float = 20
@export var pointCount: int = 256
@export var radiusExpandSpeed: float = 240

@onready var radar_light = %radarLight
		
var radius: float = 1
var startLevel: int = 1

func _ready():
	#startLevel = GameManager.worldLayer
	
	if GameManager.worldManager != null:
		if GameManager.worldManager.levelName == "Hidden Grove":
			radar_light.energy = 2.0
		else:
			if GameManager.worldLayer == 0:
				radar_light.energy = 1.0
			else:
				radar_light.energy = 0.5

func _process(delta):
	if radius < maxRadius:
		radius += radiusExpandSpeed  * delta
		queue_redraw()
	else:
		modulate = modulate.lerp(Color.TRANSPARENT, delta)
		radar_light.energy = lerpf(radar_light.energy, 0, delta)
		if modulate.a < 0.1 and radar_light.energy < 0.1:
			modulate.a -= 0.01 * delta
			radar_light.energy -= 0.01 * delta
			if radar_light.energy < 0.005:
				print("freed")
				queue_free()
				
	if GameManager.worldLayer == startLevel:
		show()
	else:
		hide()

func _draw():
	draw_arc(Vector2.ZERO, radius, 0, TAU, pointCount, circleColor, circleWidth)
	radar_light.texture_scale = radius/512
