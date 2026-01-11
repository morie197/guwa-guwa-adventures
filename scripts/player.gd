extends CharacterBody2D



var layer: int = 0
var areaForce: Vector2 = Vector2.ZERO
var areaFlag: String = ""
var moveSpeed: int = 300
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
	
	if GameManager.abilities.has("fly") or GameManager.abilities.has("sprint"):
		if !flying:
			sprinting = (Input.is_action_pressed("sprint") and !tired)
		if !sprinting and areaFlag != "air":
			flying = (Input.is_action_pressed("fly") and !tired)
		
		
		
	if GameManager.abilities.has("quack"):
		if Input.is_action_just_pressed("quack"):
			GameManager.expGain(quackEXP)
			
	
			
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
	
