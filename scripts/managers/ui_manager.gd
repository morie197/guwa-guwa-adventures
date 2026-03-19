extends CanvasLayer

const LEVEL_UP_UI = preload("uid://dqqnbgo7hdj8n")
const TUTORIAL = preload("uid://dvc0qm8fmb6qj")
const ALL_TUTORIALS = preload("uid://babei73ri162t")
const CREDITS = preload("uid://26t45ci53pbw")
const PAUSE_MENU = preload("uid://x4vnr5iy3hg3")
const HP_BAR_PART = preload("uid://cgofcggcnhupr")
const SAVE_LOAD_MENU = preload("uid://b8nmevsdid6a6")
const POPUP = preload("uid://cd68megybdr25")

const HPPART = preload("uid://dpew5sdxiu3ji")
const HPPARTEMPTY = preload("uid://bnx8opkaadiwv")

@onready var lostpanel = $lostpanel
@onready var minimap_camera = %minimapCamera

@onready var switch = %switch

@onready var progress_to_complete_percent = %ProgressToCompletePercent

var inPopup: bool = false

@onready var progress_to_completion = %progressToCompletion

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
@onready var until_next_goal = $HUD/VBoxContainer/HBoxContainer2/untilNextGoal

@onready var minimap = %minimap
@onready var mini_map_panel = %MiniMapPanel
@onready var showmap_text = %showmapText

@onready var hp_text = %HPText
@onready var hp_bars = %HPBars

@onready var radar_ready = %radarReady

@onready var loadGame = $lostpanel/VBoxContainer2/VBoxContainer/load
@onready var quit = $lostpanel/VBoxContainer2/VBoxContainer/quit

@onready var hud = %HUD

var creditContentSize: float = 0


var stamina: int

var tutorial
var levelUpUI

var credits

var saveLoadMenu

var hoverState: float = 0
var hoverTime: float = 0.2
var creditScreenOffset = 1480
var creditScrollSpeed: float = 90
var bgmFadeTime: float = 0.2
var bgmVolume: float = -8
var hoverSpeed: float = 1
var hoverAmount: float = 5
var origin: Vector2

var creditSkipSpeed: float = 20

var inPauseMenu: bool = false
var pauseMenu

var ui_manager = self

var collectedAll: bool = false

var hpBars: Array[Node] = []

@export var targetModulateColor: Color = Color.BLACK

@export var modulateSpeed: float = 0.9

func _ready():
	mini_map_panel.hide()
	%showmapText.visible = false
	updateNextAbility()
	%winpanel.hide()
	
	if GameManager.difficultyValue == GameManager.Difficulty.EASY:
		hp_text.hide()
		hp_bars.hide()
	else:
		_updateMaxHP()
	
	GameManager.levelUp.connect(_showLevelUpUI)
	GameManager.startTutorial.connect(_startTutorial)
	GameManager.upgraded.connect(_updateMaxHP)
	GameManager.loadedLevel.connect(_updateGoal)
	GameManager.levelUp.connect(_updateGoal)
	origin = migrate_down_indicator.global_position
	
	for bar in hp_bars.get_children():
		hpBars.append(bar)
		
	loadGame.pressed.connect(_load)
	quit.pressed.connect(_quit)
	
	if GameManager.abilities.has("sprint"):
		stamina_bar.show()
	else:
		stamina_bar.hide()


func _unhandled_input(event):
	if Input.is_action_just_pressed("closeMap"):
		if GameManager.abilities.has("map"):
			mini_map_panel.visible = !mini_map_panel.visible
			%showmapText.visible = !mini_map_panel.visible
			%showmapText.text = tr("SHOW_MINIMAP") + "H"

func updateNextAbility():
	until_next_ability.text = ""
	for ability in AbilityData.ABILITIES:
		if GameManager.level >= ability:
			continue
		else:
			until_next_ability.text = tr(AbilityData.ABILITIES[ability]["displayName"]) + ": " + str(ability)
			break
	
	#if GameManager.level <= 40:
		#until_next_goal.text = tr("MIGRATION_GOAL")
	#elif GameManager.level <= 90 and GameManager.worldManager.levelName == "Hidden Grove":
		#until_next_goal.text = tr("MIGRATION_BACK_GOAL")
	#else:
		#until_next_goal.text = tr("ALL_TREAT_GOAL")
	
