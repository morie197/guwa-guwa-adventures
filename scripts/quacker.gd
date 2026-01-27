extends Area2D
class_name Quacker

var max_quack_range: float :
	set(new_range):
		if max_quack_range != new_range:
			max_quack_range = new_range
			
var max_health: int :
	set(new_maxhp):
		if max_health != new_maxhp:
			max_health = new_maxhp
			
var minQuackRange: float = 20
			
@export var attack_damage: int 
	
var health: int

var enemy_duck: Array[Quacker]
			
var parent_duck

var quack_range: float

var quackTime: float = 1.0
var quackTimer: float = 0.0
			
signal quacked
signal hp_changed
signal dead

var circle

func _ready():
	body_entered.connect(_duck_detected)
	body_exited.connect(_duck_exited)
	
	var collision_shape = CollisionShape2D.new()
	add_child(collision_shape)
	circle  = CircleShape2D.new()
	circle.radius = max_quack_range
	collision_shape.shape = circle
	
	quack_range = max_quack_range
	
func initValues():
	health = max_health

func _draw():
	draw_arc(Vector2.ZERO, max_quack_range - 8, 0, TAU, 64, Color(1, 0, 0, 0.3), 5.0)
	if (quack_range < max_quack_range):
		draw_arc(Vector2.ZERO, quack_range - 8, 0, TAU, 64, Color(0, 0.6, 0.6, 0.7), 5.0)

func _process(delta):
	if (quack_range < max_quack_range) or Input.is_action_just_released("quack"):
		#quackTimer -= delta
		quack_range += 100 * delta
		circle.radius = quack_range
		queue_redraw()
	else:
		quacked.emit()
		print("quacked")
		circle.radius = max_quack_range
		
	
	


func damage(amount: int, damager):
	if parent_duck.name == "PlayerMinigame":
		if parent_duck.quacking and amount > 0:
			if parent_duck.parry(damager) == false:
				return
		if amount > 0:
			parent_duck.hit_sound.play()
	health = clamp(health - amount, 0, max_health)
	hp_changed.emit()
	if health <= 0:
		dead.emit()

func quack():
	#quackTimer = quackTime
	quack_range = minQuackRange
	#quacked.emit()
	for enemy in enemy_duck:
		if enemy.parent_duck.has_method("knockback"):
			var knockBackDirection = (global_position - enemy.parent_duck.global_position).normalized() * 50
			enemy.parent_duck.knockback(-knockBackDirection)
	if enemy_duck.size() > 0:
		return false
	
func _duck_detected(body):
	var enemy
	if body.get_collision_layer_value(10):
		enemy = body.get_parent().quacker
	else:
		enemy = body.quacker
	if !enemy_duck.has(enemy):
		enemy_duck.append(enemy)
	
func _duck_exited(body):
	var enemy
	if body.get_collision_layer_value(10):
		enemy = body.get_parent().quacker
	else:
		enemy = body.quacker
	if enemy_duck.has(enemy):
		enemy_duck.erase(enemy)
	
	
