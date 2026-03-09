extends PanelContainer

@onready var skill_name = $VBoxContainer/skillName
@onready var skill_treats = $VBoxContainer/skillTreats

var fadeoutSpeed: float = 2
var normaldisplayTime: float = 5


var normaldisplayTimer: float = 0

var speed: float = 5

# Called when the node enters the scene tree for the first time.
func _ready():
	normaldisplayTimer = normaldisplayTime

func setText(skillName: String = "WALKING", treats: int = 13):
	skill_name.text = tr("REQUIRED_TEXT") + tr(skillName)
	skill_treats.text = tr("REQUIRED_TREATS") % str(treats)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if normaldisplayTimer > 0:
		normaldisplayTimer -= delta
	else:
		modulate = modulate.lerp(Color.TRANSPARENT, delta * fadeoutSpeed)
		if modulate.a <= 0.05:
			queue_free()

	global_position.y -= speed * delta
