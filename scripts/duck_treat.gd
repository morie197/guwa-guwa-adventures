extends Node2D

@onready var point_light_2d = $duckArea/PointLight2D
@onready var duck_treat_sound = $duckArea/duckTreatSound
@onready var map_check = $mapCheck
@onready var duck_area = $duckArea


var hidden_treat_sound: float = -6

@export var undergroundEnergy: float = 1.0
@export var hiddenTreat = false

var origin: Vector2

var amplitude: float = 10
var frequency: float = 2
var hoverTime: float = 0.0
var id: int = 0
var underground: bool = false

func _ready():
	map_check.hide()
	duck_area.body_entered.connect(_player_entered)
	origin = global_position
	if name.match("duckTreat"):
		id = 1
	else:
		id = name.trim_prefix("duckTreat").to_int()
	
	if hiddenTreat:
		duck_treat_sound.volume_db = hidden_treat_sound
	
	GameManager.treatsUpdated.connect(_treatsUpdated)

func _process(delta):
	hoverTime += delta * frequency
	position.y = origin.y + sin(hoverTime) * amplitude
	

func _player_entered(body: Node2D):
	GameManager.treatGet()
	GameManager.treatRegistry.append(id)
	map_check.show()
	_enableDisable(false)
	
func _treatsUpdated():
	duck_area.monitoring = true
	if GameManager.treatRegistry.has(id):
		map_check.show()
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
	duck_area.set_collision_mask_value(5, enable)
	if enable and onWorldlayer:
		duck_area.show()
		duck_area.process_mode = PROCESS_MODE_ALWAYS
		point_light_2d.enabled = true
	else:
		duck_area.hide()
		duck_area.call_deferred("set_process_mode", PROCESS_MODE_DISABLED)
		point_light_2d.enabled = false
