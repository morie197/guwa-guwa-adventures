extends CharacterBody2D

@onready var swimming = $swimming
@onready var walking = $walking


var layer: int = 0
var areaForce: Vector2 = Vector2.ZERO
var areaFlag: String = ""
var moveSpeed: int = 100
var maxStamina: float = 1.20
var staminaRecoveryRate: float = 0.4
var stamina: float = 0
var sprintMult: float = 1.3
var flyMulti: float = 2.0
var flyStaminaMulti: float = 1.3
var sprinting: bool = false
var flying: bool = false
var tired: bool = false
var quackEXP: int = 100
var tile: Vector2i = Vector2i.ZERO

var staminaMultiplier: float = 1.0
var zoomMultiplier: float = 1.0 # unused
var speedMultiplier: float = 1.0

var moveVector: Vector2 = Vector2.ZERO

@onready var area_collider = $AreaCollider


func _ready():
	area_collider.area_entered.connect(_area_enter)
	stamina = maxStamina * staminaMultiplier
	
	


func _physics_process(delta):
	if GameManager.paused:
		velocity = Vector2.ZERO
		return
	_move(moveVector)
	
func _process(delta):
	if GameManager.paused:
		return
	
	moveVector.y = Input.get_axis("up", "down")
	moveVector.x = Input.get_axis("left", "right")
	
	if moveVector != Vector2.ZERO:
		tile = GameManager.getTileUnderPos(global_position)
		if tile == Vector2i(0, 0) or tile.x == 8:
			layer = 0
		elif tile == Vector2i(0, 4):
			layer = 1
	
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
	
	if GameManager.abilities.has("fly") or GameManager.abilities.has("sprint"):
		if !flying:
			sprinting = (Input.is_action_pressed("sprint") and !tired)
		if !sprinting and areaFlag != "air":
			flying = (Input.is_action_pressed("fly") and !tired)
		
	if GameManager.abilities.has("quack"):
		if Input.is_action_just_pressed("quack"):
			GameManager.expGain(quackEXP)
			
	if GameManager.abilities.has("dive") and areaFlag == "dive":
		if Input.is_action_just_pressed("dive"):
			GameManager.switchUnderOverGround()
			
	
			
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
	#print(area.layer, " ", area.force, " ", area.flag, " ")
	layer = area.layer
	areaForce = area.force
	areaFlag = area.flag
	
func _move(movevec: Vector2):
	velocity = movevec.normalized()
	velocity *= moveSpeed
	velocity *= speedMultiplier
	if sprinting:
		velocity *= sprintMult
	elif flying:
		velocity *= flyMulti
		
	if !flying: 
		velocity += areaForce
	
	move_and_slide()
	
