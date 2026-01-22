extends Node2D

@onready var quack_detector = $quackDetector
@onready var collider = $collider

@export var duckNames: Array[String] = ["Jerry"]
@export var duckHP: Array[int] = [5]
@export var stageName: String = "land_forest"

@export var owners: Array[Node2D] = [self]

func _ready():
	quack_detector.area_entered.connect(_player_detected)
	quack_detector.area_exited.connect(_player_exited)

func _player_detected(_area):
	if GameManager.playerRef != null:
		GameManager.playerRef.quack.connect(_quack)
	
func _player_exited(_area):
	if GameManager.playerRef != null:
		GameManager.playerRef.quack.disconnect(_quack)

	
func _quack():
	if duckNames.size() > 0 and GameManager.minigame == false:
		GameManager.initiateMinigame(duckNames, duckHP, stageName, owners)
	
func playerWon():
	_exitMinigame()
	collider.set_collision_layer_value(1, false)
	quack_detector.set_collision_mask_value(6, false)
	hide()
	
func playerLost():
	_exitMinigame()

func _exitMinigame():
	GameManager.paused = false
	GameManager.minigame = false
	if GameManager.worldLayer == 0:
		GameManager.worldManager.darkener.show()
	GameManager.worldManager.ui_manager.stamina_bar.show()
	GameManager.worldManager.ui_manager.stamina_bar_minigame.hide()
	
