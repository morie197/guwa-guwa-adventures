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

@onready var underMap = $MapLayers/Under
@onready var overMap = $MapLayers/Over

@onready var lights = $Underground/lights

@onready var underHidden = $MapLayers/Under/visible/hidden
@onready var overHidden = $MapLayers/Over/visible/hidden


@onready var ui_manager = $UIManager

@onready var quackNodes = $Overground/cameraNodes/quackNodes
@onready var land_nodes = $Overground/cameraNodes/landNodes
@onready var dive_nodes = $Overground/cameraNodes/diveNodes
@onready var fly_nodes = $Overground/cameraNodes/flyNodes

@onready var darkener = $Underground/darkener

@export var levelName: String = ""

var FOWRadius: int = 2

@onready var spawn_pos = $spawnPos

var current_logic_layer

var zoomInAmount: float = 2
var zoomOutAmount: float = 0.5

const HIDDEN = preload("uid://bhx0dlto56i1j")

var zoomMin: float = 1
var ZOOMMAX: float = 0.05

var mouseScrollInput: float = 0.0
var moveVector: Vector2

var zoomSpeed: float = 20

var mapLayer: int = 1

var cameraMoveSpeed: float = 50

var targetZoom: Vector2 = Vector2.ONE

var inMap: bool = false
var mapCam: Camera2D

func _unhandled_input(event):
	if Input.is_action_just_pressed("openMap"):
		if GameManager.abilities.has("map"):
			openMap()
		
	if inMap and Input.is_action_just_pressed("nextTutorialItem"):
		openMap(true)
		
	if event is InputEventMouseButton:
		if Input.is_action_just_pressed("zoomin"):
			mouseScrollInput = zoomInAmount
		elif Input.is_action_just_pressed("zoomout"):
			mouseScrollInput = zoomOutAmount
	
	if event is InputEventKey:
		moveVector.y = Input.get_axis("up", "down")
		moveVector.x = Input.get_axis("left", "right")

func _process(delta):
	if inMap:
		mapCam.global_position += moveVector * cameraMoveSpeed * ((zoomMin - mapCam.zoom.x) + 1)

		if mouseScrollInput != 0.0:
			var calculatedZoom: float = clamp(mapCam.zoom.x * mouseScrollInput, ZOOMMAX, zoomMin)
			targetZoom = Vector2(calculatedZoom, calculatedZoom)
			print(targetZoom)
			mouseScrollInput = 0
		
		if mapCam.zoom != targetZoom:
			mapCam.zoom = mapCam.zoom.lerp(targetZoom, zoomSpeed * delta)

func _ready():
	get_viewport().canvas_cull_mask = 1
	mapCam = Camera2D.new()
	mapCam.set_visibility_layer_bit(1, false)
	mapCam.set_visibility_layer_bit(2, true)
	mapCam.enabled = false
	add_child(mapCam)
	
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
	lights.hide()
	_turnOnOffLayer(overgroundLayer, true)
	current_logic_layer = overground_logic_layer
	underground_collision_layer.collision_enabled = false
	GameManager.enterLevel()
	#request_ready()

func openMap(switching: bool = false):
	#print("opening", inMap)
	if inMap and !switching:
		get_viewport().canvas_cull_mask = 1
		mapCam.enabled = false
		GameManager.paused = false
		inMap = false
		underMap.modulate = Color.TRANSPARENT
		overMap.modulate = Color.TRANSPARENT
		return
	
	if inMap == false:
		mapLayer = GameManager.worldLayer
		get_viewport().canvas_cull_mask = 2
		mapCam.global_position = GameManager.playerRef.global_position
	inMap = true
	mapCam.enabled = true
	mapCam.make_current()
	GameManager.paused = true
	
	if switching:
		mapLayer = abs(mapLayer - 1)
	
	if mapLayer == 0:
		underMap.modulate = Color.WHITE
		overMap.modulate = Color.TRANSPARENT
	else:
		overMap.modulate = Color.WHITE
		underMap.modulate = Color.TRANSPARENT

func updateFOW():
	var FOWTileMap: TileMapLayer
	if GameManager.worldLayer == 0:
		FOWTileMap = underHidden
	elif GameManager.worldLayer == 1:
		FOWTileMap = overHidden
	else:
		print("no tile map ;(")
		return
		
	var playerCell = getTileUnderPos(GameManager.playerRef.global_position)
	if GameManager.worldLayer == 0:
		if !GameManager.traveledTilesUnder.has(playerCell):
			GameManager.traveledTilesUnder.append(playerCell)
	elif GameManager.worldLayer == 1:
		if !GameManager.traveledTiles.has(playerCell):
			GameManager.traveledTiles.append(playerCell)
	
	var finalFOWRadius = FOWRadius + GameManager.upgradeLevels["range"]
	
	for x in range(-finalFOWRadius, finalFOWRadius + 1):
		for y in range(-finalFOWRadius, finalFOWRadius + 1):
			var cellReveal = Vector2i(playerCell.x + x, playerCell.y + y)
			FOWTileMap.set_cell(cellReveal, -1)
			
func loadFOW():
	var parentMap
	parentMap = overHidden.get_parent()
	overHidden.queue_free()
	overHidden = HIDDEN.instantiate()
	parentMap.add_child(overHidden)
	
	parentMap = underHidden.get_parent()
	underHidden.queue_free()
	underHidden = HIDDEN.instantiate()
	parentMap.add_child(underHidden)
	
	
	for playerCell in GameManager.traveledTiles:
		for x in range(-FOWRadius, FOWRadius + 1):
			for y in range(-FOWRadius, FOWRadius + 1):
				var cellReveal = Vector2i(playerCell.x + x, playerCell.y + y)
				overHidden.set_cell(cellReveal, -1)
				
	for playerCell in GameManager.traveledTilesUnder:
		
		for x in range(-FOWRadius, FOWRadius + 1):
			for y in range(-FOWRadius, FOWRadius + 1):
				var cellReveal = Vector2i(playerCell.x + x, playerCell.y + y)
				underHidden.set_cell(cellReveal, -1)

func switchUnderOverGround():
	if overgroundLayer == null or undergroundLayer == null:
		print("no overground or underground tilemap")
		return
	updateFOW()
	if GameManager.worldLayer == 1:
		GameManager.worldLayer = 0
		lights.show()
		_turnOnOffLayer(overgroundLayer, false)
		overground_collision_layer.collision_enabled = false
		
		darkener.show()
		_turnOnOffLayer(undergroundLayer, true)
		underground_collision_layer.collision_enabled = true
		current_logic_layer = underground_logic_layer
	else:
		GameManager.worldLayer = 1 
		lights.hide()
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
	print("updating FOW")
	updateFOW()
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
