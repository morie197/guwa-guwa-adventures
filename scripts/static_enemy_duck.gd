extends Node2D
class_name StaticDuck

@onready var quack_detector = $quackDetector
@onready var collider = $collider

const DUCK_CONTAINER = preload("uid://cnvkkjoe28ls3")

@export var duckNames: Array[String]
@export var duckHP: Array[int]
@export var duckATK: Array[int]
@export var duckSPD: Array[int]
@export var duckRAN: Array[int]
@export var stageName: String = "land_forest"

@export var direction: Vector2 = Vector2.LEFT

var duckContainer

@export var owners: Array[Node2D]

var id: int = 0
var underground: bool = false

func _ready():
	quack_detector.area_entered.connect(_player_detected)
	quack_detector.area_exited.connect(_player_exited)
	global_rotation_degrees = 0
	
	if name.match("StaticEnemyDuck"):
		id = 1
	else:
		id = name.trim_prefix("StaticEnemyDuck").to_int()
	
	GameManager.treatsUpdated.connect(_ducksUpdated)

func _player_detected(_area):
	if GameManager.playerRef != null:
		GameManager.playerRef.quack.connect(_quack)
		if duckContainer == null:
			_duckWindowPopup()
	if GameManager.healthValue > 3:
		if GameManager.abilities.has("quack"):
			SaveManager.autoSave()
	
func _duckWindowPopup():
	for i in duckNames.size():
		var duckyCont = DUCK_CONTAINER.instantiate()
		owners[i].add_child(duckyCont)
		duckyCont.duckName.text = str(duckNames[i])
		duckyCont.duckhp.text = "HP: " + str(duckHP[i])
		duckyCont.duckatk.text = "ATK: " + str(duckATK[i])
		duckyCont.duckspd.text = "SPD: " + str(duckSPD[i])
		duckyCont.duckrange.text = "RAN: " + str(duckRAN[i])
		
		duckyCont.global_position = owners[i].global_position
		duckyCont.position.x -= duckyCont.size.x/2.0
		duckyCont.position += Vector2.RIGHT * 64
		owners[i].duckContainer = duckyCont
	
	
func _player_exited(_area):
	if GameManager.playerRef != null:
		GameManager.playerRef.quack.disconnect(_quack)
		for duck in owners:
			if duck.duckContainer != null:
				duck.duckContainer.queue_free()
				duck.duckContainer = null

func _quack():
	if duckNames.size() > 0 and GameManager.minigame == false and GameManager.lost == false:
		GameManager.initiateMinigame(duckNames, duckHP, duckATK, duckSPD, duckRAN, stageName, owners)
	
func playerWon():
	_exitMinigame()
	GameManager.duckRegistry.append(id)
	SaveManager.autoSave(true)
	_enableDisable(false)
	
func playerLost():
	_exitMinigame()

func _exitMinigame():
	GameManager.paused = false
	GameManager.minigame = false
	if GameManager.worldLayer == 0:
		GameManager.worldManager.darkener.show()
	GameManager.worldManager.ui_manager.stamina_bar.show()
	GameManager.worldManager.ui_manager.stamina_bar_minigame.hide()
	
func _ducksUpdated():
	if GameManager.duckRegistry.has(id):
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
		
	collider.set_collision_layer_value(1, enable)
	quack_detector.set_collision_mask_value(6, enable)
	
	if enable and onWorldlayer:
		show()
		process_mode = PROCESS_MODE_ALWAYS
	else:
		hide()
		process_mode = PROCESS_MODE_DISABLED
	
