extends CanvasLayer

const LEVEL_UP_UI = preload("uid://dqqnbgo7hdj8n")
const TUTORIAL = preload("uid://dvc0qm8fmb6qj")
const ALL_TUTORIALS = preload("uid://babei73ri162t")
const CREDITS = preload("uid://26t45ci53pbw")

@onready var game_won_bgm = $sounds/gameWonBGM
@onready var winpanel = $winpanel

@onready var level_up_sound = $sounds/LevelUpSound
@onready var new_ability = $sounds/NewAbility

@onready var max_level_sound = $sounds/maxLevelSound
@onready var upgraded_sound = $sounds/upgradedSound
@onready var migrate_down_indicator = $MigrateDownIndicator

@onready var stamina_bar = $StaminaBar
@onready var stamina_bar_minigame = $StaminaBarMinigame
@onready var lunge_text = $StaminaBarMinigame/LungeText
@onready var migrate_bar = $MigrateBar

var stamina: int

var tutorial
var levelUpUI

var credits

var hoverState: float = 0
var hoverTime: float = 0.2
var creditScreenOffset = 1480
var creditScrollSpeed: float = 90
var bgmFadeTime: float = 0.2
var bgmVolume: float = -8
var hoverSpeed: float = 1
var hoverAmount: float = 5
var origin: Vector2

@export var targetModulateColor: Color = Color.BLACK

@export var modulateSpeed: float = 0.9

func _ready():
	GameManager.levelUp.connect(_showLevelUpUI)
	GameManager.startTutorial.connect(_startTutorial)
	GameManager.showTutorial("basics")
	origin = migrate_down_indicator.global_position
	
func _physics_process(delta):
	if credits != null:
		if winpanel.modulate != targetModulateColor:
			winpanel.modulate = winpanel.modulate.lerp(targetModulateColor, delta * modulateSpeed)
		credits.global_position.y -= (creditScrollSpeed * delta)
		game_won_bgm.volume_db = lerp(game_won_bgm.volume_db, bgmVolume, bgmFadeTime * delta )
	
	if hoverState == 1:
		hoverTime += delta
		if hoverTime >= hoverSpeed:
			hoverState = -1
	else:
		hoverTime -= delta
		if hoverTime <= -hoverSpeed:
			hoverState = 1
	migrate_down_indicator.global_position.y = origin.y + (hoverTime * hoverAmount)
	
func updateStaminaBar(current: int, max: int):
	if GameManager.wonGame == true:
		stamina_bar.hide()
		return
	if GameManager.minigame == true:
		stamina_bar.hide()
		stamina_bar_minigame.show()
		stamina_bar_minigame.value = current
		stamina_bar_minigame.max_value = max
		if current >= max - 1:
			lunge_text.show()
		else:
			if lunge_text.visible:
				lunge_text.hide()
	else:
		if GameManager.abilities.has("sprint"):
			stamina_bar.show()
			stamina_bar.value = current
			stamina_bar.max_value = max
		stamina_bar_minigame.hide()
		
func updateMigrateBar(current: int, maxVal: int):
	if current > maxVal/20.0:
		migrate_bar.show()
		if GameManager.playerRef.moveVector.y > 0:
			migrate_down_indicator.hide()
		else:
			migrate_down_indicator.show()
	else:
		migrate_bar.hide()
		migrate_down_indicator.hide()
	migrate_bar.max_value = maxVal
	migrate_bar.value = maxVal - current

func gameWon():
	migrate_bar.hide()
	stamina_bar.hide()
	migrate_down_indicator.hide()
	if credits != null:
		credits.queue_free()
	credits = CREDITS.instantiate()
	add_child(credits)
	credits.position.y += creditScreenOffset
	game_won_bgm.volume_db = -60.0
	game_won_bgm.play()

func _showLevelUpUI():
	GameManager.paused = true

	if level_up_sound.playing == true or new_ability.playing == true:
		level_up_sound.stop()
		new_ability.stop()
		
	if AbilityData.ABILITIES.has(GameManager.level):
		#level_up_sound_2.play()
		new_ability.play()
	else:
		level_up_sound.play()
	
	
	if levelUpUI != null:
		levelUpUI.queue_free()
	levelUpUI = LEVEL_UP_UI.instantiate()
	levelUpUI.masterUIManager = self
	add_child(levelUpUI)
	
func _startTutorial(tutorialName: String):
	if tutorial != null:
		return
	tutorial = TUTORIAL.instantiate()
	add_child(tutorial)
	if !ALL_TUTORIALS.tutorials.has(tutorialName):
		print("No tutorial with name: ", tutorialName)
		return
	tutorial.setData(ALL_TUTORIALS.tutorials[tutorialName])
	