func _physics_process(delta):
	if credits != null:
		if tutorial:
			tutorial.queue_free()
		if winpanel.modulate != targetModulateColor:
			winpanel.modulate = winpanel.modulate.lerp(targetModulateColor, delta * modulateSpeed)
		if Input.is_action_pressed("nextTutorialItem"):
			credits.global_position.y -= (creditScrollSpeed * delta * creditSkipSpeed)
		else:
			credits.global_position.y -= (creditScrollSpeed * delta)
		game_won_bgm.volume_db = lerp(game_won_bgm.volume_db, bgmVolume, bgmFadeTime * delta )
		
		if -credits.global_position.y > creditContentSize:
			if Input.is_action_pressed("nextTutorialItem"):
				game_won_bgm.volume_db -= 1
			game_won_bgm.volume_db = lerp(game_won_bgm.volume_db, -80.0, bgmFadeTime * delta )
			#print(game_won_bgm.volume_db)
			winpanel.modulate = winpanel.modulate.lerp(Color.BLACK, delta * modulateSpeed)
			if game_won_bgm.volume_db < -40:
				if GameManager.playerCamCredits != null:		
					if !GameManager.playerCamCredits.is_queued_for_deletion():
						GameManager.playerCamCredits.queue_free()
				var ind = AudioServer.get_bus_index("SFX")
				AudioServer.set_bus_mute(ind, false)
				GameManager.wonGame = false
				get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
	
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
		hp_bars.hide()
		hp_text.hide()
		return
		
	if maxHP >= 25:
		hp_bars.custom_minimum_size.y = 60
		hp_bars.add_theme_constant_override("separation", -34)
	else:
		hp_bars.custom_minimum_size.y = 70
		hp_bars.add_theme_constant_override("separation", -38)
		
	hp_bars.show()
	hp_text.show()
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
	
	if GameManager.difficultyValue == GameManager.Difficulty.EASY:
		hp_bars.hide()
		hp_text.hide()
		return
	
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
	if visible == false:
		visible = true
	#print("pause called")
	#print(inPauseMenu)
	if !inPauseMenu:
		inPauseMenu = true
		GameManager.paused = true
		GameManager.playerRef.healTimer.paused = true
		pauseMenu = PAUSE_MENU.instantiate()
		pauseMenu.ui_manager = self
		add_child(pauseMenu)
	else:
		if pauseMenu != null and !pauseMenu.is_queued_for_deletion():
			#print("unpaused")
			GameManager.paused = false
			GameManager.playerRef.healTimer.paused = false
			inPauseMenu = false
			pauseMenu.queue_free()
			
func closeLoadSave():
	GameManager.paused = false
	GameManager.playerRef.healTimer.paused = false
	GameManager.lost = false
	saveLoadMenu.queue_free()
	lostpanel.hide()
	_inPopup()

func _load():
	if saveLoadMenu != null:
		saveLoadMenu.queue_free()
	saveLoadMenu = SAVE_LOAD_MENU.instantiate()
	saveLoadMenu.mode = "load"
	add_child(saveLoadMenu)
	saveLoadMenu.parentMenu = self
	_inPopup()
	
func _quit():
	GameManager.paused = false
	GameManager.lost = false
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")

func _inPopup():
	inPopup = !inPopup
	var buttons = [loadGame , quit]
	if SaveManager.check_save() == false:
		buttons.erase(loadGame)
	for button in buttons:
		button.disabled = inPopup			
	
func updateStaminaBar(current: int, max: int):
	if GameManager.playerRef == null:
		return
	
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
			stamina_bar.value = current + 40
			stamina_bar.max_value = max + 40
			if GameManager.playerRef.tired and current < max - 60:
				stamina_bar.modulate = Color.DIM_GRAY
			else:
				stamina_bar.modulate = Color.WHITE
		stamina_bar_minigame.hide()
		
