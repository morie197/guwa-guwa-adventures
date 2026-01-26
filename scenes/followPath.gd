extends PathFollow2D

@export var speed: float = 100

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if GameManager.paused:
		return
	progress += speed * delta
