extends CharacterBody2D


@onready var swimming = $swimming
@onready var walking = $walking

@onready var agent = $NavigationAgent2D
@onready var quack_sound = $quackSound
@onready var lunge_bar = $lungeBar

@onready var a_tk = %ATk

@export var speed: float = 110
@export var projectileSpeedMult: float = 2
var max_quack_range: float = 100
@export var maxHealth: int = 5
var attackDamage: int = 1

@export var healthToHealingRatio: int = 10

@onready var quacker = $Quacker

@export var quackCooldown: float = 1.3
@export var quackBaseRandomTimer: float = 1
@export var quackRandomTimerVariation: float = 0.3

@export var chaseSpeedMultiplier: float = 1.6
@export var runningSpeedMultiplier: float = 1.2

@export var lungeActivationDistance: float = 200
@export var lungeSpeedMultiplier: float = 8

@export var playerEnemyRangeDiff: float = 20

@onready var ram = $ram

var baseHealAmount: int = 3

var quackRandomTimer: float = 0.0
var quackTimer: float = 0.0

var knockBackDuration: float = 0.2
var knockBackDirection: Vector2 = Vector2.ZERO

var lungeCooldown: float = 2
var lungeCooldownTimer: float = 0.0
var lungeLength: float = 0.1
var lungeTimer: float = 0.0
var lungeVelocity: Vector2 = Vector2.ZERO
var quackDelay: float = 0.5
var lunging: bool = false

var stateBaseRandomTimer: float = 6
var stateRandomTimerVariation: float = 2

var stateRandomTimer: float = 0.0
var knockBackSpeed: float = 1.3

var lungeDelay: float = 0.25

enum STATE{FOLLOWING, CHARGE, IDLE, RUNNING}
var stateChances: Array[int] = [40, 40, 10, 10]
var stateDurations: Array[float] = [1.3, 1.0, 0.3, 0.2]
var state: STATE

var infoBox
var minigamemanager

var beingKnockedBack: bool = false

var tim: Timer
var tom: Timer

var moveVector: Vector2 = Vector2.ZERO

var startingModulate: Color = Color.WHITE

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
			var potential_target = (global_position - playerPos).normalized() * 200
			agent.target_position = NavigationServer2D.map_get_closest_point(get_world_2d().get_navigation_map(), global_position + potential_target)
		

func initValues():
	quacker.parent_duck = self
	quacker.attack_damage = attackDamage
	quacker.max_health = maxHealth
	quacker.max_quack_range = max_quack_range
	
	if minigamemanager.enemyNames.size() > 3:
		#print("other chances")
		stateChances = [30, 30, 10, 30]
	
	startingModulate = modulate
	

		
	
	#if GameManager.difficultyValue == GameManager.Difficulty.EASY:
		#max_quack_range = minigamemanager.player_minigame.baseQuackRange * minigamemanager.rangeMultiplier / (((minigamemanager.enemyHealthValues.size() -1) / 2.0) + 1) * (maxHealth / 5)
		#max_quack_range = clampf(max_quack_range * minigamemanager.speedMultiplier * 2, minigamemanager.player_minigame.baseQuackRange, minigamemanager.player_minigame.baseQuackRange * minigamemanager.rangeMultiplier - playerEnemyRangeDiff)
	#else: 
		#quackBaseRandomTimer += 2.0
		#quackCooldown = quackCooldown * (((minigamemanager.enemyHealthValues.size() -1) / 4.0) + 1)
	
	#max_quack_range = ((minigamemanager.player_minigame.baseQuackRange * clampf(minigamemanager.rangeMultiplier/3, 1, 10))/2 + (maxHealth * playerEnemyRangeDiff)/4) - (((minigamemanager.enemyHealthValues.size() -1) / 2.0) + 1)
		
	var enemyScale = clampf(0.5 + ((maxHealth/40.0) - (speed/90.0)), 1, 2)
	swimming.scale = Vector2(enemyScale, enemyScale)
	walking.scale = Vector2(enemyScale, enemyScale)
	
	a_tk.text = "ATK: " + str(attackDamage)

	
	if minigamemanager.swimming == false:
		swimming.visible = false
		walking.visible = true
	
	quacker.initValues()
	
	quacker.dead.connect(_died)
	
	ram.area_entered.connect(_rammed)
	
	quackRandomTimer = randf_range(quackBaseRandomTimer - quackRandomTimerVariation, quackBaseRandomTimer + quackRandomTimerVariation)
	
	stateRandomTimer = randf_range(stateBaseRandomTimer - stateRandomTimerVariation, stateBaseRandomTimer + stateRandomTimerVariation)
	
	agent.target_position = playerPos
	
	changeStates()

