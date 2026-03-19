extends PathFollow2D

@export var speed: float = 100
@export var peakPos: float = -1
@export var underground: bool = false
@export var tornadoParticles: GPUParticles2D

@export var disableStreamComponents: Array[Node2D]

var peakPosRatio: float

func _ready():
	if peakPos != -1:
		peakPosRatio = peakPos / get_parent().curve.get_baked_length()
	if disableStreamComponents.size() > 0:
		GameManager.switchedWorldLevel.connect(_toggleTornado)
		
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if GameManager.paused:
		return
	if GameManager.worldManager != null:
		if GameManager.worldManager.inMap:
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
		
func _toggleTornado():
	#print("toggled")
	#print(disableStreamComponents)
	if GameManager.worldLayer == 1:
		for component in disableStreamComponents:
			if component is CollisionShape2D:
				#print("collision")
				component.set_deferred("disabled", true)
			component.process_mode = PROCESS_MODE_DISABLED
			component.hide()
	else:
		for component in disableStreamComponents:
			if component is CollisionShape2D:
				#print("collision")
				component.set_deferred("disabled", false)
			component.process_mode = PROCESS_MODE_ALWAYS
			component.show()
