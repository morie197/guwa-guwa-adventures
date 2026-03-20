extends Node2D

@export var target: Node2D
@onready var textObject = $text
var attackString: String = ""
var pos: int = 1
var offset: Vector2 = Vector2.ZERO
var color: Color = Color.WHITE

# Called when the node enters the scene tree for the first time.
func _ready():
	if tr("QUACK_SOUND").length() > 4:
		textObject.add_theme_font_size_override("normal_font_size", 128/tr("QUACK_SOUND").length())
	else:
		textObject.add_theme_font_size_override("normal_font_size", 64/tr("QUACK_SOUND").length())
	textObject.add_theme_color_override("default_color", color)
	#var overallOffset = Vector2(direction.normalized().x * 32, 32)
	textObject.text = attackString
	
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if target != null:
		if !target.is_queued_for_deletion():
			global_position = target.global_position + offset
	else:
		queue_free()
