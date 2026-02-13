extends Node2D
class_name DuckTreat

@onready var point_light_2d = $duckArea/PointLight2D
@onready var duck_treat_sound = $duckArea/duckTreatSound
@onready var map_check = $mapCheck
@onready var duck_area = $duckArea
@onready var treat_sprite = $duckArea/Sprite2D

const TREAT_MAP_INDICATOR = preload("uid://luhbyxeky4e2")

var hidden_treat_sound: float = -6

@export var undergroundEnergy: float = 1.0
@export var hiddenTreat = false
@export var movingTreat = false

var origin: Vector2
var mapTreatIcon

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
	if GameManager.worldManager == null:
		print("returning")
		return
	if enable:
		treat_sprite.set_visibility_layer_bit(1, false)
		showOnMap(false)
		mapCheckRef.show()
		if underground:
			mapCheckRef.reparent(GameManager.worldManager.underMap)
		else:
			mapCheckRef.reparent(GameManager.worldManager.overMap)
	else:
		showOnMap(true)
		if mapCheckRef.get_parent() != self:
			mapCheckRef.reparent(self)
		mapCheckRef.hide()
			
func showOnMap(show: bool = true):
	if mapTreatIcon == null:
		mapTreatIcon = TREAT_MAP_INDICATOR.instantiate()
		mapTreatIcon.scale *= 2
		mapTreatIcon.set_visibility_layer_bit(0, false)
		mapTreatIcon.set_visibility_layer_bit(1, true)
		if underground:
			GameManager.worldManager.underMap.add_child(mapTreatIcon)
		else:
			GameManager.worldManager.overMap.add_child(mapTreatIcon)
		mapTreatIcon.global_position = global_position
		mapTreatIcon.target = self
	
	if show:
		mapTreatIcon.show()
	else:
		mapTreatIcon.hide()
		
		
	
		
	print("showing on map")
	

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
