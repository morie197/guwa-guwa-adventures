extends CanvasLayer

const UPGRADE_SELECTION_UI = preload("uid://dwgfu70tl5d85")
var selectionUI

# Called when the node enters the scene tree for the first time.
func _ready():
	GameManager.levelUp.connect(_showLevelUpUI)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _showLevelUpUI():
	if selectionUI != null: 
		queue_free()
	selectionUI = UPGRADE_SELECTION_UI.instantiate()
	add_child(selectionUI)
