extends PanelContainer

@onready var quiet_gardens_select = %QuietGardensSelect
@onready var rocky_forest_select = %RockyForestSelect
@onready var new_game_button = %newGameButton
@onready var cancel_button = %cancelButton

var parentMenu

@onready var slot_name = $"menu/VBoxContainer/Quiet Gardens/VBoxContainer/slotName"
@onready var slot_name_2 = $"menu/VBoxContainer/Rocky Forest/VBoxContainer/slotName2"

var selectedTextColor = Color.CYAN
var unselectedTextColor = Color.WEB_GRAY

@onready var easy_button = %easyButton
@onready var normal_button = %normalButton

var selectedStage: String = "Quiet Gardens"

# Called when the node enters the scene tree for the first time.
func _ready():
	slot_name.add_theme_color_override("default_color", selectedTextColor)
	slot_name_2.add_theme_color_override("default_color", unselectedTextColor)
	cancel_button.pressed.connect(_back)
	
	quiet_gardens_select.pressed.connect(_stageSelected.bind("Quiet Gardens"))
	rocky_forest_select.pressed.connect(_stageSelected.bind("Rocky Forest"))
	
	easy_button.pressed.connect(GameManager.changeDifficulty.bind(GameManager.Difficulty.EASY))
	normal_button.pressed.connect(GameManager.changeDifficulty.bind(GameManager.Difficulty.NORMAL))
	
	if GameManager.difficultyValue == GameManager.Difficulty.EASY:
		easy_button.button_pressed = true
	
	new_game_button.pressed.connect(_newGame)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _newGame():
	if selectedStage.match("Quiet Gardens"):
		SaveManager.saveData = {"player_pos_x":1920.0,"player_pos_y":-1080.0, "difficulty": GameManager.difficultyValue}
	else:
		SaveManager.saveData = {"difficulty": GameManager.difficultyValue}
	GameManager.loadValues()
	SaveManager.loadLevel(selectedStage)

func _back():
	parentMenu._inPopup()
	queue_free()
	
func _stageSelected(stageName: String):
	selectedStage = stageName
	if stageName.match("Quiet Gardens"):
		slot_name.add_theme_color_override("default_color", selectedTextColor)
		slot_name_2.add_theme_color_override("default_color", unselectedTextColor)
	elif stageName.match("Rocky Forest"):
		slot_name.add_theme_color_override("default_color", unselectedTextColor)
		slot_name_2.add_theme_color_override("default_color", selectedTextColor)
