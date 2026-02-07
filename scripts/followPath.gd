extends PathFollow2D

@export var speed: float = 100
@export var peakPos: float = -1

var peakPosRatio: float

func _ready():
	if peakPos != -1:
		peakPosRatio = peakPos / get_parent().curve.get_baked_length()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if GameManager.paused:
		return
	if peakPos == -1:
		progress += speed * delta
	else:
		var dist
		if progress_ratio > 0.5:
			dist = 1 - progress_ratio
		else:
			dist = progress_ratio
		dist += 1
		#print(dist)
		progress += speed * dist*dist * delta
