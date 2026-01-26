extends CanvasLayer

const LEVEL_UP_UI = preload("uid://dqqnbgo7hdj8n")
const TUTORIAL = preload("uid://dvc0qm8fmb6qj")
const ALL_TUTORIALS = preload("uid://babei73ri162t")
const CREDITS = preload("uid://26t45ci53pbw")
const PAUSE_MENU = preload("uid://x4vnr5iy3hg3")
const HP_BAR_PART = preload("uid://cgofcggcnhupr")

const HPPART = preload("uid://dpew5sdxiu3ji")
const HPPARTEMPTY = preload("uid://bnx8opkaadiwv")

@onready var game_won_bgm = $sounds/gameWonBGM
@onready var winpanel = $winpanel

@onready var level_up_sound = $sounds/LevelUpSound
@onready var new_ability = $sounds/NewAbility

@onready var max_level_sound = $sounds/maxLevelSound
@onready var upgraded_sound = $sounds/upgradedSound
@onready var migrate_down_indicator = $MigrateDownIndicator

@onready var stamina_bar = %StaminaBar
@onready var stamina_bar_minigame = $StaminaBarMinigame
@onready var lunge_text = $StaminaBarMinigame/LungeText
@onready var migrate_bar = $MigrateBar

@onready var collected_number = %collectedNumber
@onready var until_next_ability = %untilNextAbility

@onready var hp_text = %HPText
@onready var hp_bars = %HPBars

@onready var hud = %HUD


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

var inPauseMenu: bool = false
var pauseMenu

var hpBars: Array[Node] = []

@export var targetModulateColor: Color = Color.BLACK

@export var modulateSpeed: float = 0.9

func _ready():
	if GameManager.difficultyValue == GameManager.Difficulty.EASY:
		hp_text.hide()
		hp_bars.hide()
	else:
		_updateMaxHP()
	
	GameManager.levelUp.connect(_showLevelUpUI)
	GameManager.startTutorial.connect(_startTutorial)
	GameManager.upgraded.connect(_updateMaxHP)
	GameManager.showTutorial("basics")
	origin = migrate_down_indicator.global_position
	
	for bar in hp_bars.get_children():
		hpBars.append(bar)
	
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
	
func _updateMaxHP():
	var maxHP = GameManager.maxHP
	
	if GameManager.difficultyValue == GameManager.Difficulty.EASY:
		hp_text.hide()
		return
	hp_text.text = "HP: " + str(GameManager.healthValue) + "/" + str(maxHP)
	
	for hpbar in hpBars:
		hpbar.queue_free()
	
	hpBars = []
	
	for i in range(0, maxHP):
		#print(i)
		var hpbar = HP_BAR_PART.instantiate()
		hp_bars.add_child(hpbar)
		hpBars.append(hpbar)
		
	_updateHP()
	
	
func _updateHP():
	var maxHP = GameManager.maxHP
	
	if GameManager.healthValue > maxHP:
		#print("over max HP!")
		return
	
	#print(GameManager.healthValue)
	#print(maxHP)
	
	for i in range(0, GameManager.healthValue - 1):
		#print(i)
		#print(hpBars.size())
		#if hpBars.size() - 1 > i:
		#	print("invalid index")
		#	return
		hpBars[i].texture = HPPART
	
	for lostHealth in range(maxHP, GameManager.healthValue, -1):
		#print(lostHealth)
		hpBars[lostHealth - 1].texture = HPPARTEMPTY
	
func pause():
	#print("pause called")
	#print(inPauseMenu)
	if !inPauseMenu:
		inPauseMenu = true
		GameManager.paused = true
		pauseMenu = PAUSE_MENU.instantiate()
		pauseMenu.ui_manager = self
		add_child(pauseMenu)
	else:
		if pauseMenu != null and !pauseMenu.is_queued_for_deletion():
			#print("unpaused")
			GameManager.paused = false
			inPauseMenu = false
			pauseMenu.queue_free()
			
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
	
	collected_number.text = str(GameManager.level)
	
	var foundNextAbility = false
	
	for ability in AbilityData.ABILITIES:
		if GameManager.level >= ability:
			continue
		else:
			until_next_ability.text = "Next ability at: " + str(ability)
			foundNextAbility = true
			break
			
	if foundNextAbility == false:
		until_next_ability.hide()

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
	
