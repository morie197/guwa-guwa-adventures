extends CanvasLayer

const LEVEL_UP_UI = preload("uid://dqqnbgo7hdj8n")
const TUTORIAL = preload("uid://dvc0qm8fmb6qj")
const ALL_TUTORIALS = preload("uid://babei73ri162t")

@onready var level_up_sound = $sounds/LevelUpSound
@onready var new_ability = $sounds/NewAbility

@onready var max_level_sound = $sounds/maxLevelSound
@onready var upgraded_sound = $sounds/upgradedSound

@onready var stamina_bar = $StaminaBar
@onready var stamina_bar_minigame = $StaminaBarMinigame
@onready var lunge_text = $StaminaBarMinigame/LungeText

var stamina: int

var tutorial
var levelUpUI

func _ready():
	GameManager.levelUp.connect(_showLevelUpUI)
	GameManager.startTutorial.connect(_startTutorial)
	GameManager.showTutorial("basics")
	
func updateStaminaBar(current: int, max: int):
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
		stamina_bar.show()
		stamina_bar_minigame.hide()
		stamina_bar.value = current
		stamina_bar.max_value = max

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
	
