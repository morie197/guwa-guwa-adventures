extends CharacterBody2D

var moveVector: Vector2

var staminaMultiplier: float = 1
var rangeMultiplier: float = 1
var speedMultiplier: float = 1

@export var moveSpeed: float = 70
@export var staminaRecoveryRate: float = 0.4
@export var baseQuackRange: float = 100.0
@export var quackCooldown: float = 0.80
@export var lungeTime: float = 0.10
@export var lungeSpeed: float = 6

@onready var swimming = $swimming
@onready var walking = $walking

var lunging: bool = false
var tired: bool = false

var stamina: float
var quackTimer: float
var lungeVector: Vector2

var minigamemanager

@onready var quacker = $Quacker
@onready var quack_sound = $quackSound


func initValues():
	if minigamemanager.swimming == false:
		swimming.visible = false
		walking.visible = true
	
	speedMultiplier = minigamemanager.speedMultiplier
	rangeMultiplier = minigamemanager.rangeMultiplier
	staminaMultiplier = minigamemanager.staminaMultiplier
	staminaRecoveryRate = staminaRecoveryRate * staminaMultiplier
	stamina = lungeTime
	
	quacker.parent_duck = self
	quacker.attack_damage = 1
	quacker.max_health = 5 + round(minigamemanager.level/2.0)
	quacker.quack_range = baseQuackRange * rangeMultiplier
	quacker.initValues()

func _input(event):
	if event is InputEventKey:
		moveVector.y = Input.get_axis("up", "down")
		moveVector.x = Input.get_axis("left", "right")
			
		if quackTimer <= 0:
			if Input.is_action_just_pressed("quack"):
				_quack()
		
		if Input.is_action_pressed("sprint") and !tired:
			if moveVector == Vector2.ZERO:
				return
			lunging = true
			lungeVector = moveVector
		
func _physics_process(delta):
	_move(moveVector)
	
func _process(delta):
	if quackTimer > 0:
		quackTimer -= delta

	if moveVector.x < 0:
		walking.flip_h = true
		swimming.flip_h = true
	elif moveVector.x > 0:
		walking.flip_h = false
		swimming.flip_h = false

	if lunging:
		if stamina > 0: # prevent negative stamina values
			stamina -= delta
		else:
			tired = true
			lunging = false
			moveVector = Vector2.ZERO
	else:
		if stamina < lungeTime:
			stamina+=delta * staminaRecoveryRate
		else:
			tired = false
		
func _quack():
	quack_sound.play()
	quackTimer = quackCooldown
	quacker.quack()
	
func _move(movevec: Vector2):
	if lunging:
		velocity = lungeVector.normalized() * lungeSpeed
		velocity *= moveSpeed
		velocity *= speedMultiplier
	else:
		velocity = movevec.normalized()
		velocity *= moveSpeed
		velocity *= speedMultiplier
	
	move_and_slide()
