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
@export var originalSound: Node2D
@export var switchSound: Node2D
@export var delayTime: float = 0.25
var switchFromFlag: String
@export var switchToFlag: String
@export var isInBreathable: bool = false

var tim: Timer
var switchTimer: float = 0

var switchValue: int = 1

func _ready():
	switchFromFlag = flag
	GameManager.changeBreathableLayer.connect(_updateBreathable)
	
	if flag == "tornado":
		var emitter: GPUParticles2D = null
		if $GPUParticles2D != null:
			$GPUParticles2D.emitting = false
			emitter = $GPUParticles2D
		
		if $CollisionShape2D != null:
			if collider == null:
				collider = $CollisionShape2D
		
		if emitter == null or collider == null:
			print("nahman")
			return
		
		if collider.shape is CircleShape2D:
			var notifier = VisibleOnScreenNotifier2D.new()
			add_child(notifier)
			notifier.rect.size = Vector2(collider.shape.radius * 2, collider.shape.radius * 2)
			notifier.rect.position = -notifier.rect.size/2
			notifier.screen_entered.connect(func(): emitter.emitting = true)
			notifier.screen_exited.connect(func(): emitter.emitting = false)
				

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
			_switchSounds(originalSound, false)
			_switchSounds(switchSound, false)
			
	else:
		switchTimer -= delta

func _updateBreathable(breathable):
	if isInBreathable and breathable:
		visible = true
	elif isInBreathable and !breathable:
		visible = false

func _switchSounds(sound, start: bool = false):
	if originalSound != null:
		_stopStartSoundsRecursive(sound, start)
	if switchSound != null:
		_stopStartSoundsRecursive(sound, start)

func _stopStartSoundsRecursive(sound, start: bool = false):
	if sound != null:
		if sound is AudioStreamPlayer2D:
			if !start:
				sound.stop()
			else:
				sound.play()
		else:
			for s in sound.get_children():
				if s is AudioStreamPlayer2D:
					if !start:
						s.stop()
					else:
						s.play()
		
func _switch():
	if !switch:
		return
	if collider != null:
		collider.disabled = false
	switchValue = !switchValue
	switchTimer = switchTime
	if switchValue == 0:
		force = switchForce
		if switchToFlag != "":
			flag = switchToFlag
		_switchSounds(switchSound, true)
		if switchToObject != null:
			switchToObject.visible = true
	elif switchValue == 1:
		force = originalForce
		if switchToFlag != "":
			flag = switchFromFlag
		_switchSounds(originalSound, true)
		if switchFromObject != null:
			switchFromObject.visible = true
