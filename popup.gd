extends Control

@onready var text = $PanelContainer2/popupDialogue/VBoxContainer/text

@onready var yesButton = $PanelContainer2/popupDialogue/VBoxContainer/HBoxContainer/yes
@onready var noButton = $PanelContainer2/popupDialogue/VBoxContainer/HBoxContainer/no

var warningText: String = "Are you sure?"

signal yes
signal no

func _ready():
	yesButton.pressed.connect(_yes)
	noButton.pressed.connect(_no)
	
	text.text = warningText

func _process(delta):
	pass

func _yes():
	yes.emit()
	
func _no():
	no.emit()
