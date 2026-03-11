extends CharacterBody2D
class_name Player

const RADAR_CIRCLE = preload("uid://b0yv7nmxv7x5o")
const INDICATOR = preload("uid://2n3n0g72rrmu")

@onready var swimming = $swimming
@onready var walking = $walking

var flytoLand: bool = false

@onready var point_light_2d_3 = $PointLight2D3

@onready var camera_2d = $Camera2D
@onready var quack_sound = $quackSound
@onready var radar_sound = $radarSound
@onready var grass_foot_steps = $grassFootSteps
@onready var water_swimming_through = $waterSwimmingThrough
@onready var under_water_sounds = $underWaterSounds
@onready var wings_flying_sound = $wingsFlyingSound
@onready var wings_flapping_sound = $wingsFlappingSound
@onready var found_treat_sound = $foundTreat
@onready var lost_audio = $lostAudio

@onready var treat_radius = %treatRadius

var timeBeingDamaged: float
var timeBeingDamagedUntilHit: float = 0.15

var indicator

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

var treatFindRangeMult: float = 2.0

var healTimer: Timer
var areaSwitchTimer: Timer

var onThorns: bool = false

var underwaterStaminaDrain: float = 0.6

var underwater: bool = false

var enduranceMultiplier: float = 1.0
var rangeMultiplier: float = 1.0
var speedMultiplier: float = 1.0

var resistanceMultiplier =  1.0
var visibilityMultiplier =  1.0
var agilityMultiplier = 1.0

var moveVector: Vector2 = Vector2.ZERO
var mouseScrollInput: float

@export var streamMoveSpeed: float = 160
@export var whirlPoolMultiplier: float = 2
@export var areaForceTransitionSpeed: float = 4


@onready var backwards_detector = $backwardsDetector
@onready var tutorial_hint_detector = $tutorialHintDetector

@onready var damaged_sound = %damagedSound

@export var wonDelay: float = 2.0

@export var zoomMin: float = 1.25 # maximum amount zoomed OUT (bigger)
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

var areaTransitionTime: float = 0.9

@export var radarRange: float = 400
@export var radarCooldown: float = 3

var tornadoThrownVelocity: Vector2 = Vector2.ZERO

var migrationTime: float = 5
var migrateTimer: float = 0
var migrating: bool = false

var travelingTime: float = 1
var travelingTimer: float = 0
var traveling: bool = false

var quackTimer: float = 0
var radarTimer: float = 0
var targetZoom: Vector2

var lastMovedDirection: Vector2 = Vector2.ZERO

var colliding

@onready var area_collider = $AreaCollider
@onready var quack_collider = $QuackCollider

@onready var radar_collider = $RadarCollider

var streamRef

var newArea: Vector2 = Vector2.ZERO

var tilePosition: Vector2i

var healRegenerationTime: float = 45.0

signal quack
signal radar

signal updatedStamina(current: int, max: int)

func _ready():
	camera_2d.make_current()
	area_collider.area_entered.connect(_area_enter)
	area_collider.area_exited.connect(_area_exit)
	
	GameManager.changedMapLevel.connect(_showOnMap)
	
	healTimer = Timer.new()
	add_child(healTimer)
	healTimer.timeout.connect(GameManager.healPlayer.bind(1, true))
	healTimer.timeout.connect(_regenHeal)
	_regenHeal()
	
	areaSwitchTimer = Timer.new()
	add_child(areaSwitchTimer)
	areaSwitchTimer.timeout.connect(_transitionArea)
	
	targetZoom = Vector2(zoomMin, zoomMin)
	
	initializeValues()

