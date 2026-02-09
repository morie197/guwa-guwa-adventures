extends CharacterBody2D

const RADAR_CIRCLE = preload("uid://b0yv7nmxv7x5o")

@onready var swimming = $swimming
@onready var walking = $walking

@onready var going_fast_particle = $goingFastParticle

@onready var camera_2d = $Camera2D
@onready var quack_sound = $quackSound
@onready var radar_sound = $radarSound
@onready var grass_foot_steps = $grassFootSteps
@onready var water_swimming_through = $waterSwimmingThrough
@onready var under_water_sounds = $underWaterSounds
@onready var wings_flying_sound = $wingsFlyingSound
@onready var wings_flapping_sound = $wingsFlappingSound

@onready var audio_listener_2d = $AudioListener2D

var tornadoMultiplier: float = 5.0

@onready var bgm = $BGM

@onready var heal_sound = $healSound

var bgmVolume: float = -5.7
var bgmFadeTime: float = 0.2

var thornSpeedMultiplier: float = 0.3
var easyStreamHitSpeedMultiplier: float = 0.3

var layer: int = 0
var areaForce: Vector2 = Vector2.ZERO
var areaFlag: String = ""
var moveSpeed: int = 160
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
var flyLerpSpeed: float = 1

var healTimer: Timer

var onThorns: bool = false

var underwaterStaminaDrain: float = 0.6

var underwater: bool = false

var enduranceMultiplier: float = 1.0
var rangeMultiplier: float = 1.0
var speedMultiplier: float = 1.0

var moveVector: Vector2 = Vector2.ZERO
var mouseScrollInput: float

@export var streamMoveSpeed: float = 160
@export var whirlPoolMultiplier: float = 2
@export var areaForceTransitionSpeed: float = 6

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

var tornadoRecoverSpeed: float = 0.1

@export var quackRange: float = 60
@export var quackCooldown: float = 0.20
@export var quackFalloffZoom: float = 2
@export var quackFalloffAmountMulti: float = 8

@export var radarRange: float = 400
@export var radarCooldown: float = 3

var tornadoThrownVelocity: Vector2 = Vector2.ZERO

var migrationTime: float = 5
var migrateTimer: float = 0
var migrating: bool = false

var quackTimer: float = 0
var radarTimer: float = 0
var targetZoom: Vector2

var lastMovedDirection: Vector2 = Vector2.ZERO

var colliding

@onready var area_collider = $AreaCollider
@onready var quack_collider = $QuackCollider

@onready var radar_collider = $RadarCollider

var streamRef

var tilePosition: Vector2i

var healRegenerationTime: float = 60.0

signal quack
signal radar

signal updatedStamina(current: int, max: int)

func _ready():
	area_collider.area_entered.connect(_area_enter)
	area_collider.area_exited.connect(_area_exit)
	
	bgmVolume = bgm.volume_db
	
	healTimer = Timer.new()
	add_child(healTimer)
	healTimer.timeout.connect(GameManager.healPlayer.bind(1, true))
	healTimer.timeout.connect(_regenHeal)
	_regenHeal()
	
	targetZoom = Vector2(zoomMin, zoomMin)
	
	initializeValues()

func _unhandled_input(event):
	if GameManager.lost:
		return
	
	if Input.is_action_just_pressed("menuback pause"):
		if GameManager.minigame or GameManager.inUpgradeMenu or GameManager.wonGame or GameManager.cameraShown:
			return
		if GameManager.worldManager.ui_manager != null:
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
				if layer != 2:
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
			if Input.is_action_pressed("search"):
				_radar()
			
		if GameManager.abilities.has("dive") and layer == -1:
			if Input.is_action_just_pressed("dive"):
				GameManager.worldManager.switchUnderOverGround()
				
		if Input.is_action_just_pressed("zoomin") and mouseScrollInput == 0:
			mouseScrollInput = zoomInAmount * keyZoomMult
		elif Input.is_action_just_pressed("zoomout") and mouseScrollInput == 0:
			mouseScrollInput = zoomOutAmount / keyZoomMult
		
	

