extends Area2D

@onready var point_light_2d = $PointLight2D

@export var undergroundEnergy: float = 1.0

var origin: Vector2

var amplitude: float = 10
var frequency: float = 2
var hoverTime: float = 0.0
var id: int = 0
var underground: bool = false

func _ready():
	self.body_entered.connect(_player_entered)
	origin = global_position
	if name.match("duckTreat"):
		id = 1
	else:
		id = name.trim_prefix("duckTreat").to_int()
	
	GameManager.treatsUpdated.connect(_treatsUpdated)

func _process(delta):
	hoverTime += delta * frequency
	position.y = origin.y + sin(hoverTime) * amplitude
	

func _player_entered(body: Node2D):
	GameManager.treatGet()
	GameManager.treatRegistry.append(id)
	_enableDisable(false)
	
func _treatsUpdated():
	monitoring = true
	if GameManager.treatRegistry.has(id):
		_enableDisable(false)
	else:
		_enableDisable(true)

func _enableDisable(enable: bool = true):
	var onWorldlayer
	if GameManager.worldLayer == 0 and underground == true:
		onWorldlayer = true
	elif GameManager.worldLayer == 1 and underground == false:
		onWorldlayer = true
	else:
		onWorldlayer = false
	set_collision_mask_value(5, enable)
	if enable and onWorldlayer:
		show()
		process_mode = PROCESS_MODE_ALWAYS
		point_light_2d.enabled = true
	else:
		hide()
		call_deferred("set_process_mode", PROCESS_MODE_DISABLED)
		point_light_2d.enabled = false
