extends Area2D

@export var force: Vector2
@export var flag: String
@export var size: float
@export var switch: bool
@export var switchTime: float
@export var switchFromObject: Node2D
@export var switchToObject: Node2D
@export var collider: CollisionShape2D
@export var switchForce: Vector2
@export var originalForce: Vector2
@export var originalSound: AudioStreamPlayer2D
@export var switchSound: AudioStreamPlayer2D

var tim: Timer
var switchTimer: float = 0

var switchValue: int = 1

func _process(delta):
	if !switch:
		return
	
	if switchTimer <= 0:
		if tim == null:
			tim = Timer.new()
			add_child(tim)
			tim.wait_time = 0.25
			tim.timeout.connect(_switch)
			tim.timeout.connect(tim.queue_free)
			tim.start()
			collider.disabled = true
			switchFromObject.visible = false
			switchToObject.visible = false
	else:
		switchTimer -= delta

func _switch():
	if !switch:
		return
	collider.disabled = false
	switchValue = !switchValue
	switchTimer = switchTime
	if switchValue == 0:
		force = switchForce
		originalSound.stop()
		switchSound.play()
		switchToObject.visible = true
	elif switchValue == 1:
		force = originalForce
		originalSound.play()
		switchSound.stop()
		switchFromObject.visible = true