func _physics_process(delta):
	if agent.is_navigation_finished() or minigamemanager.inTutorial == true:
		velocity = Vector2.ZERO
		return

	_move()

func changeStates():
	if minigamemanager.displaying == true:
		return
	var rng = randf() * 100
	var stateVariationTimer: float = 1
	
	for index in range(STATE.size()):
		if rng < stateChances[index] and STATE.values()[index] != state:
			state = STATE.values()[index]
			#print(state)
			stateVariationTimer = stateDurations[index]
		else:
			#print(rng, rng - stateChances[index])
			rng -= stateChances[index]
			if rng <= 0:
				#print("breaking")
				break
			
	stateRandomTimer = randf_range(stateBaseRandomTimer - stateRandomTimerVariation, stateBaseRandomTimer + stateRandomTimerVariation) * stateVariationTimer		
	#print(state)
	
	
		
		
func forceState(forcedState: STATE):
	if minigamemanager.displaying == true:
		return
		
	var rng = randf() * 100
	if rng < 30.0:
		return

	state = forcedState
	var stateVariationTimer = stateDurations[state]
			
	stateRandomTimer = randf_range(stateBaseRandomTimer - stateRandomTimerVariation, stateBaseRandomTimer + stateRandomTimerVariation) * stateVariationTimer		

func _process(delta):
	if minigamemanager.displaying == true or minigamemanager.inTutorial == true:
		velocity = Vector2.ZERO
		return
	
	if state == STATE.RUNNING:
		if global_position.distance_to(agent.target_position) < 30:
			forceState(STATE.FOLLOWING)
	
	if moveVector.x < 0:
		walking.flip_h = true
		swimming.flip_h = true
	elif moveVector.x > 0:
		walking.flip_h = false
		swimming.flip_h = false
		
	if moveVector != Vector2.ZERO:
		swimming.play()
		walking.play()
	else:
		swimming.stop()
		walking.stop()
	
	if tim != null and !tim.is_queued_for_deletion():
		lunge_bar.show()
		lunge_bar.max_value = tim.wait_time * 100
		lunge_bar.value = (tim.time_left / 0.9) * 100
	
	if stateRandomTimer > 0:
		stateRandomTimer -= delta
	else:
		changeStates()
		
	if lungeTimer > 0:
		lungeTimer -= delta
	elif lunging:
		lunging = false
		modulate = startingModulate
	
	if lungeCooldownTimer > 0:
		lungeCooldownTimer -= delta
	
	if quackTimer > 0:
		quackTimer -= delta	
	
	if quackRandomTimer >= 0:
		quackRandomTimer -= delta
	
	if quackRandomTimer <= 0:
		quackRandomTimer = randf_range(quackBaseRandomTimer - quackRandomTimerVariation, quackBaseRandomTimer + quackRandomTimerVariation)
		quack()	
	#elif quacker.enemy_duck.size() > 0:
		#if state != STATE.RUNNING:
			#quack()
	
