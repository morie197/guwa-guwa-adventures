extends CharacterBody2D

const RADAR_CIRCLE = preload("uid://b0yv7nmxv7x5o")

@onready var swimming = $swimming
@onready var walking = $walking

@onready var camera_2d = $Camera2D
@onready var quack_sound = $quackSound
@onready var radar_sound = $radarSound

@onready var bgm = $BGM

var layer: int = 0
var areaForce: Vector2 = Vector2.ZERO
var areaFlag: String = ""
var moveSpeed: int = 110
var maxStamina: float = 5.0
var staminaRecoveryRate: float = 2
var stamina: float = 0
var sprintMult: float = 1.2
var flyMulti: float = 2.0
var flyStaminaMulti: float = 1.3
var sprinting: bool = false
var flying: bool = false
var tired: bool = false
var tile: Vector2i = Vector2i.ZERO
var newtile: Vector2i = Vector2i.ZERO

var staminaMultiplier: float = 1.0
var rangeMultiplier: float = 1.0
var speedMultiplier: float = 1.0

var moveVector: Vector2 = Vector2.ZERO
var mouseScrollInput: float

@export var streamMoveSpeed: float = 120
@export var whirlPoolMultiplier: float = 2
@export var areaForceTransitionSpeed: float = 10

@export var zoomMin: float = 1.5 # maximum amount zoomed OUT (bigger)
@export var ZOOMMAX: float = 5 # maximum amount zoomed IN (smaller)
@export var zoomSpeed: float = 10.0
@export var zoomInAmount: float = 1.2
@export var zoomOutAmount: float = 0.8
@export var rangeMultZoomFactor: float = 1.1
@export var keyZoomMult: float = 1.5

@export var quackRange: float = 60
@export var quackCooldown: float = 0.20
@export var quackFalloffZoom: float = 2
@export var quackFalloffAmountMulti: float = 8

@export var radarRange: float = 120
@export var radarCooldown: float = 1.5

var quackTimer: float = 0
var radarTimer: float = 0
var targetZoom: Vector2

@onready var area_collider = $AreaCollider
@onready var quack_collider = $QuackCollider

@onready var radar_collider = $RadarCollider

var streamRef

signal quack
signal radar


func _ready():
	area_collider.area_entered.connect(_area_enter)
	area_collider.area_exited.connect(_area_exit)
	
	stamina = maxStamina * staminaMultiplier
	
	targetZoom = Vector2(zoomMin, zoomMin)
	
	initializeValues()

func _unhandled_input(event):
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
				if !sprinting and areaFlag != "air":
					flying = (Input.is_action_pressed("fly") and !tired)
		
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
	if GameManager.paused:
		velocity = Vector2.ZERO
		return
	_move(moveVector)
	
func _process(delta):
	if GameManager.minigame:
		bgm.stop()
	elif bgm.playing == false:
		bgm.play()
	
	if GameManager.paused:
		moveVector = Vector2.ZERO
		return
		
	if areaFlag == "":
		areaForce = lerp(areaForce, Vector2.ZERO, delta * areaForceTransitionSpeed)
		
	
	if quackTimer > 0:
		quackTimer -= delta
		
	if radarTimer > 0:
		radarTimer -= delta

	
	if moveVector != Vector2.ZERO:
		newtile = GameManager.worldManager.getTileUnderPos(global_position)
		if tile != newtile:
			if areaFlag == "dive":
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
		else:
			tired = true
			if sprinting: 
				sprinting = false
			elif flying and areaFlag != "air": 
				flying = false
	else:
		if stamina < maxStamina * staminaMultiplier:
			stamina+=delta * staminaRecoveryRate
		else:
			tired = false

func _area_enter(area):
	streamRef = area
	areaFlag = area.flag
	if areaFlag == "stream" or "whirlpool":
		#print("nya")
		areaForce = area.force * streamMoveSpeed
	
func _area_exit(area):
	streamRef == null
	areaFlag = ""
	
func initializeValues():
	stamina = maxStamina * staminaMultiplier
	quack_collider.get_child(0).shape.radius = quackRange * rangeMultiplier
	radar_collider.get_child(0).shape.radius = radarRange * rangeMultiplier

func _quack():
	quack_sound.play()
	quack_sound.volume_db = 10 - clampf(quackFalloffZoom - camera_2d.zoom.x, 0, 80) * quackFalloffAmountMulti
	#print(quack_sound.volume_db)
	quackTimer = quackCooldown
	quack.emit()
	
func _radar():
	radar_sound.play()
	radarTimer = radarCooldown
	radar.emit()
	var radCircle = RADAR_CIRCLE.instantiate()
	GameManager.worldManager.add_child(radCircle)
	radCircle.global_position = global_position
	radCircle.maxRadius = radarRange * rangeMultiplier
	
func _move(movevec: Vector2):
	velocity = movevec.normalized()
	velocity *= moveSpeed
	velocity *= speedMultiplier
	if sprinting:
		velocity *= sprintMult
	elif flying:
		velocity *= flyMulti
		
	if !flying: 
		if areaFlag == "stream":
			velocity += areaForce
		elif areaFlag == "whirlpool":
			if streamRef != null:
				var distanceFromCenter = global_position - streamRef.global_position
				var absDistance = absf(distanceFromCenter.x) + absf(distanceFromCenter.y)
				print(absDistance)
				var whirlpoolvel = distanceFromCenter.normalized() * areaForce
				velocity += Vector2(whirlpoolvel.y, -whirlpoolvel.x) * whirlPoolMultiplier * (streamRef.size / absDistance + 1)
				print(velocity)
	
	move_and_slide()
	
