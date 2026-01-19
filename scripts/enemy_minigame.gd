extends CharacterBody2D


@onready var swimming = $swimming
@onready var walking = $walking

@onready var agent = $NavigationAgent2D
@onready var quack_sound = $quackSound

@export var speed: float = 60
@export var quackRange: float = 60
@export var maxHealth: int = 5

@onready var quacker = $Quacker

@export var quackCooldown: float = 1.1
@export var quackBaseRandomTimer: float = 3
@export var quackRandomTimerVariation: float = 0.5

@export var chaseSpeedMultiplier: float = 1.5
@export var runningSpeedMultiplier: float = 1.2

@export var lungeActivationDistance: float = 200
@export var lungeSpeedMultiplier: float = 10

var quackRandomTimer: float = 0.0
var quackTimer: float = 0.0

var lungeCooldown: float = 2.0
var lungeCooldownTimer: float = 0.0
var lungeLength: float = 0.1
var lungeTimer: float = 0.0
var lungeVelocity: Vector2 = Vector2.ZERO
var lunging: bool = false

var stateBaseRandomTimer: float = 6
var stateRandomTimerVariation: float = 2

var stateRandomTimer: float = 0.0

enum STATE{FOLLOWING, CHARGE, IDLE, RUNNING}
var stateChances: Array[int] = [40, 40, 10, 10]
var stateDurations: Array[float] = [1.3, 1.0, 0.3, 0.2]
var state: STATE

var infoBox
var minigamemanager

var moveVector: Vector2 = Vector2.ZERO

var playerPos: Vector2 :
	set(new_pos):
		if playerPos != new_pos:
			playerPos = new_pos
		
		if state == STATE.FOLLOWING or state == STATE.CHARGE:
			agent.target_position = playerPos
		if state == STATE.IDLE:
			agent.target_position = global_position
		if state == STATE.RUNNING:
			#agent.target_position = global_position + -playerPos.normalized() * 100
			var potential_target = (global_position - playerPos).normalized() * 100
			agent.target_position = NavigationServer2D.map_get_closest_point(get_world_2d().get_navigation_map(), potential_target)
			

func initValues():
	quacker.parent_duck = self
	quacker.attack_damage = 1
	quacker.max_health = maxHealth
	quacker.quack_range = quackRange
	
	if minigamemanager.swimming == false:
		swimming.visible = false
		walking.visible = true
	
	quacker.initValues()
	
	quacker.dead.connect(_died)
	
	quackRandomTimer = randf_range(quackBaseRandomTimer - quackRandomTimerVariation, quackBaseRandomTimer + quackRandomTimerVariation)
	
	stateRandomTimer = randf_range(stateBaseRandomTimer - stateRandomTimerVariation, stateBaseRandomTimer + stateRandomTimerVariation)
	
	state = STATE.FOLLOWING
	agent.target_position = playerPos

func _physics_process(delta):
	if agent.is_navigation_finished():
		velocity = Vector2.ZERO
		return
		
	_move()

func _changeStates():
	var rng = randf() * 100
	var stateVariationTimer: float = 1
	
	for index in range(STATE.size()):
		if rng < stateChances[index]:
			state = STATE.values()[index]
			stateVariationTimer = stateDurations[index]
		else:
			rng -= stateChances[index]
			if rng <= 0:
				break
			
	stateRandomTimer = randf_range(stateBaseRandomTimer - stateRandomTimerVariation, stateBaseRandomTimer + stateRandomTimerVariation) * stateVariationTimer		
	print(state)
		

func _process(delta):
	if moveVector.x < 0:
		walking.flip_h = true
		swimming.flip_h = true
	elif moveVector.x > 0:
		walking.flip_h = false
		swimming.flip_h = false
	
	if stateRandomTimer > 0:
		stateRandomTimer -= delta
	else:
		_changeStates()
		
	if lungeTimer > 0:
		lungeTimer -= delta
	elif lunging:
		lunging = false
		
	if lungeCooldownTimer > 0:
		lungeCooldownTimer -= delta
	
	if quackTimer > 0:
		quackTimer -= delta	
	
	if quackRandomTimer >= 0:
		quackRandomTimer -= delta
	
	if quackRandomTimer <= 0:
		quack()	
		quackRandomTimer = randf_range(quackBaseRandomTimer - quackRandomTimerVariation, quackBaseRandomTimer + quackRandomTimerVariation)
	elif quacker.enemy_duck != null:
		quack()
	
func _move():
	var next_pos = agent.get_next_path_position()
	moveVector = (next_pos - global_position).normalized()
	velocity = moveVector * speed
	if state == STATE.RUNNING:
		velocity *= runningSpeedMultiplier
	elif state == STATE.CHARGE:
		velocity *= chaseSpeedMultiplier

	var distanceVector = abs(global_position - playerPos)
	if distanceVector.x + distanceVector.y <= lungeActivationDistance:
		if lunging == false and lungeCooldownTimer <= 0:
			if state != STATE.CHARGE:
				state = STATE.CHARGE
			print("lunging!")
			lunging = true
			lungeTimer = lungeLength
			lungeVelocity = velocity
			lungeCooldownTimer = lungeCooldown
	
	if lunging:
		velocity = lungeVelocity * lungeSpeedMultiplier
	move_and_slide()

func quack():
	if quackTimer > 0:
		return
	quackTimer = quackCooldown
	quack_sound.play()
	quacker.quack()

func _died():
	minigamemanager.enemiesDefeated += 1
	infoBox.hpValue = 0
	minigamemanager.enemyArray.erase(self)
	queue_free()
