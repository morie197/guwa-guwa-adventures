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
@export var quackBaseRandomTimer: float = 1.7
@export var quackRandomTimerVariation: float = 0.5

@export var runningStateDuration: float = 0.8
@export var followingStateDuration: float = 1.0
@export var idleStateDuration: float = 0.3
@export var chasingStateDuration: float = 0.6

@export var chaseSpeedMultiplier: float = 2.5
@export var runningSpeedMultiplier: float = 2


var quackRandomTimer: float = 0.0
var quackTimer: float = 0.0

var stateBaseRandomTimer: float = 6
var stateRandomTimerVariation: float = 1

var stateRandomTimer: float = 0.0

enum STATE{FOLLOWING, CHARGE, IDLE, RUNNING}
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
	var rng = randi_range(0, STATE.size())
	var stateVariationTimer: float = 1
	
	match rng:
		STATE.FOLLOWING:
			state = STATE.FOLLOWING
			stateVariationTimer = followingStateDuration
		STATE.CHARGE:
			state = STATE.CHARGE
			stateVariationTimer = chasingStateDuration
		STATE.IDLE:
			state = STATE.IDLE
			stateVariationTimer = idleStateDuration
		STATE.RUNNING:
			state = STATE.RUNNING
			stateVariationTimer = runningStateDuration
			
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
