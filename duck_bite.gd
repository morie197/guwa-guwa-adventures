extends Node2D
class_name DuckBite

@onready var duck_area = $Area2D
@onready var treat_sprite = $Area2D/Sprite2D
@onready var point_light_2d = $Area2D/PointLight2D
@onready var audio_stream_player_2d = $Area2D/AudioStreamPlayer2D

#@onready var gpu_particles_2d = $duckArea/GPUParticles2D

var id: int = 0
var underground: bool = false

var found: bool = false

var origin: Vector2

var amplitude: float = 2
var frequency: float = 1
var hoverTime: float = 0.0

#var healValue: int = 

func _ready():
	%control.visible = false
	#_updateCheck(false)
	origin = duck_area.global_position
	GameManager.loadedLevel.connect(_turnOn)
	GameManager.levelLoaded.connect(_turnOff)
	duck_area.body_entered.connect(_player_detected)
	duck_area.body_exited.connect(_player_exited)
	duck_area.area_entered.connect(_area_entered)
	duck_area.area_exited.connect(_area_exited)
	
	if name.match("duckBite"):
		id = 1
	else:
		id = name.trim_prefix("duckBite").to_int()
	
	GameManager.treatsUpdated.connect(_treatsUpdated)
	

func _process(delta):
	hoverTime += delta * frequency
	duck_area.global_position.y = origin.y + sin(hoverTime) * amplitude

func _player_detected(_body):
	if found:
		%control.visible = true
	GameManager.playerRef.quack.connect(_eat)
	
func _player_exited(_body):
	%control.visible = false
	if GameManager.playerRef.quack.is_connected(_eat):
		GameManager.playerRef.quack.disconnect(_eat)
	
func _area_entered(_area):
	#print("entered")
	GameManager.playerRef.radar.connect(_find)
	
func _area_exited(_area):
	#print("exited")
	if GameManager.playerRef.radar.is_connected(_find):
		GameManager.playerRef.radar.disconnect(_find)
	
func _find():
	#print(GameManager.duckBiteFoundRegistry)
#	print(duck_area.visible)
	if !GameManager.abilities.has("scavenge"):
		return

	if !GameManager.duckBiteFoundRegistry.has(id):
		GameManager.duckBiteFoundRegistry.append(id)
		audio_stream_player_2d.play()
		found = true
		treat_sprite.visible = true
		point_light_2d.enabled = true
	
func _eat():
	if !GameManager.abilities.has("scavenge"):
		return
		
	if !found:
		return
	
	if !GameManager.duckBiteEatenRegistry.has(id):
		GameManager.duckBiteEatenRegistry.append(id)
		GameManager.healPlayer(GameManager.hpRestoredFromTreat)
		%crunchSound.play()
		_enableDisable(false)
	
	
func _treatsUpdated():
	if GameManager.duckBiteEatenRegistry.has(id):
		_enableDisable(false)
	else:
		_enableDisable(true)
	
	if GameManager.duckBiteFoundRegistry.has(id):
		found = true
		treat_sprite.visible = true
		point_light_2d.enabled = true
	else:
		found = false
		treat_sprite.visible = false
		point_light_2d.enabled = false

func _turnOn():
	#print("turned on")
	if !GameManager.duckBiteEatenRegistry.has(id):
		#print(GameManager.treatRegistry)
		duck_area.monitoring = true
		duck_area.monitorable = true
	
func _turnOff():
	#print("turned off")
	duck_area.monitoring = false
	duck_area.monitorable = false
#
#func _updateCheck(enable: bool = true):
	#if GameManager.worldManager == null:
		#return
	#if enable:
		#treat_sprite.set_visibility_layer_bit(1, false)
	

func _enableDisable(enable: bool = true):
	##print("enable:", enable)
	var onWorldlayer
	if GameManager.worldLayer == 0 and underground == true:
		onWorldlayer = true
	elif GameManager.worldLayer == 1 and underground == false:
		onWorldlayer = true
	else:
		onWorldlayer = false
	duck_area.set_collision_mask_value(9, enable)
	#duck_area.set_collision_layer_value(1, enable)
	if enable and onWorldlayer:
		duck_area.show()
		duck_area.process_mode = PROCESS_MODE_ALWAYS
		#point_light_2d.enabled = true
	else:
		duck_area.hide()
		duck_area.call_deferred("set_process_mode", PROCESS_MODE_DISABLED)
		#point_light_2d.enabled = false
