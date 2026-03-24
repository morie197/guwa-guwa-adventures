extends PanelContainer

@onready var resume = $PanelContainer/VBoxContainer/resume
@onready var save = $PanelContainer/VBoxContainer/save
@onready var loadGame = $PanelContainer/VBoxContainer/load
@onready var settingsButton = $PanelContainer/VBoxContainer/settings
@onready var quit = $PanelContainer/VBoxContainer/quit

@onready var key_presses = $MarginContainer/keyPresses

const POPUP = preload("uid://cd68megybdr25")
const KEY_PRESS_DISPLAY = preload("uid://cu2qa7tl2feks")
const SETTINGS_MENU = preload("uid://dnkbdoidjjxng")
const SAVE_LOAD_MENU = preload("uid://b8nmevsdid6a6")

var ui_manager
var inPopup: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	resume.pressed.connect(_resume)
	settingsButton.pressed.connect(_settings)
	save.pressed.connect(_save)
	loadGame.pressed.connect(_load)
	quit.pressed.connect(_quit)
	
	resume.mouse_entered.connect(%hoversound.play)
	settingsButton.mouse_entered.connect(%hoversound.play)
	save.mouse_entered.connect(%hoversound.play)
	loadGame.mouse_entered.connect(%hoversound.play)
	quit.mouse_entered.connect(%hoversound.play)
	
	if SaveManager.check_save() == false:
		loadGame.disabled = true
		
	if GameManager.difficultyValue == GameManager.Difficulty.HARD:
		save.disabled = true
		
	#if !GameManager.difficultyValue == GameManager.Difficulty.EASY:
	#	save.disabled = true
	#	save.hide()
	
	var storedTutorials = []
	for unlockedTutorials in GameManager.shownTutorials:
		var tutorial = ui_manager.ALL_TUTORIALS.tutorials[unlockedTutorials]
		if !storedTutorials.has(tutorial):
			storedTutorials.append(tutorial)
		else:
			return
		for item in tutorial.items:
			if item.includeInPause:
				var keyDisplay = KEY_PRESS_DISPLAY.instantiate()
				key_presses.add_child(keyDisplay)
				keyDisplay.setData(item.icons, item.text, item.type)
	
	if key_presses.get_child_count() > 8:
		for keyPress in key_presses.get_children():
			keyPress.setTextSize(26)
	
func _resume():
	%clickSound.play()
	ui_manager.pause()
	
func _settings():
	%clickSound.play()
	var settingsMenu = SETTINGS_MENU.instantiate()
	add_child(settingsMenu)
	settingsMenu.back_button.pressed.connect(_inPopup)
	_inPopup()
	
func _save():
	%clickSound.play()
	var saveLoadMenu = SAVE_LOAD_MENU.instantiate()
	saveLoadMenu.mode = "save"
	add_child(saveLoadMenu)
	saveLoadMenu.parentMenu = self
	_inPopup()
	
func _load():
	%clickSound.play()
	var saveLoadMenu = SAVE_LOAD_MENU.instantiate()
	saveLoadMenu.mode = "load"
	add_child(saveLoadMenu)
	saveLoadMenu.parentMenu = self
	_inPopup()
	
func _quit():
	%clickSoundQuit.play()
	if SaveManager.saveWarning == true:
		var popup = POPUP.instantiate()
		add_child(popup)
		popup.yes.connect(func mainMenu(): get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn"))
		popup.no.connect(popup.queue_free)
		popup.no.connect(_inPopup)
		_inPopup()
	else:
		get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")

func _inPopup():
	inPopup = !inPopup
	var buttons = [resume, settingsButton, save, loadGame , quit]
	if SaveManager.check_save() == false:
		buttons.erase(loadGame)
	else:
		save.show()
		
	if GameManager.difficultyValue == GameManager.Difficulty.HARD:
		buttons.erase(save)
		
	for button in buttons:
		button.disabled = inPopup