func _physics_process(delta):
	if GameManager.wonGame:
		_move(Vector2.DOWN, delta)
		return
	elif GameManager.lost:
		velocity = Vector2.ZERO
		return
	if GameManager.paused:
		velocity = Vector2.ZERO
		return
	_move(moveVector, delta)
	
func _process(delta):
	if GameManager.wonGame:
		if bgm.volume_db <= -35 and bgm.playing:
			bgm.stop()
		else:
			bgm.volume_db = lerp(bgm.volume_db, -40.0, bgmFadeTime * delta )
	elif GameManager.lost:
		bgm.stop()
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
		if moveVector.y > 0 and flying and GameManager.worldLayer == 1:
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
		
	if GameManager.worldLayer == 0 and (layer != 1 and layer != 2):
		underwater = true
	else:
		underwater = false
	
	if underwater:
		if stamina > 0:
			stamina -= delta * underwaterStaminaDrain
		else:
			GameManager.damagePlayer(1)
		
		emitUpdatedStaminaValue()
		if under_water_sounds.playing == false: 
			under_water_sounds.play()
	else:
		if under_water_sounds.playing: 
			under_water_sounds.stop()
		
	if flyDelayTimer > 0:
		flyDelayTimer -= delta
		
	if areaFlag == "":
		var multiplier = 1
		if abs(areaForce.x) > 1.5 or abs(areaForce.y) > 1.5:
			multiplier = 2
		areaForce = lerp(areaForce, Vector2.ZERO, delta * areaForceTransitionSpeed * multiplier)
		
	if moveVector != Vector2.ZERO:
		lastMovedDirection = lastMovedDirection.lerp(moveVector, delta * flyLerpSpeed)
		
	if !Input.is_action_pressed("fly") and (flying or forcedFly) and layer != 2:
		_toggleFly(false)
		
	if flying and !wings_flying_sound.playing:
		wings_flying_sound.play()
	
	if quackTimer > 0:
		quackTimer -= delta
		
	if radarTimer > 0:
		radarTimer -= delta

	if layer == 2 and tired and forcedFly:
		GameManager.damagePlayer(1)
	
	GameManager.minimapCam.global_position = global_position
	GameManager.minimapCam.zoom = camera_2d.zoom / 8
	
	if (moveVector != Vector2.ZERO) or (forcedFly or flying) or (areaFlag.match("wind") or areaFlag.match("stream") or areaFlag.match("forcestream") or areaFlag.match("whirlpool")):
		_stateEffects()
		
		tileCheck()
		
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
				if moveVector != Vector2.ZERO:
					stamina -= delta
				else:
					sprinting = false
			if flying:
				stamina -= delta / flyStaminaMulti
			emitUpdatedStaminaValue()
		else:
			tired = true
			if sprinting: 
				sprinting = false
			elif flying and areaFlag != "air" and !areaFlag.match("wind") and !forcedFly: 
				_toggleFly(false)
	else:
		if stamina < maxStamina and !underwater: 
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
	
func loadGameChecks():
	tileCheck()
	flying = false
	velocity = Vector2.ZERO
	sprinting = false
	migrating = false
	
func tileCheck():
	newtile = GameManager.worldManager.getTileUnderPos(global_position)
	if tile != newtile:
		if GameManager.worldManager != null:
			GameManager.worldManager.updateFOW(true)
		if (areaFlag.match("air") and !areaFlag.match("wind")):
			areaFlag = ""
		tile = newtile
		tilePosition = (tile * 64) + Vector2i(0, 0)
		var atlascoords = GameManager.worldManager.tileToAtlasCoords(tile)
		if atlascoords == Vector2i(0, 2):
			layer = 0
		elif atlascoords == Vector2i(0, 0):
			layer = 1
		elif atlascoords == Vector2i(0, 3):
			layer = -1
		elif atlascoords == Vector2i(1, 1):
			layer = 2
			if !areaFlag.match("wind"):
				areaFlag = "air"
			if flying == false:
				sprinting = false
				forcedFly = true
				_toggleFly(true)
						
		if atlascoords == Vector2i(1, 0):
			layer = 1
			onThorns = true
		else:
			onThorns = false
					
		if forcedFly:
			if layer != 2 and !(!tired and Input.is_action_pressed("fly")):
				forcedFly = false
				_toggleFly(false)
	
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
	
