extends Node2D
class_name StaticDuck

@onready var quack_detector = $quackDetector
@onready var collider = $collider

@onready var water_sprite = %waterSprite
@onready var land_sprite = %landSprite

@onready var polygon_2d = $Polygon2D


const DUCK_CONTAINER = preload("uid://cnvkkjoe28ls3")

@export var duckNames: Array[String]
@export var duckHP: Array[int]
@export var duckATK: Array[int]
@export var duckSPD: Array[int]
@export var duckRAN: Array[int]
@export var stageName: String = "land_forest"
@export var revealedAreas: Array[Node2D]

var hardAddHP: int = 5
var hardAddATK: int = 1
var hardAddSPD: int = 2
var hardAddRAN: int = 1


var duckHPFinal: Array
var duckATKFinal: Array
var duckSPDFinal: Array
var duckRANFinal: Array

@export var facingLeft: bool = false

var activationDistance: float = 350

@export var landDuck: bool = false

var duckContainer
var detected: bool = false

@export var owners: Array[Node2D]
@export var inBreathable: bool = true

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
	GameManager.changeBreathableLayer.connect(_breathLayerChanged)
	
	if facingLeft:
		%waterSprite.flip_h = true
		%landSprite.flip_h = true
		
	GameManager.moved.connect(_updateDirection)
	
	GameManager.levelLoaded.connect(_ducksUpdated)

func _breathLayerChanged(breathable: bool = false):
	#print(GameManager.worldLayer)
	if (breathable and inBreathable) or GameManager.worldLayer == 1:
		land_sprite.modulate = Color.WHITE
		water_sprite.modulate = Color.WHITE
	else:
		land_sprite.modulate = Color.TRANSPARENT
		water_sprite.modulate = Color.TRANSPARENT

func _updateDirection():
	if %landSprite.visible:
		%waterSprite.visible = false
	elif %waterSprite.visible:
		%landSprite.visible = false
	if GameManager.playerRef != null and detected:
		if GameManager.playerRef.global_position.distance_to(global_position) < activationDistance:
			if GameManager.playerRef.global_position.x < global_position.x:
				%waterSprite.flip_h = true
				%landSprite.flip_h = true
			else:
				%waterSprite.flip_h = false
				%landSprite.flip_h = false

	

func _player_detected(_area):
	detected = true
	if landDuck:
		%landSprite.visible = true
		%waterSprite.visible = false
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
		duckyCont.duckhp.text = tr("DUCK_HP_STAT") + str(duckHPFinal[i])
		duckyCont.duckatk.text = tr("DUCK_ATK_STAT") + str(duckATKFinal[i])
		duckyCont.duckspd.text = tr("DUCK_SPD_STAT") + str(duckSPDFinal[i])
		duckyCont.duckrange.text = tr("DUCK_RAN_STAT") + str(duckRANFinal[i])
		
		duckyCont.global_position = owners[i].global_position
		duckyCont.position.x -= duckyCont.size.x/2.0
		duckyCont.position += Vector2.RIGHT * 64
		owners[i].duckContainer = duckyCont
	
	
func _player_exited(_area):
	detected = false
	if GameManager.playerRef != null:
		GameManager.playerRef.quack.disconnect(_quack)
		for duck in owners:
			if duck.duckContainer != null:
				duck.duckContainer.queue_free()
				duck.duckContainer = null
				
	if GameManager.duckRegistry.has(id):
		%landSprite.visible = false
		%waterSprite.visible = false
		return
	if landDuck:
		%landSprite.visible = false
		%waterSprite.visible = true

func _quack():
	if duckNames.size() > 0 and GameManager.minigame == false and GameManager.lost == false:
		GameManager.initiateMinigame(duckNames, duckHPFinal, duckATKFinal, duckSPDFinal, duckRANFinal, stageName, owners)
	
func playerWon():
	_exitMinigame()
	for area in revealedAreas:
		if area is HiddenArea:
			area._showarea()
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
	if GameManager.difficultyValue == GameManager.Difficulty.HARD:
		if owners.size() <= 3:
			duckHPFinal = duckHP.map(func(n): return n + hardAddHP)
			duckATKFinal = duckATK.map(func(n): return n + hardAddATK)
			duckSPDFinal = duckSPD.map(func(n): return n + hardAddSPD)
			duckRANFinal = duckRAN.map(func(n): return n + hardAddRAN)
		else:
			duckHPFinal = duckHP.map(func(n): return n + hardAddHP)
			duckATKFinal = duckATK.duplicate()
			duckSPDFinal = duckSPD.map(func(n): return n + roundi(hardAddSPD/2.0))
			duckRANFinal = duckRAN.duplicate()
	else:
		duckHPFinal = duckHP.duplicate()
		duckATKFinal = duckATK.duplicate()
		duckSPDFinal = duckSPD.duplicate()
		duckRANFinal = duckRAN.duplicate()
	
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
	polygon_2d.visible = enable
	
	if enable and onWorldlayer:
		water_sprite.visible = true
		process_mode = PROCESS_MODE_ALWAYS
	else:
		water_sprite.visible = false
		process_mode = PROCESS_MODE_DISABLED
	
