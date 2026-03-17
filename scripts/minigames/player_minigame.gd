extends CharacterBody2D

var moveVector: Vector2

var enduranceMultiplier: float = 1
var rangeMultiplier: float = 1
var speedMultiplier: float = 1

@export var moveSpeed: float = 120
@export var staminaRecoveryRate: float = 0.8
@export var baseQuackRange: float = 80.0
@export var quackCooldown: float = 1.3
@export var lungeTime: float = 0.15
@export var lungeSpeed: float = 6

var flyLerpSpeed: float

var layer: int = 1
#
#var invincible: bool = false
#var invincibleCoolDown: float = 0.1
#var invincibleTimer: float = 0.0
#var invincibleDuration: float = 0.6
#var invincibleDurationTimer: float = 0.0

var beingKnockedBack: bool = false
var knockBackDirection: Vector2
var knockBackDuration: float = 0.2

var flyStaminaMulti: float

var flying: bool = false

@onready var swimming = $swimming
@onready var walking = $walking


@onready var wings_flying_sound = %wingsFlyingSound
@onready var wings_flapping_sound = %wingsFlappingSound

@onready var blocked_sound = $blockedSound

var lunging: bool = false
var tired: bool = false

var flyDelayTimer: float = 0.0
var flyDelay: float

var knockBackSpeed: float = 2

var waterSpeedMultiplier: float
var agilityMultiplier: float

var lastMovedDirection: Vector2 = Vector2.ZERO

@onready var ram = $ram

var flyMulti: float

var stamina: float
var quackTimer: float
var lungeVector: Vector2

var quackingTime: float = 0.6
var quackingTimer: float = 0.0

var quacking: bool = false

var sprintMult: float

var hitQuackVolume: float = -6
var missQuackVolume: float = 0

var minigamemanager

var sprinting: bool = false

@onready var quacker = $Quacker
@onready var quack_sound = $quackSound
@onready var block_sound = $blockSound
@onready var invincibility_bar = $invincibilityBar
@onready var hit_sound = $hitSound
@onready var enemy_hit = $enemyHit
@onready var heal_sound = $healSound

func _ready():
	agilityMultiplier = GameManager.playerRef.agilityMultiplier
	waterSpeedMultiplier = GameManager.playerRef.waterSpeedMultiplier
	flyDelay = GameManager.playerRef.flyDelay
	flyLerpSpeed = GameManager.playerRef.flyLerpSpeed
	flyStaminaMulti = GameManager.playerRef.flyStaminaMulti
	flyMulti = GameManager.playerRef.flyMulti
	sprintMult = GameManager.playerRef.sprintMult

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
	quacker.attack_damage = 2 + floor(GameManager.postgameUpgradeLevels["power"] / 5.0)
	quacker.max_health = GameManager.maxHP
	quacker.max_quack_range = baseQuackRange * (((rangeMultiplier-1)/1)+1) 
	quacker.max_quack_range *= 1 + (GameManager.postgameUpgradeLevels["reach"] * UpgradeData.POSTGAMEUPGRADES["reach"]["percentIncrease"])/200.0
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
			if Input.is_action_just_pressed("attack"):
				_quack()
		
	if event.is_action_pressed("lunge") and !tired and !event.is_echo():
		lunging = true
		
			
		
		#
		#if GameManager.abilities.has("fly") or GameManager.abilities.has("sprint"):
			#if !flying:
				#sprinting = (Input.is_action_pressed("sprint") and !tired)
			#if GameManager.abilities.has("fly"):
				#if Input.is_action_just_pressed("fly") and !(GameManager.worldLayer == 0 and (layer == 0 or layer == -1)):
					#if sprinting:
						#sprinting = false
				#if layer != 2:
					#if Input.is_action_pressed("fly") and !tired and !(GameManager.worldLayer == 0 and (layer == 0 or layer == -1)):
						#_toggleFly(true)
					#else:
						#_toggleFly(false)
		
func _physics_process(delta):
	_move(moveVector)
	
