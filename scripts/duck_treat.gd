extends Node2D

var origin: Vector2

var hoverState: int = 1
var hoverSpeed: float = 0.6
var hoverAmount: float = 20.0
var hoverTime: float = 0.0
@export var id: int = 0

func _ready():
	self.body_entered.connect(_player_entered)
	origin = global_position

func _physics_process(delta):
	if hoverState == 1:
		hoverTime += delta
		if hoverTime >= hoverSpeed:
			hoverState = -1
	else:
		hoverTime -= delta
		if hoverTime <= -hoverSpeed:
			hoverState = 1
	global_position.y = origin.y + (hoverTime * hoverAmount)
	

func _player_entered(body: Node2D):
	#print("duck enter")
	GameManager.treatGet()
	queue_free()