func _unhandled_input(event):
	if GameManager.worldManager == null:
		return
	
	if GameManager.lost:
		return
		

	
	if Input.is_action_just_pressed("menuback pause"):
		if GameManager.minigame or GameManager.inUpgradeMenu or GameManager.wonGame or GameManager.cameraShown or GameManager.worldManager.inMap:
			return
		if GameManager.worldManager.ui_manager != null:
			GameManager.worldManager.ui_manager.pause()
	if GameManager.paused or GameManager.minigame:
		return
	
	if event is InputEventMouseButton:
		if GameManager.worldManager != null:
			if GameManager.worldManager.inMap:
				return
		
		if Input.is_action_just_pressed("zoomin"):
			mouseScrollInput = zoomInAmount
		elif Input.is_action_just_pressed("zoomout"):
			mouseScrollInput = zoomOutAmount
	
	if event is InputEventKey:
		if GameManager.abilities.has("sonar") and radarTimer <= 0:
			if Input.is_action_pressed("search"):
				_radar()
				
		if GameManager.worldManager != null:
			if GameManager.worldManager.inMap:
				return
		
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
			if !(GameManager.abilities.has("travel") and (GameManager.level < 90 and GameManager.worldManager.levelName == "Hidden Grove")):
				if flying and Input.is_action_pressed("quack"):
					migrating = true
					if migrateTimer <= 0:
						migrateTimer = migrationTime
				else:
					if migrating:
						migrateTimer = 0
						GameManager.worldManager.ui_manager.updateMigrateBar(floor(migrateTimer * 100), floor(migrationTime * 100))
						migrating = false
		
		#if GameManager.abilities.has("travel"):
			#if flying and Input.is_action_pressed("search"):
				#traveling = true
				#if travelingTimer <= 0:
					#travelingTimer = travelingTime
			#else:
				#if traveling:
					#travelingTimer = 0
					#GameManager.worldManager.ui_manager.updateMigrateBar(floor(travelingTimer * 100), floor(travelingTime * 100))
					#traveling = false
		
		if GameManager.abilities.has("quack") and quackTimer <= 0:
			if Input.is_action_just_pressed("quack"):
				_quack()
				
		
			
		if GameManager.abilities.has("dive") and layer == -1:
			if Input.is_action_just_pressed("dive"):
				GameManager.worldManager.switchUnderOverGround()
				
		if Input.is_action_just_pressed("zoomin") and mouseScrollInput == 0:
			mouseScrollInput = zoomInAmount * keyZoomMult
		elif Input.is_action_just_pressed("zoomout") and mouseScrollInput == 0:
			mouseScrollInput = zoomOutAmount / keyZoomMult
		
func _animateDuck():
	if tornadoThrownVelocity.is_zero_approx():
		if moveVector.x < 0:
			walking.flip_h = true
			%walktofly.flip_h = true
			%flying.flip_h = true
			swimming.flip_h = true
		elif moveVector.x > 0:
			walking.flip_h = false
			%walktofly.flip_h = false
			%flying.flip_h = false
			swimming.flip_h = false
	
	if tornadoThrownVelocity.is_zero_approx():
		if flyDelayTimer > 0.0:
			if %flying.is_playing():
				flytoLand = true
				%flying.stop()
			%flying.visible = false
			%walktofly.visible = true
			var progFrame: float = 0.0
			if flytoLand:
				progFrame = (clampf(flyDelayTimer / flyDelay, 0, 1))
			else:
				progFrame = (1.0 - clampf(flyDelayTimer / flyDelay, 0, 1))
			%walktofly.frame = %walktofly.sprite_frames.get_frame_count("default") * progFrame
			#print(%walktofly.frame)
			#print(clampf(flyDelayTimer / flyDelay, 0, 1))
			walking.visible = false
			if walking.is_playing():
				walking.stop()
			swimming.visible = false
			if swimming.is_playing():
				swimming.stop()
		elif flying:
			%walktofly.visible = false
			%flying.visible = true
			%flying.play()
			
			walking.visible = false
			if walking.is_playing():
				walking.stop()
			swimming.visible = false
			if swimming.is_playing():
				swimming.stop()
		else:
			flytoLand = false
			if %flying.is_playing():
				%flying.stop()
			%flying.visible = false
			%walktofly.visible = false
			
			if layer == 0 or layer == -1:
				walking.visible = false
				swimming.visible = true
			if layer == 1:
				swimming.visible = false
				walking.visible = true
			if moveVector != Vector2.ZERO:
				if layer == 0 or layer == -1:
					if walking.is_playing():
						walking.stop()
					swimming.play()
				if layer == 1:
					if swimming.is_playing():
						swimming.stop()
					walking.play()
			else:
				if walking.is_playing():
					walking.stop()
				elif swimming.is_playing():
					swimming.stop()
			
			
	if flying:
		if %flying.frame == 3:
			wings_flying_sound.play()

