extends Node2D

@export var circleColor: Color

# Called when the node enters the scene tree for the first time.
func _ready():
	GameManager.upgraded.connect(queue_redraw)
	GameManager.changedMapLevel.connect(_showOnMap)

func _showOnMap(on: bool):
	visible = on
	print(on)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _draw():
	if GameManager.abilities.has("treatdetect"):
		var mult: float = 1.0
		if GameManager.worldManager.levelName == "Hidden Grove":
			mult = 0.1 * GameManager.playerRef.visibilityMultiplier
		var circleWidth = (GameManager.playerRef.radarRange * GameManager.playerRef.rangeMultiplier * GameManager.playerRef.treatFindRangeMult * GameManager.level/10.0) * mult
		draw_arc(Vector2.ZERO, circleWidth, 0, TAU, 60, circleColor, 64)
