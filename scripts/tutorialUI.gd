extends Control

const KEY_PRESS_DISPLAY = preload("uid://cu2qa7tl2feks")

@onready var tutorial_text = $"DialogueBox/Tutorial Text"
@onready var key_presses = $PanelContainer/bottom_bar/key_presses_container

@onready var dialogue_box = $DialogueBox
@onready var nextDialogueButton = $TextureRect

@export var maxDisplayTime: float = 30

var keyDisplay
var displayTime: float = 0.0
var itemNumber = 0

func _process(delta):
	displayTime += delta
	if Input.is_action_just_pressed("nextTutorialItem") or displayTime >= maxDisplayTime:
		displayTime = 0.0
		GameManager.tutorialOver.emit()
		queue_free()

func setData(tutorial: Tutorial):
	if tutorial.displayText == "":
		dialogue_box.hide()
		nextDialogueButton.hide()
	else:
		tutorial_text.text = tutorial.displayText
	_setTutorialItems(tutorial.items)

func _setTutorialItems(items: Array[TutorialItem]):
	for item in items:
		keyDisplay = KEY_PRESS_DISPLAY.instantiate()
		key_presses.add_child(keyDisplay)
		keyDisplay.setData(item.icons, item.text, item.type)

	#print(key_presses.get_child_count())