func updateMigrateBar(current: int, maxVal: int):
	if current > maxVal/20.0:
		migrate_bar.show()
	else:
		migrate_bar.hide()
	migrate_bar.max_value = maxVal
	migrate_bar.value = maxVal - current

func gameLost():
	lostpanel.show()

func gameWon():
	migrate_bar.hide()
	stamina_bar.hide()
	%winpanel.show()
	migrate_down_indicator.hide()
	if credits != null:
		credits.queue_free()
	credits = CREDITS.instantiate()
	add_child(credits)
	credits.position.y += creditScreenOffset
	game_won_bgm.volume_db = -60.0
	game_won_bgm.play()
	
	creditContentSize = 7500

func _updateGoal():
	collected_number.add_theme_color_override("default_color", Color.WHITE)
	
	if GameManager.difficultyValue == GameManager.Difficulty.HARD:
		%treatIcon.material.set_shader_parameter("uv_offset", Color(1, 0.0, 0.0, 1.0))
	else:
		%treatIcon.material.set_shader_parameter("uv_offset", Color(0, 0, 0, 1))
	
	if GameManager.level <= 40:
		until_next_goal.text = tr("MIGRATION_GOAL")
	elif GameManager.worldManager.levelName == "Hidden Grove" and GameManager.level <= 90:
		until_next_goal.text = tr("MIGRATION_BACK_GOAL")
	else:
		until_next_goal.text = tr("ALL_TREAT_GOAL")
	
	if GameManager.level > 40:
		progress_to_completion.self_modulate = Color.TEAL
		if GameManager.worldManager.levelName == "Quiet Gardens":
			if GameManager.level >= 65:
				collected_number.add_theme_color_override("default_color", Color.BLUE)
				collectedAll = true
			progress_to_completion.max_value = 65.0
			progress_to_complete_percent.max_value = 65.0
		elif GameManager.worldManager.levelName == "Hidden Grove":
			if GameManager.level <= 90:
				progress_to_completion.max_value = 90.0
				progress_to_complete_percent.max_value = 90.0
			elif 35 - GameManager.treatRegistry.size() > 0:
				progress_to_completion.max_value = 35 + (GameManager.level - GameManager.treatRegistry.size())
				progress_to_complete_percent.max_value =  35 + (GameManager.level - GameManager.treatRegistry.size())
			elif 35 - GameManager.treatRegistry.size() <= 0:
				collected_number.add_theme_color_override("default_color", Color.BLUE)
				collectedAll = true
				
				
		else:
			if GameManager.level >= 65:
				collected_number.add_theme_color_override("default_color", Color.BLUE)
				collectedAll = true
			progress_to_completion.max_value = 65.0
			progress_to_complete_percent.max_value = 65.0
		
	else:
		progress_to_completion.max_value = 40.0
		progress_to_complete_percent.max_value = 40.0
		
	progress_to_completion.value = GameManager.level
	progress_to_complete_percent.value = GameManager.level
	
	updateNextAbility()
	

func _showLevelUpUI():
	collected_number.text = str(GameManager.level)
	
	if GameManager.availableUpgradePoints <= 0:
		return
	
	print(GameManager.availableUpgradePoints)
	
	GameManager.paused = true
	GameManager.playerRef.healTimer.paused = true
	
	var foundNextAbility = false
	
	for ability in AbilityData.ABILITIES:
		if GameManager.level >= ability:
			continue
		else:
			until_next_ability.text = tr(AbilityData.ABILITIES[ability]["displayName"]) + ": " + str(ability)
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
		tutorial.queue_free()
		#return
	tutorial = TUTORIAL.instantiate()
	hud.add_child(tutorial)
	if !ALL_TUTORIALS.tutorials.has(tutorialName):
		print("No tutorial with name: ", tutorialName)
		return
	tutorial.setData(ALL_TUTORIALS.tutorials[tutorialName])
	