func _physics_process(delta):
	if GameManager.loadingLevel:
		return
	if GameManager.worldManager != null:
		if GameManager.worldManager.inMap:
			return
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
	#print(camera_2d.global_position)
	#print(camera_2d.is_current())
	#print(global_position)
	
	if GameManager.loadingLevel:
		#print("returning")
		return
	
	if GameManager.wonGame:
		if bgm.volume_db <= -35 and bgm.playing:
			bgm.stream_paused = true
		else:
			bgm.volume_db = lerp(bgm.volume_db, -40.0, bgmFadeTime * delta )
	elif GameManager.lost:
		bgm.stream_paused = true
	elif GameManager.minigame:
		flying = false
		migrating = false
		traveling = false
		migrateTimer = 0
		bgm.stream_paused = true
	elif bgm.stream_paused == true:
		bgm.stream_paused = false
	elif !bgm.playing:
		bgm.play()
	else:
		bgm.volume_db = bgmVolume
		
	if GameManager.paused:	
		moveVector = Vector2.ZERO
		return
	if migrating:
		if flying and GameManager.worldLayer == 1:
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
		
	if GameManager.worldLayer == 0 or GameManager.worldManager.levelName == "Hidden Grove":
		point_light_2d_3.enabled = true
	else:
		point_light_2d_3.enabled = false
		
	#if traveling:
		#if migrating:
			#migrating = false
		#if flying and GameManager.worldLayer == 1:
			#if travelingTimer > 0:
				#bgm.volume_db = lerp(bgm.volume_db, -40.0, bgmFadeTime * delta )
				#travelingTimer -= delta
				#GameManager.worldManager.ui_manager.updateMigrateBar(floor(travelingTimer * 100), floor(travelingTime * 100))
			#else:
				#_traveled()
		#else:
			#bgm.volume_db = bgmVolume
			#travelingTimer = clampf(travelingTimer + delta * 1.5, 0, travelingTime)
			#GameManager.worldManager.ui_manager.updateMigrateBar(floor(travelingTimer * 100), floor(travelingTime * 100))
		
	if GameManager.worldLayer == 0 and (layer != 1 and layer != 2):
		underwater = true
	else:
		underwater = false
	
	if underwater:
		if stamina > 0:
			stamina -= delta * underwaterStaminaDrain
		else:
			GameManager.damagePlayer(1)
			modulate = Color(1, clampf(1.0 - timeBeingDamagedUntilHit * 2, 0, 1), clampf(1.0 - timeBeingDamagedUntilHit * 2, 0, 1))
		
		emitUpdatedStaminaValue()
		if under_water_sounds.playing == false: 
			under_water_sounds.play()
	else:
		if under_water_sounds.playing: 
			under_water_sounds.stop()
		
	if timeBeingDamaged <= 0:
		modulate = modulate.lerp(Color(1, clampf(1.0 - timeBeingDamaged * 2, 0, 1), clampf(1.0 - timeBeingDamaged * 2, 0, 1)), clampf(delta * 3, 0 , 1))
		#print(modulate)
		
	if flyDelayTimer > 0:
		flyDelayTimer -= delta
		
	if healTimer.paused:
		healTimer.paused = false
		
	if areaForce != newArea:
		areaForce = lerp(areaForce, newArea, delta * areaForceTransitionSpeed)
		if abs(areaForce.x - newArea.x) < 1 and abs(areaForce.y - newArea.y) < 1:
			areaForce = Vector2.ZERO
		#print(areaForce)
	else:
		if areaFlag == "":
			#print("else")
			areaForce = Vector2.ZERO
		
	if GameManager.worldManager != null:
		if GameManager.worldManager.ui_manager != null:
			if GameManager.abilities.has("sonar"): 
				GameManager.worldManager.ui_manager.radar_ready.visible = radarTimer <= 0
		
	if moveVector != Vector2.ZERO and tornadoThrownVelocity.is_zero_approx():
		lastMovedDirection = lastMovedDirection.lerp(moveVector, delta * flyLerpSpeed)
		
	if !Input.is_action_pressed("fly") and (flying or forcedFly) and layer != 2:
		_toggleFly(false)
		
	if flying and !wings_flying_sound.playing:
		if GameManager.loadingLevel:
			return
	
	if quackTimer > 0:
		quackTimer -= delta
		
	if radarTimer > 0:
		radarTimer -= delta

	if layer == 2 and tired and forcedFly:
		GameManager.damagePlayer(1)
		modulate = Color(1, clampf(1.0 - timeBeingDamagedUntilHit * 2, 0, 1), clampf(1.0 - timeBeingDamagedUntilHit * 2, 0, 1))
	
	GameManager.minimapCam.global_position = global_position
	GameManager.minimapCam.zoom = camera_2d.zoom / 8
	
	if (moveVector != Vector2.ZERO) or (forcedFly or flying) or ((areaFlag.match("wind") or areaFlag.match("stream") or areaFlag.match("forcestream") or areaFlag.match("whirlpool") or areaFlag.match("tornado")) and streamRef != null):
		_stateEffects()
		
		tileCheck()
		#print(layer)
		
	if mouseScrollInput != 0:
		var minimumZoomAmount = zoomMin / (1 + ((rangeMultiplier - 1) * rangeMultZoomFactor))
		var calculatedZoom: float = clamp(camera_2d.zoom.x * mouseScrollInput, minimumZoomAmount, ZOOMMAX)
		targetZoom = Vector2(calculatedZoom, calculatedZoom)
		mouseScrollInput = 0
		
	if camera_2d.zoom != targetZoom:
		camera_2d.zoom = lerp(camera_2d.zoom, targetZoom, zoomSpeed * delta)
	
	_animateDuck()
	
	if sprinting or flying:
		if stamina > 0: # prevent negative stamina values
			if sprinting:
				walking.speed_scale = 2.5
				if moveVector != Vector2.ZERO and tornadoThrownVelocity.is_zero_approx():
					stamina -= delta
				else:
					sprinting = false
			if flying and tornadoThrownVelocity.is_zero_approx():
				stamina -= delta / flyStaminaMulti
			emitUpdatedStaminaValue()
		else:
			walking.speed_scale = 1.3
			tired = true
			if sprinting: 
				sprinting = false
			elif flying and layer != 2 and !areaFlag.match("wind") and !forcedFly: 
				_toggleFly(false)
	else:
		walking.speed_scale = 1.3
		if stamina < maxStamina * resistanceMultiplier and !underwater: 
			stamina+=delta * staminaRecoveryRate * enduranceMultiplier
			emitUpdatedStaminaValue()
		else:
			tired = false

