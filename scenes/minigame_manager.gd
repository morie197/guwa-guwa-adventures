extends Node2D
			
const ENEMY_MINIGAME = preload("uid://5y4if4dkbvsj")
			
@onready var player_minigame = $PlayerMinigame
@onready var enemyGroup = $Enemies
@onready var terrain_variations = $TerrainVariations
@onready var stage_title = $PanelContainer/StageName
@onready var playerText = $PanelContainer/PlayerInfo/RichTextLabel
@onready var playerHPBar = $PanelContainer/PlayerInfo/TextureProgressBar
@onready var enemy_info = $PanelContainer/EnemyInfo
@onready var camera_2d = $Camera2D
@onready var popup_panel = $PanelContainer/PopupPanel
@onready var popup_text = $PanelContainer/PopupPanel/PopupText


const INFO_PANEL = preload("uid://dx2xq1xrwtf6t")

const LAND_FOREST = preload("uid://n0e7krhcyk3k")
const LAND_ROCKS = preload("uid://bix5b6tlxe77f")
const WATER = preload("uid://dkl8whx6w6aql")
const UNDERWATER = preload("uid://c0s32qtr7abah")

var stage: String

var speedMultiplier: float = 1.0
var	rangeMultiplier: float = 1.0
var	enduranceMultiplier: float = 1.0

var level: int = 1
var enemyCount: int = 1
var enemyHealthValues: Array[int]
var enemyNames: Array[String]

var playerPos: Vector2

var enemySpawn: Vector2 = Vector2.ZERO

@export var updateTime: float = 0.2

var updateTimer: float = 0.0

var enemyArray = []
var enemiesDefeated: int = 0

var swimming = false
var walking = false
var diving = false

var displaying = false

signal won
signal lost

@export var textDisplayTime: float = 2
		
func initValues():
	camera_2d.make_current()
	if stage == "":
		return
	var stageMap
	match stage:
		"land_forest":
			stageMap = LAND_FOREST
			stage_title.text = "Forest"
			walking = true
		"land_rocks":
			stageMap = LAND_ROCKS
			stage_title.text = "Rocks"
			walking = true
		"water":
			stageMap = WATER
			stage_title.text = "Water"
			swimming = true
		"underwater":
			stageMap = UNDERWATER
			stage_title.text = "Underwater"
			diving = true
	var map = stageMap.instantiate()
	terrain_variations.add_child(map)
	player_minigame.minigamemanager = self
	playerPos = player_minigame.global_position
	updateTimer = updateTime
	player_minigame.initValues()
	player_minigame.quacker.hp_changed.connect(_player_hp_changed)
	player_minigame.quacker.dead.connect(_lostGame)
	_player_hp_changed()
	
	for ene in enemyCount:
		var enemy = ENEMY_MINIGAME.instantiate()
		enemy.position = enemySpawn
		enemySpawn += Vector2.LEFT * 32
		enemyGroup.add_child(enemy)
		enemyArray.append(enemy)
		enemy.minigamemanager = self
		enemy.maxHealth = enemyHealthValues[ene] + round((GameManager.level/(((enemyHealthValues.size() - 1)/2.0) + 1)) / 2.0)
		enemy.speed = enemy.speed * (speedMultiplier / 2)
		enemy.initValues()
		
		var info = INFO_PANEL.instantiate()
		enemy_info.add_child(info)
		info.infoOwner = enemy.quacker
		enemy.infoBox = info
		enemy.quacker.hp_changed.connect(_hp_changed.bind(enemy.infoBox))
		info.entityName = enemyNames[ene]
		info.max_hp_value = enemy.maxHealth
		info.hpValue = enemy.quacker.health

func _hp_changed(infoBox):
	if infoBox.infoOwner.health > 0:
		infoBox.hpValue = infoBox.infoOwner.health
		
	
func _player_hp_changed():
	playerText.text = "Duck " + str(player_minigame.quacker.health) + "/" + str(player_minigame.quacker.max_health)
	playerHPBar.max_value = player_minigame.quacker.max_health
	playerHPBar.value = player_minigame.quacker.health

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if updateTimer <= 0:
		_updatePlayerPos()
	else:
		updateTimer -= delta
		
	if enemiesDefeated >= enemyCount:
		if displaying == false:
			_wonGame()
		
func _wonGame():
	if !GameManager.difficultyValue == GameManager.Difficulty.EASY:
		GameManager.healthValue = player_minigame.quacker.health
		GameManager.upgraded.emit()
		
	displaying = true
	popup_panel.visible = true
	popup_text.text = "You've defeated "
	for enemyName in enemyNames:
		if enemyNames[0] == enemyName:
			popup_text.text += enemyName
		else:
			popup_text.text += ", " + enemyName
	popup_text.text += "!"
	
	var displaytime = Timer.new()
	add_child(displaytime)
	displaytime.wait_time = textDisplayTime
	displaytime.timeout.connect(won.emit)
	displaytime.start()
		
func _lostGame():
	if !GameManager.difficultyValue == GameManager.Difficulty.EASY:
		GameManager.lostGame()
	if displaying == true:
		return
	player_minigame.hide()
	displaying = true
	popup_panel.visible = true
	popup_text.text = "You've lost to "
	for enemyName in enemyNames:
		if enemyNames[0] == enemyName:
			popup_text.text += enemyName
		else:
			popup_text.text += ", " + enemyName
	popup_text.text += "!"
	
	var displaytime = Timer.new()
	add_child(displaytime)
	displaytime.wait_time = textDisplayTime
	displaytime.timeout.connect(lost.emit)
	displaytime.start()
	
func _updatePlayerPos():
	playerPos = player_minigame.global_position
	updateTimer = updateTime
	for enemy in enemyArray:
		enemy.playerPos = playerPos
