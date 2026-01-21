extends CharacterBody2D

var moveVector: Vector2

var staminaMultiplier: float = 1
var rangeMultiplier: float = 1
var speedMultiplier: float = 1

@export var moveSpeed: float = 140
@export var staminaRecoveryRate: float = 0.6
@export var baseQuackRange: float = 100.0
@export var quackCooldown: float = 0.80
@export var lungeTime: float = 0.10
@export var lungeSpeed: float = 6

var invincible: bool = false
var invincibleCoolDown: float = 0.1
var invincibleTimer: float = 0.0
var invincibleDuration: float = 0.8
var invincibleDurationTimer: float = 0.0

@onready var swimming = $swimming
@onready var walking = $walking

var lunging: bool = false
var tired: bool = false

var stamina: float
var quackTimer: float
var lungeVector: Vector2

var hitQuackVolume: float = -6
var missQuackVolume: float = 0

var minigamemanager

@onready var quacker = $Quacker
@onready var quack_sound = $quackSound
@onready var block_sound = $blockSound
@onready var invincibility_bar = $invincibilityBar
@onready var hit_sound = $hitSound
@onready var enemy_hit = $enemyHit


func initValues():
	if minigamemanager.swimming == false:
		swimming.visible = false
		walking.visible = true
	
	speedMultiplier = minigamemanager.speedMultiplier
	rangeMultiplier = minigamemanager.rangeMultiplier
	staminaMultiplier = minigamemanager.staminaMultiplier
	staminaRecoveryRate = staminaRecoveryRate * ((staminaMultiplier - 1.0) / 2) + 1
	stamina = lungeTime
	
	quacker.parent_duck = self
	quacker.attack_damage = 1
	quacker.max_health = 5 + round(minigamemanager.level/2.0)
	quacker.quack_range = baseQuackRange * rangeMultiplier
	quacker.initValues()
	quacker.hp_changed.connect(_hp_change)

func _input(event):
	if minigamemanager.displaying == true:
		moveVector = Vector2.ZERO
		return
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
		
	if invincibleTimer > 0:
		invincibleTimer -= delta
			
	if invincibleDurationTimer > 0:
		invincibility_bar.max_value = invincibleDuration * 100
		invincibility_bar.value = invincibleDurationTimer * 100
		invincibleDurationTimer -= delta
	elif invincible:
		invincibleTimer = invincibleCoolDown
		invincibility_bar.hide()
		invincible = false
		
	GameManager.worldManager.ui_manager.updateStaminaBar(round(stamina * 100), round(lungeTime * 100))

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
	quackTimer = quackCooldown
	if quacker.quack() == false:
		quack_sound.volume_db = hitQuackVolume
		enemy_hit.play()
		quack_sound.play()
	else:
		quack_sound.volume_db = missQuackVolume
		quack_sound.play()
	
func _hp_change():
	hit_sound.pitch_scale = clampf(float(quacker.health) / float(quacker.max_health) + 0.5, 0.2, 1)

func parry():
	if invincible:
		block_sound.play()
		return false
	if !invincible and invincibleTimer > 0:
		return true
	elif invincibleTimer <= 0:
		quacker.health  = clamp(quacker.health + 1, 0, quacker.max_health)
		quacker.hp_changed.emit()
		invincibleDurationTimer = invincibleDuration
		invincible = true
		invincibility_bar.show()
		block_sound.play()
		return false
	return false
	
func _move(movevec: Vector2):
	if lunging:
		velocity = lungeVector.normalized() * lungeSpeed
		velocity *= moveSpeed
		velocity *= (speedMultiplier / 1.8)
	else:
		velocity = movevec.normalized()
		velocity *= moveSpeed
		velocity *= (speedMultiplier / 1.8)
	
	move_and_slide()