func _showOnMap(on: bool):
	if on:
		%Polygon2D.color = Color.WHITE
	else:
		%Polygon2D.color = Color.GRAY
func _area_enter(area):
	streamRef = area
	areaFlag = area.flag
	
	if areaFlag == "wind" or "safeTornado":
		newArea = area.force * streamMoveSpeed
	else:
		newArea = area.force * streamMoveSpeed
		areaForce = area.force * streamMoveSpeed
	
	areaSwitchTimer.wait_time = areaTransitionTime
	if areaSwitchTimer.is_inside_tree():
		areaSwitchTimer.start()
	
	if areaFlag == "stream" or "whirlpool":
		#print("nya")
		areaForce = area.force * streamMoveSpeed
	
func _area_exit(_area):
	streamRef = null
	#areaForce = Vector2.ZERO
	newArea = Vector2.ZERO
	areaSwitchTimer.wait_time = areaTransitionTime
	if areaSwitchTimer.is_inside_tree():
		areaSwitchTimer.start()
	
func loadGameChecks():
	tileCheck()
	flying = false
	velocity = Vector2.ZERO
	sprinting = false
	migrating = false
	
func tileCheck():
	if GameManager.worldManager == null:
		return
	newtile = GameManager.worldManager.getTileUnderPos(global_position)
	if tile != newtile:
		if GameManager.worldManager != null:
			GameManager.worldManager.updateFOW(true)
		if (layer == 2 and !(areaFlag.match("wind") or areaFlag == "tornado")):
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
	tornadoThrownVelocity = Vector2.ZERO
	timeBeingDamaged = 0
	modulate = Color.WHITE
	tileCheck()
	if streamRef == null:
		areaForce = Vector2.ZERO
	
	stamina = maxStamina * resistanceMultiplier
	emitUpdatedStaminaValue()
	quack_collider.get_child(0).shape.radius = quackRange * rangeMultiplier
	radar_collider.get_child(0).shape.radius = radarRange * rangeMultiplier
	if GameManager.abilities.has("travel"):
		point_light_2d_3.texture_scale = 3 * visibilityMultiplier
	
