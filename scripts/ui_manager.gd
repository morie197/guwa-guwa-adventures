extends CanvasLayer

const LEVEL_UP_UI = preload("uid://dqqnbgo7hdj8n")
const TUTORIAL = preload("uid://dvc0qm8fmb6qj")
const ALL_TUTORIALS = preload("uid://babei73ri162t")

var tutorial

# Called when the node enters the scene tree for the first time.
func _ready():
	GameManager.levelUp.connect(_showLevelUpUI)
	GameManager.startTutorial.connect(_startTutorial)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _showLevelUpUI():
	GameManager.paused = true
	var levelUpUI = LEVEL_UP_UI.instantiate()
	add_child(levelUpUI)
	
func _startTutorial(tutorialName: String):
	if tutorial != null:
		return
	tutorial = TUTORIAL.instantiate()
	add_child(tutorial)
	if !ALL_TUTORIALS.tutorials.has(tutorialName):
		print("No tutorial with name: ", tutorialName)
		return
	tutorial.setData(ALL_TUTORIALS.tutorials[tutorialName])
	
