extends Control

@onready var text = $PanelContainer2/popupDialogue/VBoxContainer/text

@onready var yesButton = $PanelContainer2/popupDialogue/VBoxContainer/HBoxContainer/yes
@onready var noButton = $PanelContainer2/popupDialogue/VBoxContainer/HBoxContainer/no

var warningText: String = ""

signal yes
signal no

func _ready():
	yesButton.grab_focus()
	yesButton.pressed.connect(_yes)
	noButton.pressed.connect(_no)
	
	yesButton.text = tr("YES_ACTION")
	noButton.text = tr("NO_ACTION")
	
	if warningText == "":
		warningText = tr("POPUP_WARNING_DEFAULT")
	
	text.text = warningText

func _process(delta):
	pass

func _yes():
	yes.emit()
	
func _no():
	no.emit()