func _regenHeal():
	healTimer.wait_time = healRegenerationTime
	healTimer.start()
	
func _migrated():
	if migrating == true:
		migrating = false
	set_collision_mask_value(1, false)
	set_collision_layer_value(5, false)
	var timmy = Timer.new()
	add_child(timmy)
	timmy.wait_time = wonDelay
	timmy.timeout.connect(camera_2d.reparent.bind(GameManager, true))
	timmy.timeout.connect(func assignCamera(): GameManager.playerCamCredits = camera_2d)
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
	
func _stateEffects():
	if flying or forcedFly:
		if going_fast_particle.visible == false:
			going_fast_particle.show()
		water_swimming_through.stop()
		grass_foot_steps.stop()
		return
	else:
		going_fast_particle.hide()

	if sprinting:
		water_swimming_through.volume_db = -3.0
		water_swimming_through.pitch_scale = 1.7
		grass_foot_steps.volume_db = -2.0
		grass_foot_steps.pitch_scale = 1.5
	else:
		water_swimming_through.volume_db = -7.0
		water_swimming_through.pitch_scale = 1.31
		grass_foot_steps.volume_db = -5.0
		grass_foot_steps.pitch_scale = 1
	
	var percent: float = 0
	
	if water_swimming_through.playing:
		percent = water_swimming_through.get_playback_position() / water_swimming_through.stream.get_length()
	elif grass_foot_steps.playing:
		percent = grass_foot_steps.get_playback_position() / grass_foot_steps.stream.get_length()
	
	percent *= 100
	
	if sprinting: 
		if water_swimming_through.playing:
			percent += 15.0
		elif grass_foot_steps.playing:
			percent += 5
	
	match layer:
		0:
			if percent >= 80.0 or water_swimming_through.playing == false:
				water_swimming_through.play()
		1:
			if percent >= 95.0 or grass_foot_steps.playing == false:
				grass_foot_steps.play()
	
