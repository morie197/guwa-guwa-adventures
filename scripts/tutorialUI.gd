extends Control

const KEY_PRESS_DISPLAY = preload("uid://cu2qa7tl2feks")

@onready var tutorial_text = $"DialogueBox/Tutorial Text"
@onready var key_presses = $key_presses_container

@export var maxDisplayTime: float = 10

var keyDisplay
var tutorialdata: Array[TutorialItem]
var displayTime: float = 0.0
var itemNumber = 0

func _process(delta):
	displayTime += delta
	if Input.is_action_just_pressed("nextTutorialItem") or displayTime >= maxDisplayTime:
		displayTime = 0.0
		_nextTutorialItem()

func setData(tutorial: Tutorial):
	tutorialdata = tutorial.items
	_nextTutorialItem()

func _nextTutorialItem():
	if itemNumber >= tutorialdata.size():
		queue_free()
	else:
		_setTutorialItem(tutorialdata[itemNumber])
		itemNumber += 1

func _setTutorialItem(item: TutorialItem):
	tutorial_text.text = item.text
	if keyDisplay != null:
		keyDisplay.queue_free()
	keyDisplay = KEY_PRESS_DISPLAY.instantiate()
	key_presses.add_child(keyDisplay)
	keyDisplay.setData(item.icons)
	print(key_presses.get_child_count())
