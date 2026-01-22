extends Control

@onready var newgame = $PanelContainer2/PanelContainer/VBoxContainer/newgame
@onready var continueButton = $PanelContainer2/PanelContainer/VBoxContainer/continue
@onready var settings = $PanelContainer2/PanelContainer/VBoxContainer/settings
@onready var quit = $PanelContainer2/PanelContainer/VBoxContainer/quit

const POPUP = preload("uid://cd68megybdr25")
const SETTINGS_MENU = preload("uid://dnkbdoidjjxng")

var inPopup: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	newgame.pressed.connect(_newgame)
	continueButton.pressed.connect(_loadgame)
	quit.pressed.connect(_quit)
	settings.pressed.connect(_settings)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _newgame():
	var popup = POPUP.instantiate()
	add_child(popup)
	popup.yes.connect(_loadMainMap)
	popup.no.connect(popup.queue_free)
	popup.no.connect(_inPopup)
	_inPopup()

func _loadgame():
	pass
	
func _quit():
	get_tree().quit()
	
func _settings():
	var settingsMenu = SETTINGS_MENU.instantiate()
	add_child(settingsMenu)
	settingsMenu.back_button.pressed.connect(_inPopup)
	_inPopup()
	
func _inPopup():
	inPopup = !inPopup
	var buttons = [newgame, settings, continueButton, quit]
	for button in buttons:
		button.disabled = inPopup

func _loadMainMap():
	get_tree().change_scene_to_file("res://scenes/level.tscn")
