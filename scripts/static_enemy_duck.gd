extends Node2D
class_name StaticDuck

@onready var quack_detector = $quackDetector
@onready var collider = $collider

@export var duckNames: Array[String] = ["Jerry"]
@export var duckHP: Array[int] = [5]
@export var stageName: String = "land_forest"

@export var owners: Array[Node2D] = [self]

var id: int = 0
var underground: bool = false

func _ready():
	quack_detector.area_entered.connect(_player_detected)
	quack_detector.area_exited.connect(_player_exited)
	
	if name.match("StaticEnemyDuck"):
		id = 1
	else:
		id = name.trim_prefix("StaticEnemyDuck").to_int()
	
	GameManager.treatsUpdated.connect(_ducksUpdated)

func _player_detected(_area):
	if GameManager.playerRef != null:
		GameManager.playerRef.quack.connect(_quack)
		
	SaveManager.autoSave()
	
func _player_exited(_area):
	if GameManager.playerRef != null:
		GameManager.playerRef.quack.disconnect(_quack)

func _quack():
	if duckNames.size() > 0 and GameManager.minigame == false:
		GameManager.initiateMinigame(duckNames, duckHP, stageName, owners)
	
func playerWon():
	_exitMinigame()
	GameManager.duckRegistry.append(id)
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
	
