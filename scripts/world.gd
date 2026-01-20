extends Node2D

@onready var player = $Player
@onready var undergroundLayer = $Underground
@onready var overgroundLayer = $Overground
@onready var underground_logic_layer = $Underground/LogicLayer
@onready var overground_logic_layer = $Overground/LogicLayer
@onready var underground_collision_layer = $Underground/CollisionLayer
@onready var overground_collision_layer = $Overground/CollisionLayer

@onready var ui_manager = $UIManager

@onready var darkener = $Underground/darkener

var current_logic_layer

func _ready():
	GameManager.playerRef = player
	GameManager.worldManager = self
	
	undergroundLayer.visible = false
	overgroundLayer.visible = true
	current_logic_layer = overground_logic_layer
	underground_collision_layer.collision_enabled = false
	GameManager.enterLevel()

func switchUnderOverGround():
	if overgroundLayer == null or undergroundLayer == null:
		print("no overground or underground tilemap")
		return
	if GameManager.worldLayer == 1:
		GameManager.worldLayer = 0
		overgroundLayer.visible = false
		overground_collision_layer.collision_enabled = false
		
		undergroundLayer.visible = true
		underground_collision_layer.collision_enabled = true
		current_logic_layer = underground_logic_layer
	else:
		GameManager.worldLayer = 1 
		undergroundLayer.visible = false
		underground_collision_layer.collision_enabled = false
		
		overgroundLayer.visible = true
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
