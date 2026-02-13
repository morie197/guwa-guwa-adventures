extends PanelContainer

@onready var duck_grid = $DuckGrid

const DUCK_CONTAINER = preload("uid://cnvkkjoe28ls3")

var duckNames: Array[String]
var duckHP: Array[int]

var corrected: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in duckNames.size():
		var duckCont = DUCK_CONTAINER.instantiate()
		duck_grid.add_child(duckCont)
		duckCont.duckName.text = str(duckNames[i])
		duckCont.duckhp.text = "HP: " + str(duckHP[i])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !corrected:
		position.x += size.x/2.0
		corrected = true
