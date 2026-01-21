extends Control

@onready var newgame = $PanelContainer2/PanelContainer/VBoxContainer/newgame
@onready var loadGame = $PanelContainer2/PanelContainer/VBoxContainer/load
@onready var quit = $PanelContainer2/PanelContainer/VBoxContainer/quit

const POPUP = preload("uid://cd68megybdr25")

var inPopup: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	newgame.pressed.connect(_newgame)
	loadGame.pressed.connect(_loadgame)
	quit.pressed.connect(_quit)

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
	
func _inPopup():
	inPopup = !inPopup
	var buttons = [newgame, loadGame, quit]
	for button in buttons:
		button.disabled = inPopup

func _loadMainMap():
	get_tree().change_scene_to_file("res://scenes/level.tscn")
