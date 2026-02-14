extends CharacterBody2D

var moveVector: Vector2

var enduranceMultiplier: float = 1
var rangeMultiplier: float = 1
var speedMultiplier: float = 1

@export var moveSpeed: float = 160
@export var staminaRecoveryRate: float = 0.8
@export var baseQuackRange: float = 100.0
@export var quackCooldown: float = 1
@export var lungeTime: float = 0.15
@export var lungeSpeed: float = 6

var invincible: bool = false
var invincibleCoolDown: float = 0.1
var invincibleTimer: float = 0.0
var invincibleDuration: float = 0.6
var invincibleDurationTimer: float = 0.0

var beingKnockedBack: bool = false
var knockBackDirection: Vector2
var knockBackDuration: float = 0.2

@onready var swimming = $swimming
@onready var walking = $walking

var lunging: bool = false
var tired: bool = false

var knockBackSpeed: float = 2

@onready var ram = $ram

var stamina: float
var quackTimer: float
var lungeVector: Vector2

var quackingTime: float = 0.6
var quackingTimer: float = 0.0

var quacking: bool = false

var hitQuackVolume: float = -6
var missQuackVolume: float = 0

var minigamemanager

@onready var quacker = $Quacker
@onready var quack_sound = $quackSound
@onready var block_sound = $blockSound
@onready var invincibility_bar = $invincibilityBar
@onready var hit_sound = $hitSound
@onready var enemy_hit = $enemyHit
@onready var heal_sound = $healSound


func initValues():
	if minigamemanager.swimming == false:
		swimming.visible = false
		walking.visible = true
	
	speedMultiplier = minigamemanager.speedMultiplier
	rangeMultiplier = minigamemanager.rangeMultiplier
	enduranceMultiplier = minigamemanager.enduranceMultiplier
	stamina = lungeTime
	
	quackCooldown = quackCooldown - ((speedMultiplier/5) * quackCooldown)
	quacker.parent_duck = self
	quacker.attack_damage = 1
	quacker.max_health = GameManager.maxHP
	quacker.max_quack_range = baseQuackRange * (((rangeMultiplier-1)/1.5)+1)
	quacker.initValues()
	quacker.health = GameManager.healthValue
	quacker.hp_changed.connect(_hp_change)
	#ram.area_entered.connect(_rammed)

func _input(event):
	if minigamemanager.displaying == true:
		moveVector = Vector2.ZERO
		return
		
	if Input.is_action_just_pressed("leftClick"):
		_quack()
		
	if event is InputEventKey:
		moveVector.y = Input.get_axis("up", "down")
		moveVector.x = Input.get_axis("left", "right")
			
		if quackTimer <= 0:
			if Input.is_action_just_pressed("quack") or Input.is_action_just_pressed("fly"):
				_quack()
		
		if (Input.is_action_pressed("sprint")) and !tired:
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
		
	if quackingTimer > 0:
		quackingTimer -= delta
	else:
		quacking = false
			
	if invincibleDurationTimer > 0:
		invincibility_bar.max_value = invincibleDuration * 100
		invincibility_bar.value = invincibleDurationTimer * 100
		invincibleDurationTimer -= delta
	elif invincible:
		invincibleTimer = invincibleCoolDown
		invincibility_bar.hide()
		invincible = false
		
	GameManager.worldManager.ui_manager.updateStaminaBar(round(quackCooldown * 100) - round(quackTimer * 100), round(quackCooldown * 100))

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
	if quackTimer > 0:
		return
	
	quacking = true
	quack_sound.volume_db = hitQuackVolume
	quack_sound.play()
	
	#quackingTimer = quackingTime
	
	quackTimer = quackCooldown
	#if quacker.quack() == false:
		#quack_sound.volume_db = hitQuackVolume
		#enemy_hit.play()
		#quack_sound.play()
	#else:
		#
		#quack_sound.volume_db = missQuackVolume
		#quack_sound.play()
		
	quacker.quack(get_local_mouse_position().normalized(), 5 * speedMultiplier)
	
func _hp_change():
	hit_sound.pitch_scale = clampf(float(quacker.health) / float(quacker.max_health) + 0.5, 0.2, 1)

func parry(damager):
	if invincible:
		block_sound.play()
		return false
	if !invincible and invincibleTimer > 0:
		return true
	elif invincibleTimer <= 0:
		if GameManager.difficultyValue == GameManager.Difficulty.EASY:
			quacker.health  = clamp(quacker.health + 1, 0, quacker.max_health)
		else:
			#damager.damage(1, self)
			#damager.parent_duck.changeStates()
			quacker.quack((damager.global_position - global_position).normalized(), 5 * speedMultiplier)
		quacker.hp_changed.emit()
		invincibleDurationTimer = invincibleDuration
		invincible = true
		invincibility_bar.show()
		block_sound.play()
		return false
	return false
	

func knockback(direction: Vector2):
	beingKnockedBack = true
	knockBackDirection = direction 
	var tommy = Timer.new()
	tommy.wait_time = knockBackDuration
	tommy.timeout.connect(func turnOffKnockback(): beingKnockedBack = false)
	tommy.timeout.connect(tommy.queue_free)
	add_child(tommy)
	tommy.start()
	
#func _rammed(area):
#	if lunging:
#		print("damaged enemy")
#		area.get_parent().quacker.damage(1, self)
	
func _move(movevec: Vector2):
	if lunging:
		velocity = lungeVector.normalized() * lungeSpeed
		velocity *= moveSpeed
		velocity *= (speedMultiplier / 1.8)
	else:
		velocity = movevec.normalized()
		velocity *= moveSpeed
		velocity *= (speedMultiplier / 1.8)
		
	if beingKnockedBack:
		velocity += knockBackDirection * knockBackSpeed
	
	move_and_slide()
