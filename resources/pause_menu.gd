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

var ui_manager
var inPopup: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	resume.pressed.connect(_resume)
	settingsButton.pressed.connect(_settings)
	save.pressed.connect(_save)
	loadGame.pressed.connect(_load)
	quit.pressed.connect(_quit)
	
	for unlockedTutorials in GameManager.shownTutorials:
		var tutorial = ui_manager.ALL_TUTORIALS.tutorials[unlockedTutorials]
		for item in tutorial.items:
			var keyDisplay = KEY_PRESS_DISPLAY.instantiate()
			key_presses.add_child(keyDisplay)
			keyDisplay.setData(item.icons, item.text, item.type)
	
	print("finished")
	print(resume.disabled)
	
func _resume():
	ui_manager.pause()
	
func _settings():
	var settingsMenu = SETTINGS_MENU.instantiate()
	add_child(settingsMenu)
	settingsMenu.back_button.pressed.connect(_inPopup)
	_inPopup()
	
func _save():
	GameManager.saveValues()
	SaveManager.save_game()
	
func _load():
	SaveManager.load_game()
	GameManager.loadValues()
	
func _quit():
	var popup = POPUP.instantiate()
	add_child(popup)
	popup.yes.connect(func mainMenu(): get_tree().change_scene_to_file("res://resources/main_menu.tscn"))
	popup.no.connect(popup.queue_free)
	popup.no.connect(_inPopup)

func _inPopup():
	inPopup = !inPopup
	var buttons = [resume, settingsButton, save, loadGame, quit]
	for button in buttons:
		button.disabled = inPopup
