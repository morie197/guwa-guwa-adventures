extends CharacterBody2D

const RADAR_CIRCLE = preload("uid://b0yv7nmxv7x5o")

@onready var swimming = $swimming
@onready var walking = $walking

@onready var camera_2d = $Camera2D
@onready var quack_sound = $quackSound
@onready var radar_sound = $radarSound
@onready var grass_foot_steps = $grassFootSteps
@onready var water_swimming_through = $waterSwimmingThrough
@onready var under_water_sounds = $underWaterSounds
@onready var wings_flying_sound = $wingsFlyingSound
@onready var wings_flapping_sound = $wingsFlappingSound

@onready var audio_listener_2d = $AudioListener2D

@onready var bgm = $BGM
var bgmVolume: float = -5.7
var bgmFadeTime: float = 0.2

var layer: int = 0
var areaForce: Vector2 = Vector2.ZERO
var areaFlag: String = ""
var moveSpeed: int = 130
var maxStamina: float = 8.0
var staminaRecoveryRate: float = 1.4
var stamina: float = 0
var sprintMult: float = 1.5
var waterSpeedMultiplier: float = 1.5
var flyMulti: float = 2.5
var flyStaminaMulti: float = 1.3
var sprinting: bool = false
var flying: bool = false
var tired: bool = false
var tile: Vector2i = Vector2i.ZERO
var newtile: Vector2i = Vector2i.ZERO
var forcedFly: bool = false
var flyDelay: float = 0.3
var flyDelayTimer: float = 0.0

var enduranceMultiplier: float = 1.0
var rangeMultiplier: float = 1.0
var speedMultiplier: float = 1.0

var moveVector: Vector2 = Vector2.ZERO
var mouseScrollInput: float

@export var streamMoveSpeed: float = 120
@export var whirlPoolMultiplier: float = 2
@export var areaForceTransitionSpeed: float = 10

@onready var backwards_detector = $backwardsDetector
@onready var tutorial_hint_detector = $tutorialHintDetector

@onready var damaged_sound = %damagedSound

@export var wonDelay: float = 2.0

@export var zoomMin: float = 1.5 # maximum amount zoomed OUT (bigger)
@export var ZOOMMAX: float = 5 # maximum amount zoomed IN (smaller)
@export var zoomSpeed: float = 10.0
@export var zoomInAmount: float = 1.2
@export var zoomOutAmount: float = 0.8
@export var rangeMultZoomFactor: float = 1.2
@export var keyZoomMult: float = 1.5

@export var quackRange: float = 60
@export var quackCooldown: float = 0.20
@export var quackFalloffZoom: float = 2
@export var quackFalloffAmountMulti: float = 8

@export var radarRange: float = 120
@export var radarCooldown: float = 1.5

var migrationTime: float = 5
var migrateTimer: float = 0
var migrating: bool = false

var quackTimer: float = 0
var radarTimer: float = 0
var targetZoom: Vector2

var colliding

@onready var area_collider = $AreaCollider
@onready var quack_collider = $QuackCollider

@onready var radar_collider = $RadarCollider

var streamRef

signal quack
signal radar

signal updatedStamina(current: int, max: int)

func _ready():
	area_collider.area_entered.connect(_area_enter)
	area_collider.area_exited.connect(_area_exit)
	
	targetZoom = Vector2(zoomMin, zoomMin)
	
	initializeValues()

func _unhandled_input(event):
	if Input.is_action_just_pressed("menuback pause"):
		if GameManager.minigame or GameManager.inUpgradeMenu or GameManager.wonGame:
			return
		GameManager.worldManager.ui_manager.pause()
	if GameManager.paused or GameManager.minigame:
		return
	
	if event is InputEventMouseButton:
		if Input.is_action_just_pressed("zoomin"):
			mouseScrollInput = zoomInAmount
		elif Input.is_action_just_pressed("zoomout"):
			mouseScrollInput = zoomOutAmount
	
	if event is InputEventKey:
		moveVector.y = Input.get_axis("up", "down")
		moveVector.x = Input.get_axis("left", "right")
		
		if GameManager.abilities.has("fly") or GameManager.abilities.has("sprint"):
			if !flying:
				sprinting = (Input.is_action_pressed("sprint") and !tired)
			if GameManager.abilities.has("fly"):
				if Input.is_action_just_pressed("fly") and !(GameManager.worldLayer == 0 and (layer == 0 or layer == -1)):
					if sprinting:
						sprinting = false
				if areaFlag != "air":
					if Input.is_action_pressed("fly") and !tired and !(GameManager.worldLayer == 0 and (layer == 0 or layer == -1)):
						_toggleFly(true)
					else:
						_toggleFly(false)
		
		if GameManager.abilities.has("migrate"):
			if flying and Input.is_action_pressed("quack"):
				migrating = true
				if migrateTimer <= 0:
					migrateTimer = migrationTime
			else:
				if migrating:
					migrateTimer = 0
					GameManager.worldManager.ui_manager.updateMigrateBar(floor(migrateTimer * 100), floor(migrationTime * 100))
					migrating = false
		
		if GameManager.abilities.has("quack") and quackTimer <= 0:
			if Input.is_action_just_pressed("quack"):
				_quack()
				
		if GameManager.abilities.has("sonar") and radarTimer <= 0:
			if Input.is_action_just_pressed("search"):
				_radar()
			
		if GameManager.abilities.has("dive") and areaFlag == "dive":
			if Input.is_action_just_pressed("dive"):
				GameManager.worldManager.switchUnderOverGround()
				
		if Input.is_action_just_pressed("zoomin") and mouseScrollInput == 0:
			mouseScrollInput = zoomInAmount * keyZoomMult
		elif Input.is_action_just_pressed("zoomout") and mouseScrollInput == 0:
			mouseScrollInput = zoomOutAmount / keyZoomMult
		
	