func emitUpdatedStaminaValue():
	updatedStamina.emit(round(stamina * 100), round(maxStamina * resistanceMultiplier * 100))

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
	if GameManager.worldManager.levelName == "Hidden Grove" and GameManager.level < 90:
		return
	set_collision_mask_value(1, false)
	set_collision_layer_value(5, false)
	#if !GameManager.abilities.has("travel") and GameManager.levelLoaded and !(GameManager.worldManager.levelName == "Hidden Grove" and GameManager.level > 90):
		
	
	if GameManager.abilities.has("travel") and !(GameManager.worldManager.levelName == "Hidden Grove"):
		_travelOrWin()
	
	
	if (!GameManager.abilities.has("travel") and GameManager.levelLoaded) or (GameManager.worldManager.levelName == "Hidden Grove" and GameManager.level > 90):
		GameManager.won()	
		
		_winGameCamera()
		
	
	GameManager.paused = true

func _winGameCamera():
	var timmy = Timer.new()
	add_child(timmy)
	timmy.wait_time = wonDelay
	timmy.timeout.connect(camera_2d.reparent.bind(GameManager, true))
	timmy.timeout.connect(func assignCamera(): GameManager.playerCamCredits = camera_2d)
	timmy.timeout.connect(audio_listener_2d.queue_free)
	timmy.timeout.connect(timmy.queue_free)
	timmy.start()

func _travelOrWin():
	if GameManager.worldManager == null:
		return
	if GameManager.worldManager.ui_manager == null:
		return
		
	var popup = GameManager.worldManager.ui_manager.POPUP.instantiate()
	popup.warningText = tr("TRAVEL_HIDDEN_GROVE_PROMPT")
	GameManager.worldManager.ui_manager.add_child(popup)
	#
	#popup.noButton.text = "Travel"
	#popup.yesButton.text = "Credits"
		
	popup.no.connect(popup.queue_free)
	popup.yes.connect(popup.queue_free)
	popup.no.connect(GameManager.won)
	popup.no.connect(_winGameCamera)
	popup.yes.connect(GameManager.travelToMap)
	
func _radar():
	radar_sound.play()
	radarTimer = radarCooldown
	radar.emit()
	var radCircle = RADAR_CIRCLE.instantiate()
	radCircle.startLevel = GameManager.worldLayer
	GameManager.worldManager.add_child(radCircle)
	if GameManager.abilities.has("treatdetect"):
		var closest = GameManager.worldManager.getClosestTreat()
		if closest != null:
			#print("found:", closest)
			
			
			var distanceToClosest = closest.global_position.distance_to(self.global_position)
			var timmy = Timer.new()
			timmy.wait_time = clampf(distanceToClosest/1000.0, 0.1, 5)
			
			#print(distanceToClosest)
			if distanceToTreatFormula(closest.global_position):
				if indicator != null and !is_queued_for_deletion():
					indicator.queue_free()
				indicator = INDICATOR.instantiate()
				indicator.pointAt = closest
				add_child(indicator)
				indicator.delayTime = timmy.wait_time
				indicator.hide()
				
				timmy.timeout.connect(found_treat_sound.play)
				timmy.timeout.connect(timmy.queue_free)
				timmy.timeout.connect(indicator.show)
				timmy.timeout.connect(_createTreatRadarCircle.bind(closest.global_position, GameManager.worldLayer))
				add_child(timmy)
				timmy.start()
			
			
			
			#indicator.global_rotation = (global_position - closest.global_position).normalized().rotated(PI / 2).angle()
			#var vectorAngle = (global_position - closest.global_position).normalized()
			#indicator.global_position += Vector2(-vectorAngle.x, -vectorAngle.y) * 64

		
	radCircle.global_position = global_position
	radCircle.maxRadius = radarRange * rangeMultiplier
	
func _createTreatRadarCircle(global_pos: Vector2, level: int = 1):
	var treatRadCircle = RADAR_CIRCLE.instantiate()
	GameManager.worldManager.add_child(treatRadCircle)
	treatRadCircle.global_position = global_pos
	treatRadCircle.startLevel = level
	treatRadCircle.circleColor = Color(0.863, 0.929, 0.0, 0.302)
	treatRadCircle.radiusExpandSpeed = 120
	treatRadCircle.maxRadius = (radarRange * rangeMultiplier)/2.0
	