func _process(delta):
	if quackTimer > 0:
		quackTimer -= delta
		
	#if invincibleTimer > 0:
		#invincibleTimer -= delta
		
	if quackingTimer > 0:
		quackingTimer -= delta
	else:
		quacking = false
			#
	#if invincibleDurationTimer > 0:
		#invincibility_bar.max_value = invincibleDuration * 100
		#invincibility_bar.value = invincibleDurationTimer * 100
		#invincibleDurationTimer -= delta
	#elif invincible:
		#invincibleTimer = invincibleCoolDown
		#invincibility_bar.hide()
		#invincible = false
		
	GameManager.worldManager.ui_manager.updateStaminaBar(round(quackCooldown * 100) - round(quackTimer * 100), round(quackCooldown * 100))

	if moveVector.x < 0:
		walking.flip_h = true
		swimming.flip_h = true
	elif moveVector.x > 0:
		walking.flip_h = false
		swimming.flip_h = false
		
	
	if flying and !wings_flying_sound.playing:
		#if GameManager.loadingLevel:
			#return
		wings_flying_sound.play()
		
	
	if moveVector != Vector2.ZERO:
		lastMovedDirection = lastMovedDirection.lerp(moveVector, delta * flyLerpSpeed)
		
	
	if flyDelayTimer > 0:
		flyDelayTimer -= delta
		
	

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
		
func _toggleFly(value: bool):
	if flying == value: 
		return
		
	if !GameManager.abilities.has("fly"):
		return
		
	lastMovedDirection = lastMovedDirection * 0.4
	#if lastMovedDirection.x > 0.5 or lastMovedDirection.y > 0.5:
	#	lastMovedDirection = lastMovedDirection/2.0
	if !wings_flapping_sound.playing:
		wings_flapping_sound.play()
	if wings_flying_sound.playing:
		wings_flying_sound.stop()
	flyDelayTimer = flyDelay
	flying = value
		
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
#
func parry(direction, damagerSpeed, reflectDamage, reflectPosition):
	quacker.quack(direction, damagerSpeed, true, reflectDamage, reflectPosition)
	
	#if invincible:
		#block_sound.play()
		#return false
	#if !invincible and invincibleTimer > 0:
		#return true
	#elif invincibleTimer <= 0:
		#if GameManager.difficultyValue == GameManager.Difficulty.EASY:
			#quacker.health  = clamp(quacker.health + 1, 0, quacker.max_health)
		#else:
			##damager.damage(1, self)
			##damager.parent_duck.changeStates()
			#quacker.quack((damager.global_position - global_position).normalized(), 5 * speedMultiplier)
		#quacker.hp_changed.emit()
		#invincibleDurationTimer = invincibleDuration
		#invincible = true
		#invincibility_bar.show()
		#block_sound.play()
		#return false
	#return false
	

func knockback(direction: Vector2, multiplier: float = 1):
	beingKnockedBack = true
	knockBackDirection = direction * multiplier
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
		velocity = moveVector.normalized() * lungeSpeed
		velocity *= moveSpeed
		velocity *= ((speedMultiplier - 1) / 5) + 1
	else:
		#if flying == true:
				#velocity = lastMovedDirection
		#else:
			#velocity = movevec.normalized()
			
		velocity = movevec.normalized()
			
		velocity *= moveSpeed
		velocity *= ((speedMultiplier - 1) / 5) + 1
		#velocity *=  agilityMultiplier
		#
		#if flying:
			#velocity *= flyMulti * agilityMultiplier
		#else:
			#velocity *= sprintMult
		
		velocity *= sprintMult
		#
		#if !flying and (layer == 0 or layer == -1):
			#velocity *= waterSpeedMultiplier * agilityMultiplier
			#
		#if flyDelayTimer > 0:
			#velocity = movevec.normalized() * moveSpeed / 1.4
		
	

		
	if beingKnockedBack:
		velocity += knockBackDirection * knockBackSpeed
		
			
	
	move_and_slide()
