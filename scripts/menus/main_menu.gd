extends Control

@onready var newgame = %newgame
@onready var continueButton = %continue
@onready var settings = %settings
@onready var quit = %quit

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
	
	newgame.mouse_entered.connect(_hovered)
	continueButton.mouse_entered.connect(_hovered)
	quit.mouse_entered.connect(_hovered)
	settings.mouse_entered.connect(_hovered)
	
	newgame.mouse_exited.connect(_hoverExit)
	continueButton.mouse_exited.connect(_hoverExit)
	quit.mouse_exited.connect(_hoverExit)
	settings.mouse_exited.connect(_hoverExit)
	
	if SaveManager.check_save() == false:
		continueButton.disabled = true
		
	%AudioStreamPlayer.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _hovered():
	%hoversound.play()
	
func _hoverExit():
	pass
	#%hoversoundExit.play()
	
func _newgame():
	%clickSound.play()
	var newGameUI = NEW_GAME_UI.instantiate()
	newGameUI.parentMenu = self
	add_child(newGameUI)
	_inPopup()

func _loadgame():
	%clickSound.play()
	var saveLoadMenu = SAVE_LOAD_MENU.instantiate()
	saveLoadMenu.mode = "load"
	add_child(saveLoadMenu)
	saveLoadMenu.parentMenu = self
	_inPopup()
	
func _quit():
	%clickSoundQuit.play()
	%clickSoundQuit.finished.connect(get_tree().quit)
	#get_tree().quit()
	
func _settings():
	%clickSound.play()
	var settingsMenu = SETTINGS_MENU.instantiate()
	add_child(settingsMenu)
	settingsMenu.back_button.pressed.connect(_inPopup)
	_inPopup()
	
func _inPopup():
	inPopup = !inPopup
	%mainMenuContents.visible = !inPopup
	var buttons
	if SaveManager.check_save() == false:
		buttons = [newgame, settings, quit]
	else:
		buttons = [newgame, settings, continueButton, quit]
	#inPopup = !inPopup
	for button in buttons:
		button.disabled = inPopup
