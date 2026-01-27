extends Node2D

@onready var player = $Player
@onready var undergroundLayer = $Underground
@onready var overgroundLayer = $Overground
@onready var underground_logic_layer = $Underground/LogicLayer
@onready var overground_logic_layer = $Overground/LogicLayer
@onready var underground_collision_layer = $Underground/CollisionLayer
@onready var overground_collision_layer = $Overground/CollisionLayer
@onready var undergroundTreats = $Underground/treats
@onready var undergroundDucks = $Underground/ducks

@onready var ui_manager = $UIManager

@onready var quackNodes = $Overground/cameraNodes/quackNodes
@onready var land_nodes = $Overground/cameraNodes/landNodes
@onready var dive_nodes = $Overground/cameraNodes/diveNodes
@onready var fly_nodes = $Overground/cameraNodes/flyNodes

@onready var darkener = $Underground/darkener

@export var levelName: String = ""

@onready var spawn_pos = $spawnPos

var current_logic_layer

func _ready():
	for treat in undergroundTreats.get_children():
		treat.underground = true
		treat.id = -treat.id
		treat.point_light_2d.energy = treat.undergroundEnergy
		treat.point_light_2d.enabled = false
		
	_getDucksRecursively(undergroundDucks)
	GameManager.playerRef = player
	GameManager.worldManager = self
	
	_turnOnOffLayer(undergroundLayer, false)
	darkener.visible = false
	_turnOnOffLayer(overgroundLayer, true)
	current_logic_layer = overground_logic_layer
	underground_collision_layer.collision_enabled = false
	GameManager.enterLevel()
	#request_ready()

func switchUnderOverGround():
	if overgroundLayer == null or undergroundLayer == null:
		print("no overground or underground tilemap")
		return
	if GameManager.worldLayer == 1:
		GameManager.worldLayer = 0
		_turnOnOffLayer(overgroundLayer, false)
		overground_collision_layer.collision_enabled = false
		
		darkener.show()
		_turnOnOffLayer(undergroundLayer, true)
		underground_collision_layer.collision_enabled = true
		current_logic_layer = underground_logic_layer
	else:
		GameManager.worldLayer = 1 
		darkener.hide()
		_turnOnOffLayer(undergroundLayer, false)
		underground_collision_layer.collision_enabled = false
		
		_turnOnOffLayer(overgroundLayer, true)
		overground_collision_layer.collision_enabled = true
		current_logic_layer = overground_logic_layer

func getTileUnderPos(globalPos: Vector2):
	if current_logic_layer == null:
		print("no logic layer present")
		return
		
	if current_logic_layer.z_index == 0: 
		current_logic_layer.z_index = -10
		
	return current_logic_layer.local_to_map(globalPos)

func tileToAtlasCoords(localToMapCoords: Vector2i):
	if current_logic_layer == null:
		print("no logic layer present")
		return
	
	return current_logic_layer.get_cell_atlas_coords(localToMapCoords)
	
func _turnOnOffLayer(target, isVisible: bool):
	GameManager.treatsUpdated.emit()
	if isVisible:
		target.modulate = Color.WHITE
		target.process_mode = PROCESS_MODE_ALWAYS
	else:
		target.modulate = Color.TRANSPARENT
		target.process_mode = PROCESS_MODE_DISABLED
		
func _getDucksRecursively(group):
	for duck in group.get_children():
		if duck is StaticDuck:
			duck.underground = true
			duck.id = -duck.id
			duck.collider.set_collision_layer_value(1, true)
			duck.quack_detector.set_collision_mask_value(6, true)
		elif duck.get_child_count() > 0:
			_getDucksRecursively(duck)
