extends Area2D

var attack_damage: int = 1
var attackRange: float = 10.0
var parentDuck
var direction: Vector2 = Vector2.RIGHT
var speed: float = 10.0
var force: String = "enemy"

@onready var wall_collider = $wallCollider

@export var forceMultiplier: float = 50

var originPosition: Vector2 = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	body_entered.connect(_duck_detected)
	wall_collider.body_entered.connect(_wall_detected)
	global_rotation = direction.rotated(PI / 2).angle()
	#area_entered.connect(_area_detected)
	
	global_position = originPosition
	#print(originPosition)
	#print(global_position)
	
	if force == "enemy":
		#print("enemy")
		set_collision_mask_value(8, true)
	elif force == "player":
		#print("player2")
		set_collision_mask_value(10, true)
		
	#print(get_collision_layer_value(8))
	#print(get_collision_layer_value(10))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_queued_for_deletion():
		return
	#print("Self: ", global_position, " | Parent: ", get_parent().global_position)
	#print(global_position)
	
	
	if parentDuck != null:
		if global_position.distance_to(originPosition) > attackRange - 20:
			queue_free()
	
func _physics_process(delta):
	#print("Self: ", global_position, " | Parent: ", get_parent().global_position)
	global_position += direction * speed * delta * forceMultiplier
	#global_position += direction
	
func _duck_detected(body):
	if is_queued_for_deletion():
		return
	
	print(body.name)
	
	if body.name == "PlayerMinigame" and force == "enemy":
		body.quacker.damage(attack_damage, parentDuck)
		print("player")
	elif body.name == "StaticBody2D" and force == "player":
		print("enemy")
		parentDuck.minigamemanager.player_minigame.enemy_hit.play()
		body.get_parent().quacker.damage(attack_damage, parentDuck)
		
	queue_free()
	#
#func _area_detected(area):
	#if is_queued_for_deletion():
		#return
	#
	#queue_free()
	
func _wall_detected(body):
	if body.name == "PlayerMinigame" or body.name == "StaticBody2D":
		return
	else:
		print("wall")
		queue_free()
