extends Area2D
class_name Quacker

var max_quack_range: float :
	set(new_range):
		if max_quack_range != new_range:
			max_quack_range = new_range
			quack_range = max_quack_range * 2
			
var max_health: int :
	set(new_maxhp):
		if max_health != new_maxhp:
			max_health = new_maxhp
			
var minQuackRange: float = 20

var knockBackMultiplier = 60
			
@export var attack_damage: int 
	
var health: int

#var enemy_duck: Array[Quacker]

const GUWA_PROJECTILE = preload("uid://utkhontokf0j")
const DAMAGE_INDICATOR = preload("uid://cw53hm2wahaxq")

var parent_duck

var quack_range: float

var quackTime: float = 1.0
var quackTimer: float = 0.0
			
signal quacked
signal hp_changed
signal dead

var circle

func _ready():
	
	#body_entered.connect(_duck_detected)
	#body_exited.connect(_duck_exited)
	pass
	
	
	
func initValues():
	health = max_health

func _draw():
	#var collision_shape = CollisionShape2D.new()
	#add_child(collision_shape)
	#circle  = CircleShape2D.new()
	#circle.radius = max_quack_range
	#collision_shape.shape = circle
	
	if parent_duck.name == "PlayerMinigame":
		draw_arc(Vector2.ZERO, quack_range - 8, 0, TAU, 64, Color(0, 1, 1, 0.1), 5.0)
	else:
		draw_arc(Vector2.ZERO, quack_range - 8, 0, TAU, 64, Color(1, 0, 0, 0.1), 5.0)
	#if (quack_range < max_quack_range):
	#	draw_arc(Vector2.ZERO, quack_range - 8, 0, TAU, 64, Color(0, 0.6, 0.6, 0.7), 5.0)

func _process(delta):
	pass
	#if (quack_range < max_quack_range) or Input.is_action_just_released("quack"):
	#	#quackTimer -= delta
	#	quack_range += 100 * delta
	#	circle.radius = quack_range
	#	queue_redraw()
	#else:
	#	quacked.emit()
	#	print("quacked")
	#	circle.radius = max_quack_range
		
	
	


func damage(amount: int, damager):
	if damager == null:
		return
	
	var knockBackDirection
	if parent_duck.name == "PlayerMinigame":
		#if parent_duck.lunging and amount > 0:
			#if parent_duck.parry(damager) == false:
				#return
		if amount > 0:
			parent_duck.hit_sound.play()
	health = clamp(health - amount, 0, max_health)
	hp_changed.emit()
	if amount > 0:
		var multiplier: float = 1.0
		var distance = global_position.distance_to(damager.global_position) + 1
		if distance < 150:
			multiplier = 1 + 10/distance
		knockBackDirection = (global_position - damager.global_position).normalized() * knockBackMultiplier * multiplier
		parent_duck.knockback(knockBackDirection)
	
	if health != clamp(health - amount, -30, max_health):
		var damaged = DAMAGE_INDICATOR.instantiate()
		if amount < 0:
			damaged.healing = true
		add_child(damaged)
		if amount > 0:
			damaged.damageText.text = "-" + str(amount)
		elif amount < 0:
			damaged.damageText.text = "+" + str(abs(amount))
			
		damaged.global_position = global_position + Vector2(-16, -32)
	
	if health <= 0:
		dead.emit()

func quack(direction: Vector2 = Vector2.RIGHT, speed: float = 5.0, reflect: bool = false, damageOverride: int = 1, positionOverride: Vector2 = Vector2.ZERO):
	var projectile = GUWA_PROJECTILE.instantiate()
	projectile.direction = direction
	projectile.speed = speed
	projectile.parentDuck = parent_duck
	projectile.originPosition = global_position
	projectile.attackRange = quack_range
	if parent_duck.name == "PlayerMinigame":
		projectile.force = "player"
		if reflect == true:
			projectile.attack_damage = damageOverride
			projectile.originPosition = positionOverride
			projectile.reflected = true
	else:
		projectile.force = "enemy"
		projectile.attack_damage = attack_damage
	parent_duck.minigamemanager.call_deferred("add_child", projectile)
	
	
	quacked.emit()
	#for enemy in enemy_duck:
		#if enemy.has_method("damage"):
			#enemy.damage(attack_damage, self)
	#if enemy_duck.size() > 0:
		#return false
	#
#func _duck_detected(body):
	#var enemy
	#if body.get_collision_layer_value(10):
		#enemy = body.get_parent().quacker
	#else:
		#enemy = body.quacker
		#
	#if !enemy_duck.has(enemy):
		#enemy_duck.append(enemy)
	#
#func _duck_exited(body):
	#var enemy
	#if body.get_collision_layer_value(10):
		#enemy = body.get_parent().quacker
	#else:
		#enemy = body.quacker
	#if enemy_duck.has(enemy):
		#enemy_duck.erase(enemy)
	
	
