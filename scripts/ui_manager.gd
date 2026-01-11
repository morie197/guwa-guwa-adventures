extends CanvasLayer

const LEVEL_UP_UI = preload("uid://dqqnbgo7hdj8n")


# Called when the node enters the scene tree for the first time.
func _ready():
	GameManager.levelUp.connect(_showLevelUpUI)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _showLevelUpUI():
	GameManager.paused = true
	var levelUpUI = LEVEL_UP_UI.instantiate()
	add_child(levelUpUI)
