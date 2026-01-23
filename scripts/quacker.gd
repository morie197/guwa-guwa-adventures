extends Area2D
class_name Quacker

var quack_range: float :
	set(new_range):
		if quack_range != new_range:
			quack_range = new_range
			
var max_health: int :
	set(new_maxhp):
		if max_health != new_maxhp:
			max_health = new_maxhp
			
@export var attack_damage: int 
	
var health: int

var enemy_duck: Array[Quacker]
			
var parent_duck
			
signal quacked
signal hp_changed
signal dead

func _ready():
	body_entered.connect(_duck_detected)
	body_exited.connect(_duck_exited)
	
func initValues():
	health = max_health

func _draw():
	#print("updated")
	var collision_shape = CollisionShape2D.new()
	add_child(collision_shape)
	var circle  = CircleShape2D.new()
	circle.radius = quack_range
	collision_shape.shape = circle
	draw_arc(Vector2.ZERO, quack_range - 8, 0, TAU, 64, Color.RED, 5.0)

func _process(delta):
	pass

func damage(amount: int, damager):
	if parent_duck.name == "PlayerMinigame":
		if parent_duck.lunging and amount > 0:
			if parent_duck.parry(damager) == false:
				return
		if amount > 0:
			parent_duck.hit_sound.play()
	health = clamp(health - amount, 0, max_health)
	hp_changed.emit()
	if health <= 0:
		dead.emit()
	

func quack():
	quacked.emit()
	for enemy in enemy_duck:
		if enemy.has_method("damage"):
			enemy.damage(attack_damage, self)
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
	
	
