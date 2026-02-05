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
@export var delayTime: float = 0.25

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
			tim.wait_time = delayTime
			tim.timeout.connect(_switch)
			tim.timeout.connect(tim.queue_free)
			tim.start()
			if collider != null:
				collider.disabled = true
			if switchFromObject != null:
				switchFromObject.visible = false
			if switchToObject != null:
				switchToObject.visible = false
			if originalSound != null:
				originalSound.stop()
			if switchSound != null:
				switchSound.stop()
	else:
		switchTimer -= delta

func _switch():
	if !switch:
		return
	if collider != null:
		collider.disabled = false
	switchValue = !switchValue
	switchTimer = switchTime
	if switchValue == 0:
		force = switchForce
		if switchSound != null:
			switchSound.play()
		if switchToObject != null:
			switchToObject.visible = true
	elif switchValue == 1:
		force = originalForce
		if originalSound != null:
			originalSound.play()
		if switchFromObject != null:
			switchFromObject.visible = true