func distanceToTreatFormula(global_pos: Vector2) -> bool:
	var distanceToClosest = global_pos.distance_to(self.global_position)
	var mult: float = 1
	if GameManager.worldManager.levelName == "Hidden Grove":
		mult = 0.1 * visibilityMultiplier
	if distanceToClosest < radarRange * rangeMultiplier * treatFindRangeMult * GameManager.level/10.0 * mult:
		return true
	else:
		return false
	
func _transitionArea():
	pass
	
func _stateEffects():
	if flying or forcedFly:
		water_swimming_through.stop()
		grass_foot_steps.stop()


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
			if moveVector != Vector2.ZERO:
				if percent >= 80.0 or water_swimming_through.playing == false:
					water_swimming_through.play()
		1:
			if moveVector != Vector2.ZERO or areaFlag == "wind" or areaFlag == "safeTornado":
				if percent >= 95.0 or grass_foot_steps.playing == false:
					grass_foot_steps.play()
	
func _showHint():
	var coll = tutorial_hint_detector.get_collider()
	#print(coll.name)
	#print("nice")
	if coll == null:
		return
	if coll.is_queued_for_deletion():
		return
	elif coll.has_method("showHint"):
		coll.showHint(to_global(tutorial_hint_detector.target_position))
	
func _move(movevec: Vector2, delt):
	if !tornadoThrownVelocity.is_zero_approx():
		modulate = Color(1, 0.4, 0.4)
		velocity = tornadoThrownVelocity
		tornadoThrownVelocity = tornadoThrownVelocity.lerp(Vector2.ZERO, tornadoRecoverSpeed)
		#print(tornadoThrownVelocity.is_zero_approx())
	else:
		
		if flying == true:
			#velocity = lerp(velocity.normalized(), ((velocity.normalized() * 2) + lastMovedDirection.normalized()).normalized(), delt * 100)
			#velocity = lerp(velocity.normalized(), lastMovedDirection, delt * 100)
			velocity = lastMovedDirection
		elif (((areaFlag.match("stream") or areaFlag.match("whirlpool") or areaFlag.match("forcestream")) and layer != 1) or (areaFlag.match("wind") and (flying or forcedFly or layer == 2))) and streamRef != null:
			velocity = movevec
		else:
			velocity = movevec.normalized()
		
		velocity *= moveSpeed
		velocity *= speedMultiplier / 1.1
		velocity *= agilityMultiplier
		
		tutorial_hint_detector.enabled = true
		tutorial_hint_detector.target_position = moveVector * 20
		if tutorial_hint_detector.is_colliding():
			_showHint()
		
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
					modulate = Color(1, clampf(1.0 - timeBeingDamagedUntilHit * 2, 0, 1), clampf(1.0 - timeBeingDamagedUntilHit * 2, 0, 1))
				#if global_position.distance_to(tilePosition) < 64:
		if areaFlag.match("wind"):
			var windForce: Vector2
			var minMaxForce: Vector2 = Vector2.ONE * moveSpeed * (speedMultiplier / 1) * flyMulti * agilityMultiplier
			if layer == 2 or flying or forcedFly:
				windForce.x = clampf(areaForce.x, -minMaxForce.x, minMaxForce.x)
				windForce.y = clampf(areaForce.y, -minMaxForce.y, minMaxForce.y)
			else:
				windForce = areaForce/20.0
				if layer == 0:
					windForce = windForce/1.5
			velocity += windForce
			
		elif areaFlag.match("tornado"):
			if streamRef != null:
				var distanceFromCenter = global_position - streamRef.global_position
				var absDistance = absf(distanceFromCenter.x) + absf(distanceFromCenter.y)
				var whirlpoolvel = distanceFromCenter.normalized() * areaForce
						
				velocity += Vector2(whirlpoolvel.y, -whirlpoolvel.x) * tornadoMultiplier * (streamRef.size / absDistance + 1)
				velocity += (streamRef.global_position - global_position).normalized() * 100 * (streamRef.size / absDistance + 1) * tornadoMultiplier
						
				backwards_detector.enabled = true
				backwards_detector.target_position = (Vector2(whirlpoolvel.y, -whirlpoolvel.x) + ((streamRef.global_position - global_position).normalized() * (streamRef.size / absDistance + 1) * tornadoMultiplier)).normalized() * 13
				#print(absDistance)
				if absDistance < 110:
					tornadoThrownVelocity = velocity
					_toggleFly(false)
					GameManager.damagePlayer(2)
					modulate = Color(1, clampf(1.0 - timeBeingDamagedUntilHit * 2, 0, 1), clampf(1.0 - timeBeingDamagedUntilHit * 2, 0, 1))
		elif areaFlag.match("tornadoSafe"):
			if streamRef != null:
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
				#if absDistance < 110:
				#	tornadoThrownVelocity = velocity * streamRef.size/10
				#	GameManager.damagePlayer(2)

		if !flying and !forcedFly and !layer == 1: 
			if areaFlag == "stream":
				backwards_detector.enabled = true
				backwards_detector.target_position = areaForce.normalized() * 16
				#if backwards_detector.is_colliding() and streamRef != null:
					#GameManager.damagePlayer()
				var streamForce: Vector2
				var minMaxForce: Vector2 = Vector2.ONE * moveSpeed * (speedMultiplier / 1) * waterSpeedMultiplier * agilityMultiplier
				streamForce.x = clampf(areaForce.x, -minMaxForce.x, minMaxForce.x)
				streamForce.y = clampf(areaForce.y, -minMaxForce.y, minMaxForce.y)
				velocity += streamForce
			elif areaFlag == "whirlpool":
				if streamRef != null:
					var distanceFromCenter = global_position - streamRef.global_position
					var absDistance = absf(distanceFromCenter.x) + absf(distanceFromCenter.y)
					var whirlpoolvel = distanceFromCenter.normalized() * areaForce
			
					
					velocity += Vector2(whirlpoolvel.y, -whirlpoolvel.x) * whirlPoolMultiplier * (streamRef.size / absDistance + 1)
					velocity += (streamRef.global_position - global_position).normalized() * (streamRef.size / absDistance + 1) * whirlPoolMultiplier * 5
					
					backwards_detector.enabled = true
					backwards_detector.target_position = (Vector2(whirlpoolvel.y, -whirlpoolvel.x) + ((streamRef.global_position - global_position).normalized() * (streamRef.size / absDistance + 1) * whirlPoolMultiplier)).normalized() * 20
					#if backwards_detector.is_colliding() and streamRef != null:
						#GameManager.damagePlayer()
					
			elif areaFlag.match("forcestream"):
				backwards_detector.enabled = true
				backwards_detector.target_position = areaForce.normalized() * 13
				#if backwards_detector.is_colliding() and streamRef != null:
					#GameManager.damagePlayer()
				velocity += areaForce * waterSpeedMultiplier * agilityMultiplier
			else:
				backwards_detector.target_position = Vector2.ZERO
				backwards_detector.force_raycast_update()
				backwards_detector.enabled = false
		if flyDelayTimer > 0:
			if areaFlag != "tornado" and areaFlag != "tornadoSafe":
				velocity = movevec.normalized() * moveSpeed / 1.4
		
	if streamRef == null:
		backwards_detector.target_position = Vector2.ZERO
		backwards_detector.enabled = false
		
	var colliding = move_and_slide()
	if (colliding and flying) or (backwards_detector.is_colliding() and (((areaFlag == "forcestream" or areaFlag == "stream" or areaFlag == "whirlpool") and layer == 0 or layer == -1) and streamRef != null)):
		if timeBeingDamaged < timeBeingDamagedUntilHit:
			timeBeingDamaged += delt
			modulate = Color(1, clampf(1.0 - timeBeingDamaged  * 2, 0, 1), clampf(1.0 - timeBeingDamaged * 2, 0, 1))
		if timeBeingDamaged >= timeBeingDamagedUntilHit:
			GameManager.damagePlayer(1)
			#_toggleFly(false)
	elif timeBeingDamaged > 0:
		timeBeingDamaged -= delt
	
	if colliding and (movevec != Vector2.ZERO) and (movevec != movevec.normalized()) and (((areaFlag.match("stream") or areaFlag.match("whirlpool") or areaFlag.match("forcestream")) and layer != 1) or (areaFlag.match("wind") and (flying or forcedFly or layer == 2))) and streamRef != null:
		%slide.emitting = true
	else:
		%slide.emitting = false
		
		
		
		
