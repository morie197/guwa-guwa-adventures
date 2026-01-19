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

var enemy_duck: Quacker :
	set(new_enemy):
		if enemy_duck != new_enemy:
			enemy_duck = new_enemy
			
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
	draw_arc(Vector2.ZERO, quack_range, 0, TAU, 64, Color.RED, 5.0)

func _process(delta):
	pass

func damage(amount: int):
	hp_changed.emit()
	if health <= 0:
		dead.emit()
		#print("dead!")
		return
	if health > 0:
		health -= amount
		#print(health)

func quack():
	quacked.emit()
	#print(enemy_duck)
	
func _duck_detected(body):
	enemy_duck = body.quacker
	#print("entered: ", body.name)
	quacked.connect(enemy_duck.damage.bind(attack_damage))  
	
func _duck_exited(body):
	quacked.disconnect(enemy_duck.damage)
	enemy_duck = null
	