func _physics_process(delta):
	if GameManager.wonGame:
		_move(Vector2.DOWN)
		return
	if GameManager.paused:
		velocity = Vector2.ZERO
		return
	_move(moveVector)
	
func _process(delta):
	if GameManager.wonGame:
		if bgm.volume_db <= -35 and bgm.playing:
			bgm.stop()
		else:
			bgm.volume_db = lerp(bgm.volume_db, -40.0, bgmFadeTime * delta )
	elif GameManager.minigame:
		flying = false
		migrating = false
		migrateTimer = 0
		bgm.stop()
	elif bgm.playing == false:
		bgm.play()
	
	if GameManager.paused:	
		moveVector = Vector2.ZERO
		return
	if migrating:
		if moveVector.y > 0 and flying:
			if migrateTimer > 0:
				bgm.volume_db = lerp(bgm.volume_db, -40.0, bgmFadeTime * delta )
				migrateTimer -= delta
				GameManager.worldManager.ui_manager.updateMigrateBar(floor(migrateTimer * 100), floor(migrationTime * 100))
			else:
				_migrated()
		else:
			bgm.volume_db = bgmVolume
			migrateTimer = clampf(migrateTimer + delta * 1.5, 0, migrationTime)
			GameManager.worldManager.ui_manager.updateMigrateBar(floor(migrateTimer * 100), floor(migrationTime * 100))
		
	if GameManager.worldLayer == 0:
		if under_water_sounds.playing == false: 
			under_water_sounds.play()
	else:
		if under_water_sounds.playing: 
			under_water_sounds.stop()
		
	if flyDelayTimer > 0:
		flyDelayTimer -= delta
		
	if areaFlag == "":
		areaForce = lerp(areaForce, Vector2.ZERO, delta * areaForceTransitionSpeed)
		
	if flying and !wings_flying_sound.playing:
		wings_flying_sound.play()
	
	if quackTimer > 0:
		quackTimer -= delta
		
	if radarTimer > 0:
		radarTimer -= delta

	
	if moveVector != Vector2.ZERO:
		match layer:
			0:
				if water_swimming_through.playing == false:
					water_swimming_through.play()
			1:
				if grass_foot_steps.playing == false:
					grass_foot_steps.play()
		
		newtile = GameManager.worldManager.getTileUnderPos(global_position)
		if tile != newtile:
			if areaFlag.match("dive") or areaFlag.match("air") or areaFlag.match("thorns"):
				areaFlag = ""
			tile = newtile
			var atlascoords = GameManager.worldManager.tileToAtlasCoords(tile)
			if atlascoords == Vector2i(0, 2):
				layer = 0
			elif atlascoords == Vector2i(0, 0):
				layer = 1
			elif atlascoords == Vector2i(0, 3):
				layer = -1
				areaFlag = "dive"
			elif atlascoords == Vector2i(1, 1):
				layer = 2
				areaFlag = "air"
				if flying == false:
					sprinting = false
					forcedFly = true
					_toggleFly(true)
			elif atlascoords == Vector2i(1, 0):
				layer = 1
				areaFlag = "thorns"
				
			if forcedFly:
				if areaFlag != "air":
					forcedFly = false
					_toggleFly(false)
		
	if mouseScrollInput != 0:
		var minimumZoomAmount = zoomMin / (1 + ((rangeMultiplier - 1) * rangeMultZoomFactor))
		var calculatedZoom: float = clamp(camera_2d.zoom.x * mouseScrollInput, minimumZoomAmount, ZOOMMAX)
		targetZoom = Vector2(calculatedZoom, calculatedZoom)
		mouseScrollInput = 0
		
	if camera_2d.zoom != targetZoom:
		camera_2d.zoom = lerp(camera_2d.zoom, targetZoom, zoomSpeed * delta)
	
	if moveVector.x < 0:
		walking.flip_h = true
		swimming.flip_h = true
	elif moveVector.x > 0:
		walking.flip_h = false
		swimming.flip_h = false
	
	if moveVector != Vector2.ZERO:
		if layer == 0:
			walking.visible = false
			if walking.is_playing():
				walking.stop()
			swimming.visible = true
			swimming.play()
		if layer == 1:
			swimming.visible = false
			if swimming.is_playing():
				swimming.stop()
			walking.visible = true
			walking.play()
	else:
		if walking.is_playing():
			walking.stop()
		elif swimming.is_playing():
				swimming.stop()
			
	if sprinting or flying:
		if stamina > 0: # prevent negative stamina values
			if sprinting:
				stamina -= delta
			if flying:
				stamina -= delta / flyStaminaMulti
			emitUpdatedStaminaValue()
		else:
			tired = true
			if sprinting: 
				sprinting = false
			elif flying and areaFlag != "air": 
				_toggleFly(false)
	else:
		if stamina < maxStamina:
			stamina+=delta * staminaRecoveryRate * enduranceMultiplier
			emitUpdatedStaminaValue()
		else:
			tired = false

