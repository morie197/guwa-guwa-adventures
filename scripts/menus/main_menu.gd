extends Control

@onready var newgame = $PanelContainer2/PanelContainer/VBoxContainer/newgame
@onready var continueButton = $PanelContainer2/PanelContainer/VBoxContainer/continue
@onready var settings = $PanelContainer2/PanelContainer/VBoxContainer/settings
@onready var quit = $PanelContainer2/PanelContainer/VBoxContainer/quit

const POPUP = preload("uid://cd68megybdr25")
const SETTINGS_MENU = preload("uid://dnkbdoidjjxng")
const SAVE_LOAD_MENU = preload("uid://b8nmevsdid6a6")
const NEW_GAME_UI = preload("uid://saw53iuafodd")

var inPopup: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	newgame.pressed.connect(_newgame)
	continueButton.pressed.connect(_loadgame)
	quit.pressed.connect(_quit)
	settings.pressed.connect(_settings)
	
	if SaveManager.check_save() == false:
		continueButton.disabled = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _newgame():
	var newGameUI = NEW_GAME_UI.instantiate()
	newGameUI.parentMenu = self
	add_child(newGameUI)
	_inPopup()

func _loadgame():
	var saveLoadMenu = SAVE_LOAD_MENU.instantiate()
	saveLoadMenu.mode = "load"
	add_child(saveLoadMenu)
	saveLoadMenu.parentMenu = self
	_inPopup()
	
	
	
func _quit():
	get_tree().quit()
	
func _settings():
	var settingsMenu = SETTINGS_MENU.instantiate()
	add_child(settingsMenu)
	settingsMenu.back_button.pressed.connect(_inPopup)
	_inPopup()
	
func _inPopup():
	inPopup = !inPopup
	var buttons
	if SaveManager.check_save() == false:
		buttons = [newgame, settings, quit]
	else:
		buttons = [newgame, settings, continueButton, quit]
	#inPopup = !inPopup
	for button in buttons:
		button.disabled = inPopup