func _move(movevec: Vector2, delt):
	if !tornadoThrownVelocity.is_zero_approx():
		velocity = tornadoThrownVelocity
		tornadoThrownVelocity = tornadoThrownVelocity.lerp(Vector2.ZERO, tornadoRecoverSpeed)
		#print(tornadoThrownVelocity.is_zero_approx())
	else:
		
		if flying == true:
			#velocity = lerp(velocity.normalized(), ((velocity.normalized() * 2) + lastMovedDirection.normalized()).normalized(), delt * 100)
			#velocity = lerp(velocity.normalized(), lastMovedDirection, delt * 100)
			velocity = lastMovedDirection
			
		elif areaFlag.match("stream") or areaFlag.match("whirlpool") or areaFlag.match("wind") or areaFlag.match("forceStream"):
			velocity = movevec
		else:
			velocity = movevec.normalized()
		
		velocity *= moveSpeed
		velocity *= speedMultiplier / 1.1
		
		tutorial_hint_detector.enabled = false
		#tutorial_hint_detector.target_position = moveVector * 20
		#if tutorial_hint_detector.is_colliding():
		#	print("tutorial")
		
		if !flying and (layer == 0 or layer == -1):
			velocity *= waterSpeedMultiplier
			
		if sprinting:
			velocity *= sprintMult
		elif flying:
			velocity *= flyMulti

		if !flying and !forcedFly:
			if onThorns == true:
				velocity *= thornSpeedMultiplier
				if !GameManager.difficultyValue == GameManager.Difficulty.EASY:
					GameManager.damagePlayer()
				#if global_position.distance_to(tilePosition) < 64:
		if areaFlag.match("wind"):
			var windForce: Vector2
			var minMaxForce: Vector2 = Vector2.ONE * moveSpeed * (speedMultiplier / 1) * flyMulti
			if layer == 2 or flying or forcedFly:
				windForce.x = clampf(areaForce.x, -minMaxForce.x, minMaxForce.x)
				windForce.y = clampf(areaForce.y, -minMaxForce.y, minMaxForce.y)
			else:
				windForce = areaForce/20.0
				if layer == 0:
					windForce = windForce/1.5
			velocity += windForce
			
		elif areaFlag.match("tornado"):
			var distanceFromCenter = global_position - streamRef.global_position
			var absDistance = absf(distanceFromCenter.x) + absf(distanceFromCenter.y)
			var whirlpoolvel = distanceFromCenter.normalized() * areaForce
					
			velocity += Vector2(whirlpoolvel.y, -whirlpoolvel.x) * tornadoMultiplier * (streamRef.size / absDistance + 1)
			velocity += (streamRef.global_position - global_position).normalized() * 100 * (streamRef.size / absDistance + 1) * tornadoMultiplier
					
			backwards_detector.enabled = true
			backwards_detector.target_position = (Vector2(whirlpoolvel.y, -whirlpoolvel.x) + ((streamRef.global_position - global_position).normalized() * (streamRef.size / absDistance + 1) * tornadoMultiplier)).normalized() * 13
			#print(absDistance)
			if backwards_detector.is_colliding() or absDistance < 110:
				tornadoThrownVelocity = velocity
				GameManager.damagePlayer(2)
		elif areaFlag.match("tornadoSafe"):
			var distanceFromCenter = global_position - streamRef.global_position
			var absDistance = absf(distanceFromCenter.x) + absf(distanceFromCenter.y)
			var whirlpoolvel = distanceFromCenter.normalized() * areaForce
			
			var multiplier: float = 1
			if flying or forcedFly or layer == 2:
				multiplier = 1.2
					
			velocity += Vector2(whirlpoolvel.y, -whirlpoolvel.x) * tornadoMultiplier/2.0 * (streamRef.size / absDistance + 1) * multiplier
			velocity += (streamRef.global_position - global_position).normalized() * (streamRef.size / absDistance + 1) * tornadoMultiplier * 10 * multiplier
					
			backwards_detector.enabled = true
			backwards_detector.target_position = (Vector2(whirlpoolvel.y, -whirlpoolvel.x) + ((streamRef.global_position - global_position).normalized() * (streamRef.size / absDistance + 1) * tornadoMultiplier)).normalized() * 13
			#print(absDistance)
			if backwards_detector.is_colliding() or absDistance < 110:
				tornadoThrownVelocity = velocity * streamRef.size/10
				GameManager.damagePlayer(2)

		if !flying and !forcedFly and !layer == 1: 
			if areaFlag == "stream":
				backwards_detector.enabled = true
				backwards_detector.target_position = areaForce.normalized() * 16
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
					
					#backwards_detector.enabled = true
					#backwards_detector.target_position = Vector2(whirlpoolvel.y, -whirlpoolvel.x).normalized() * 20
					#if backwards_detector.is_colliding():
					#	GameManager.damagePlayer()
					
					velocity += Vector2(whirlpoolvel.y, -whirlpoolvel.x) * whirlPoolMultiplier * (streamRef.size / absDistance + 1)
					velocity += (streamRef.global_position - global_position).normalized() * (streamRef.size / absDistance + 1) * whirlPoolMultiplier * 5
					
					backwards_detector.enabled = true
					backwards_detector.target_position = (Vector2(whirlpoolvel.y, -whirlpoolvel.x) + ((streamRef.global_position - global_position).normalized() * (streamRef.size / absDistance + 1) * whirlPoolMultiplier)).normalized() * 20
					if backwards_detector.is_colliding():
						GameManager.damagePlayer()
					
			elif areaFlag.match("forcestream"):
				backwards_detector.enabled = true
				backwards_detector.target_position = areaForce.normalized() * 13
				if backwards_detector.is_colliding():
					GameManager.damagePlayer()
				velocity += areaForce * waterSpeedMultiplier
			else:
				backwards_detector.enabled = false
		if flyDelayTimer > 0:
			if areaFlag != "tornado" and areaFlag != "tornadoSafe":
				velocity = movevec.normalized() * moveSpeed / 1.4
		
	var colliding = move_and_slide()
	if colliding and flying:
		GameManager.damagePlayer(1)
		if !forcedFly:
			_toggleFly(false)
	
