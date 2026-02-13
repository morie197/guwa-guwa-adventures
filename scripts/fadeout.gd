extends Control

@export var fadeoutSpeed: float = 2
@export var normaldisplayTime: float = 2
@export var deleteList: Array[Node]

var normaldisplayTimer: float = 0

func _ready():
	normaldisplayTimer = normaldisplayTime

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if normaldisplayTimer > 0:
		normaldisplayTimer -= delta
	else:
		modulate = modulate.lerp(Color.TRANSPARENT, delta * fadeoutSpeed)
		if modulate.a <= 0.05:
			for node in deleteList:
				node.queue_free()
			queue_free()
			