func _move():
	if beingKnockedBack:
		velocity = knockBackDirection * knockBackSpeed
		move_and_slide()
		return
		
	var next_pos = agent.get_next_path_position()
	moveVector = (next_pos - global_position).normalized()
	velocity = moveVector * speed
	if state == STATE.RUNNING:
		velocity *= runningSpeedMultiplier
	elif state == STATE.CHARGE:
		velocity *= chaseSpeedMultiplier

	var distanceVector = abs(global_position - playerPos)
	if distanceVector.x + distanceVector.y <= lungeActivationDistance:
		if lunging == false and lungeCooldownTimer <= 0 and quackTimer <= 0:
			if state != STATE.CHARGE:
				state = STATE.CHARGE
			if tom == null:
				modulate = Color(clampf(modulate.r - 0.5, 0, 1), clampf(modulate.g - 0.5, 0, 1), 1)
				tom = Timer.new()
				add_child(tom)
				tom.wait_time = lungeDelay
				tom.timeout.connect(func dolunge(): lunging = true)
				tom.timeout.connect(func dolungeTimer(): lungeTimer = lungeLength)
				tom.timeout.connect(func dolungeCDTimer(): lungeCooldownTimer = lungeCooldown)
				tom.timeout.connect(tom.queue_free)
				tom.start()
			lungeVelocity = velocity
			velocity = Vector2.ZERO
	
	if lunging:	
		velocity = lungeVelocity * lungeSpeedMultiplier
	
	move_and_slide()

func quack():
	if quackTimer > 0:
		return
	quackTimer = quackCooldown
	
	#quacker.quack((playerPos - global_position).normalized(), 5 * minigamemanager.player_minigame.speedMultiplier)
	
	if tim == null:
		tim = Timer.new()
	tim.wait_time = quackDelay
	add_child(tim)
	tim.start()
	tim.timeout.connect(_attackQuack)
	#tim.timeout.connect(quacker.quack.bind((playerPos - global_position).normalized(), 10 + speed/100.0))
	tim.timeout.connect(quack_sound.play)
	tim.timeout.connect(lunge_bar.hide)
	tim.timeout.connect(tim.queue_free)

func _attackQuack():
	var direction = (minigamemanager.player_minigame.global_position - global_position).normalized()
	var projSpeed = 13.0 * ((attackDamage - 1)/5.0 + 1) + speed/130.0
	if GameManager.difficultyValue == GameManager.Difficulty.HARD:
		projSpeed *= 1.2
	quacker.quack(direction, projSpeed)

func _rammed(area):
	if area.get_parent().name == "PlayerMinigame":
		area.get_parent().quacker.damage(attackDamage, self)

func knockback(direction: Vector2):
	beingKnockedBack = true
	knockBackDirection = direction 
	var tommy = Timer.new()
	tommy.wait_time = knockBackDuration
	tommy.timeout.connect(func turnOffKnockback(): beingKnockedBack = false)
	tommy.timeout.connect(tommy.queue_free)
	add_child(tommy)
	tommy.start()

func _died():
	minigamemanager.enemiesDefeated += 1
	if minigamemanager.player_minigame.quacker.health < minigamemanager.player_minigame.quacker.max_health:
		minigamemanager.player_minigame.heal_sound.pitch_scale = 1.0 + minigamemanager.player_minigame.quacker.health/minigamemanager.player_minigame.quacker.max_health
		minigamemanager.player_minigame.heal_sound.play(0.15)
	if GameManager.difficultyValue == GameManager.Difficulty.HARD:
		minigamemanager.player_minigame.quacker.damage(-1 * clampi(floor(maxHealth/15.0) + floor(attackDamage/4.0), 1, 10), quacker)
	else:
		minigamemanager.player_minigame.quacker.damage(-1 * clampi(floor(maxHealth/10.0) + floor(attackDamage/3.0), 1, 10), quacker)
	#minigamemanager.player_minigame.quacker.damage(-baseHealAmount - round(maxHealth/healthToHealingRatio), quacker)
	#
	infoBox.hpValue = 0
	minigamemanager.enemyArray.erase(self)
	queue_free()