func _area_enter(area):
	streamRef = area
	areaFlag = area.flag
	if areaFlag == "stream" or "whirlpool":
		#print("nya")
		areaForce = area.force * streamMoveSpeed
	
func _area_exit(_area):
	streamRef = null
	areaFlag = ""
	
func _toggleFly(value: bool):
	if flying == value: 
		return
	if !wings_flapping_sound.playing:
		wings_flapping_sound.play()
	if wings_flying_sound.playing:
		wings_flying_sound.stop()
	flyDelayTimer = flyDelay
	flying = value
	
func initializeValues():
	stamina = maxStamina
	emitUpdatedStaminaValue()
	quack_collider.get_child(0).shape.radius = quackRange * rangeMultiplier
	radar_collider.get_child(0).shape.radius = radarRange * rangeMultiplier
	
func emitUpdatedStaminaValue():
	updatedStamina.emit(round(stamina * 100), round(maxStamina * 100))

func _quack():
	quack_sound.play()
	quack_sound.volume_db = 10 - clampf(quackFalloffZoom - camera_2d.zoom.x, 0, 80) * quackFalloffAmountMulti
	#print(quack_sound.volume_db)
	quackTimer = quackCooldown
	quack.emit()
	
func _migrated():
	if migrating == true:
		migrating = false
	set_collision_mask_value(1, false)
	set_collision_layer_value(5, false)
	var timmy = Timer.new()
	add_child(timmy)
	timmy.wait_time = wonDelay
	timmy.timeout.connect(camera_2d.reparent.bind(GameManager, true))
	timmy.timeout.connect(timmy.queue_free)
	timmy.timeout.connect(audio_listener_2d.queue_free)
	timmy.start()
	
	GameManager.won()
	
	
	GameManager.paused = true
	
func _radar():
	radar_sound.play()
	radarTimer = radarCooldown
	radar.emit()
	var radCircle = RADAR_CIRCLE.instantiate()
	GameManager.worldManager.add_child(radCircle)
	radCircle.global_position = global_position
	radCircle.maxRadius = radarRange * rangeMultiplier
	
func _move(movevec: Vector2):
	if areaFlag.match("stream"):
		velocity = movevec
	else:
		velocity = movevec.normalized()
	velocity *= moveSpeed
	velocity *= speedMultiplier / 1.1
	
	tutorial_hint_detector.target_position = moveVector * 20
	#if tutorial_hint_detector.is_colliding():
	#	print("tutorial")
	
	if !flying and (layer == 0 or layer == -1):
		velocity *= waterSpeedMultiplier
	if sprinting:
		velocity *= sprintMult
	elif flying:
		velocity *= flyMulti
		
	if areaFlag.match("thorns"):
		GameManager.damagePlayer()
		
	if !flying: 
		if areaFlag == "stream":
			backwards_detector.enabled = true
			backwards_detector.target_position = areaForce.normalized() * 13
			if backwards_detector.is_colliding():
				GameManager.damagePlayer()
			var streamForce: Vector2
			var minMaxForce: Vector2 = Vector2.ONE * moveSpeed * (speedMultiplier / 1) * waterSpeedMultiplier
			streamForce.x = clampf(areaForce.x, -minMaxForce.x, minMaxForce.x)
			streamForce.y = clampf(areaForce.y, -minMaxForce.y, minMaxForce.y)
			velocity += streamForce
		elif areaFlag == "whirlpool":
			if streamRef != null:
				var distanceFromCenter = global_position - streamRef.global_position
				var absDistance = absf(distanceFromCenter.x) + absf(distanceFromCenter.y)
				var whirlpoolvel = distanceFromCenter.normalized() * areaForce
				velocity += Vector2(whirlpoolvel.y, -whirlpoolvel.x) * whirlPoolMultiplier * (streamRef.size / absDistance + 1)
				velocity += (streamRef.global_position - global_position).normalized() * (streamRef.size / absDistance + 1) * whirlPoolMultiplier
		else:
			backwards_detector.enabled = false
	if flyDelayTimer > 0:
		velocity = movevec.normalized() * moveSpeed / 1.4
	
	var colliding = move_and_slide()
	if colliding and flying:
		_toggleFly(false)
	
