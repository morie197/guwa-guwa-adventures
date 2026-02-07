extends Node2D

@onready var point_light_2d = $duckArea/PointLight2D
@onready var duck_treat_sound = $duckArea/duckTreatSound
@onready var map_check = $mapCheck
@onready var duck_area = $duckArea


var hidden_treat_sound: float = -6

@export var undergroundEnergy: float = 1.0
@export var hiddenTreat = false
@export var movingTreat = false

var origin: Vector2

var amplitude: float = 10
var frequency: float = 2
var hoverTime: float = 0.0
var id: int = 0
var underground: bool = false

var mapCheckRef

func _ready():
	mapCheckRef = map_check
	_updateCheck(false)
	duck_area.body_entered.connect(_player_entered)
	origin = duck_area.global_position
	if name.match("duckTreat"):
		id = 1
	else:
		id = name.trim_prefix("duckTreat").to_int()
	
	if hiddenTreat:
		duck_treat_sound.volume_db = hidden_treat_sound
	
	GameManager.treatsUpdated.connect(_treatsUpdated)

func _process(delta):
	if movingTreat:
		return
	hoverTime += delta * frequency
	duck_area.global_position.y = origin.y + sin(hoverTime) * amplitude
	

func _player_entered(body: Node2D):
	GameManager.treatGet()
	GameManager.treatRegistry.append(id)
	_updateCheck(true)
	_enableDisable(false)
	
func _treatsUpdated():
	duck_area.monitoring = true
	if GameManager.treatRegistry.has(id):
		_updateCheck(true)
		_enableDisable(false)
	else:
		_updateCheck(false)
		_enableDisable(true)

func _updateCheck(enable: bool = true):
	if enable:
		mapCheckRef.show()
		if GameManager.worldManager == null:
			print("returning")
			return
		if underground:
			mapCheckRef.reparent(GameManager.worldManager.underMap)
		else:
			mapCheckRef.reparent(GameManager.worldManager.overMap)
	else:
		if mapCheckRef.get_parent() != self:
			mapCheckRef.reparent(self)
		mapCheckRef.hide()
			

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
