extends Area2D
class_name GuwaProjectile

var attack_damage: int = 2
var attackRange: float = 10.0
var parentDuck
var direction: Vector2 = Vector2.RIGHT
var speed: float = 10.0
var force: String = "enemy"
var reflected: bool = false

@onready var wall_collider = $wallCollider

@export var forceMultiplier: float = 50

var originPosition: Vector2 = Vector2.ZERO

var spawnTime: float

var damaged = []

# Called when the node enters the scene tree for the first time.
func _ready():
	body_entered.connect(_duck_detected)
	area_entered.connect(_projectile_detected)
	wall_collider.body_entered.connect(_wall_detected)
	global_rotation = direction.rotated(PI / 2).angle()
	#area_entered.connect(_area_detected)
	
	global_position = originPosition
	#print(originPosition)
	#print(global_position)
	
	spawnTime = parentDuck.minigamemanager.acculumatedTime
	
	#if reflected:
	#	attack_damage = clampi(attack_damage*2, 1, 100)
	
	if force == "enemy":
		#print("enemy")
		set_collision_mask_value(8, true)
	elif force == "player":
		#print("player2")
		$Polygon2D.color = Color(0.619, 0.745, 1.0, 1.0)
		set_collision_mask_value(10, true)
		
	#print(get_collision_layer_value(8))
	#print(get_collision_layer_value(10))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_queued_for_deletion():
		return
	#print("Self: ", global_position, " | Parent: ", get_parent().global_position)
	#print(global_position)
	
	
	if parentDuck != null and !reflected:
		if global_position.distance_to(originPosition) > attackRange - 20:
			modulate = Color.DIM_GRAY
			if attack_damage != 1:
				attack_damage = clampi(attack_damage/2, 1, 100)
	
func _physics_process(delta):
	#print("Self: ", global_position, " | Parent: ", get_parent().global_position)
	global_position += direction * speed * delta * forceMultiplier
	#global_position += direction
	
func _duck_detected(body):
	if is_queued_for_deletion():
		return
		
	if parentDuck.minigamemanager.displaying:
		return
	
	
	
	if body.name == "PlayerMinigame" and force == "enemy":
		body.quacker.damage(attack_damage, parentDuck)
		if damaged.has(body):
			return
		else:
			damaged.append(body)
	elif body.name == "StaticBody2D" and force == "player":
		if damaged.has(body):
			return
		else:
			damaged.append(body)
		parentDuck.minigamemanager.player_minigame.enemy_hit.play()
		body.get_parent().quacker.damage(attack_damage, parentDuck)
	#
#func _area_detected(area):
	#if is_queued_for_deletion():
		#return
	#
	#queue_free()
	
func _projectile_detected(area):
	if area.is_queued_for_deletion():
		return
	if area is GuwaProjectile:
		if (force == "player" and area.force == "enemy"):
			print(spawnTime, " > ", area.spawnTime - 0.1)
			if spawnTime > area.spawnTime - 0.1:
				parentDuck.minigamemanager.player_minigame.block_sound.play()
				print(area.attack_damage)
				parentDuck.parry(direction, area.speed, area.attack_damage, area.global_position)
			area.queue_free()
			#print("collide")
			queue_free()
	
func _wall_detected(body):
	if body.name == "PlayerMinigame" or body.name == "StaticBody2D" or is_queued_for_deletion():
		return
	else:
		#print("wall")
		queue_free()
