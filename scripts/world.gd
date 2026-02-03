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

@onready var underAreas = $Underground/areas
@onready var overAreas = $Overground/areas


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

var FOWRadius: int = 3

@onready var spawn_pos = $spawnPos

var current_logic_layer

var zoomInAmount: float = 2
var zoomOutAmount: float = 0.5

const HIDDEN = preload("uid://bhx0dlto56i1j")

var zoomMin: float = 1
var ZOOMMAX: float = 0.05

var mouseScrollInput: float = 0.0
var moveVector: Vector2
var mouseMoveVector: Vector2 = Vector2.ZERO

var zoomSpeed: float = 20

var targetCamPosition: Vector2

var mapLayer: int = 1

var cameraMoveSpeed: float = 50
var mouseCameraMoveSpeed: float = 1

var targetZoom: Vector2 = Vector2.ONE

var revealedTilesDict := {}
var revealedTilesUnderDict := {}

var lastMousePos: Vector2 = Vector2.ZERO

var inMap: bool = false
var mapCam: Camera2D

func _unhandled_input(event):
	if Input.is_action_just_pressed("openMap"):
		if GameManager.abilities.has("map"):
			if mapLayer != GameManager.worldLayer:
				print(mapLayer, " ", GameManager.worldLayer)
				openMap(true)
				openMap()
			else:
				openMap()
		
	if inMap and (Input.is_action_just_pressed("nextTutorialItem") or Input.is_action_just_pressed("dive")):
		openMap(true)
		
	if event is InputEventMouseButton:
		if Input.is_action_just_pressed("zoomin"):
			mouseScrollInput = zoomInAmount
		elif Input.is_action_just_pressed("zoomout"):
			mouseScrollInput = zoomOutAmount
	
	if event is InputEventKey:
		moveVector.y = Input.get_axis("up", "down")
		moveVector.x = Input.get_axis("left", "right")
		
	if GameManager.abilities.has("map") and inMap:
		if event is InputEventMouseMotion and Input.is_action_pressed("leftClick"):
			mouseMoveVector -= event.relative * 0.3
		else:
			mouseMoveVector = Vector2.ZERO

func _process(delta):
	if inMap:
		var newTargetCamPosition = moveVector * cameraMoveSpeed * ((zoomMin - mapCam.zoom.x) + 1)
		newTargetCamPosition += mouseMoveVector * 2
		
		targetCamPosition = targetCamPosition.lerp(newTargetCamPosition, 1.0 - exp(delta * -8))
		mapCam.global_position += targetCamPosition

		if mouseScrollInput != 0.0:
			var calculatedZoom: float = clamp(mapCam.zoom.x * mouseScrollInput, ZOOMMAX, zoomMin)
			targetZoom = Vector2(calculatedZoom, calculatedZoom)
			#print(targetZoom)
			mouseScrollInput = 0
		
		if mapCam.zoom != targetZoom:
			mapCam.zoom = mapCam.zoom.lerp(targetZoom, zoomSpeed * delta)
	else:
		targetCamPosition = Vector2.ZERO

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
	
	_getAreasOnly(overAreas, false)
	_getAreasOnly(underAreas, true)
	
	_turnOnOffLayer(undergroundLayer, false)
	darkener.visible = false
	lights.hide()
	_turnOnOffLayer(overgroundLayer, true)
	current_logic_layer = overground_logic_layer
	underground_collision_layer.collision_enabled = false
	GameManager.enterLevel()
	#request_ready()
	
	overMap.modulate = Color.WHITE
	underMap.modulate = Color.TRANSPARENT

func openMap(switching: bool = false):
	#print("opening", inMap)
	if inMap and !switching:
		get_viewport().canvas_cull_mask = 1
		mapCam.enabled = false
		GameManager.paused = false
		inMap = false
		#underMap.modulate = Color.TRANSPARENT
		#overMap.modulate = Color.TRANSPARENT
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
			

	
	#var appendToDict = {}
	#if GameManager.worldLayer == 0:
		#appendToDict = revealedTilesUnderDict
	#elif GameManager.worldLayer == 1:
		#appendToDict = revealedTilesDict
	
	var finalFOWRadius = FOWRadius + GameManager.upgradeLevels["range"]
	var playerCell = getTileUnderPos(GameManager.playerRef.global_position)
	for x in range(-finalFOWRadius, finalFOWRadius + 1):
		for y in range(-finalFOWRadius, finalFOWRadius + 1):
			var cellReveal = Vector2i(playerCell.x + x, playerCell.y + y)
			FOWTileMap.set_cell(cellReveal, -1)
			if GameManager.worldLayer == 0:
				revealedTilesUnderDict[cellReveal] = true
			elif GameManager.worldLayer == 1:
				revealedTilesDict[cellReveal] = true
			
			#appendToDict[cellReveal] = true
			
func loadFOW():
	#var parentMap
	#parentMap = overHidden.get_parent()
	#overHidden.queue_free()
	#overHidden = HIDDEN.instantiate()
	#parentMap.add_child(overHidden)
	
	#parentMap = underHidden.get_parent()
	#underHidden.queue_free()
	#underHidden = HIDDEN.instantiate()
	#parentMap.add_child(underHidden)
	#
	#var finalFOWRadius = FOWRadius + GameManager.upgradeLevels["range"]
	#print(finalFOWRadius)
	#print(GameManager.upgradeLevels["range"])
	#
	#for playerCell in GameManager.traveledTiles:
		#for x in range(-finalFOWRadius, finalFOWRadius + 1):
			#for y in range(-finalFOWRadius, finalFOWRadius + 1):
				#var cellReveal = Vector2i(playerCell.x + x, playerCell.y + y)
				#overHidden.set_cell(cellReveal, -1)
				#
	#for playerCell in GameManager.traveledTilesUnder:
		#for x in range(-finalFOWRadius, finalFOWRadius + 1):
			#for y in range(-finalFOWRadius, finalFOWRadius + 1):
				#var cellReveal = Vector2i(playerCell.x + x, playerCell.y + y)
				#underHidden.set_cell(cellReveal, -1)
	
	revealedTilesDict = {}
	revealedTilesUnderDict = {}
	
	overHidden.set_cells_terrain_connect(GameManager.revealedTiles, 0, -1, false)
	underHidden.set_cells_terrain_connect(GameManager.revealedTilesUnder, 0, -1, false)
	
	for val in GameManager.revealedTiles:
		revealedTilesDict[val] = true
		#print(val)
	
	for val in GameManager.revealedTilesUnder:
		revealedTilesUnderDict[val] = true
		#print(val)
	
	#
	#for playerCell in GameManager.traveledTiles:
		#for x in range(-finalFOWRadius, finalFOWRadius + 1):
			#for y in range(-finalFOWRadius, finalFOWRadius + 1):
				#var cellReveal = Vector2i(playerCell.x + x, playerCell.y + y)
				#revealedTilesDict[cellReveal] = true
	#var overReveals = revealedTilesDict.keys()
	#overHidden.set_cells_terrain_connect(overReveals, 0, -1, false)
				#
	#for playerCell in GameManager.traveledTilesUnder:
		#for x in range(-finalFOWRadius, finalFOWRadius + 1):
			#for y in range(-finalFOWRadius, finalFOWRadius + 1):
				#var cellReveal = Vector2i(playerCell.x + x, playerCell.y + y)
				#revealedTilesUnderDict[cellReveal] = true
	#var underReveals = revealedTilesUnderDict.keys()
	#underHidden.set_cells_terrain_connect(underReveals, 0, -1, false)
			

func clearFOW():
	var parentMap
	parentMap = overHidden.get_parent()
	overHidden.queue_free()
	overHidden = HIDDEN.instantiate()
	parentMap.add_child(overHidden)
	
	parentMap = underHidden.get_parent()
	underHidden.queue_free()
	underHidden = HIDDEN.instantiate()
	parentMap.add_child(underHidden)
	
	#var rect = overHidden.get_used_rect()
	#var tileMaps = [overHidden, underHidden]
	#
	#for tilemap in tileMaps:
		#var empty_cells = []
		#for x in range(rect.position.x, rect.end.x):
			#for y in range(rect.position.y, rect.end.y):
				#var pos = Vector2i(x, y)
				#if tilemap.get_cell_source_id(pos) == -1:
					#empty_cells.append(pos)
		#
		#tilemap.set_cells_terrain_connect(empty_cells, 0, 0)

func switchUnderOverGround():
	if overgroundLayer == null or undergroundLayer == null:
		print("no overground or underground tilemap")
		return
	if GameManager.worldLayer == 1:
		GameManager.worldLayer = 0
		lights.show()
		_turnOnOffLayer(overgroundLayer, false)
		overMap.modulate = Color.TRANSPARENT
		underMap.modulate = Color.WHITE
		overground_collision_layer.collision_enabled = false
		mapLayer = 0
		
		darkener.show()
		_turnOnOffLayer(undergroundLayer, true)
		underground_collision_layer.collision_enabled = true
		current_logic_layer = underground_logic_layer
	else:
		GameManager.worldLayer = 1 
		lights.hide()
		darkener.hide()
		_turnOnOffLayer(undergroundLayer, false)
		overMap.modulate = Color.WHITE
		underMap.modulate = Color.TRANSPARENT
		underground_collision_layer.collision_enabled = false
		mapLayer = 1
		
		_turnOnOffLayer(overgroundLayer, true)
		overground_collision_layer.collision_enabled = true
		current_logic_layer = overground_logic_layer
		
	updateFOW()

func getTileUnderPos(globalPos: Vector2):
	if current_logic_layer == null:
		print("no logic layer present")
		return
		
	if current_logic_layer.z_index == 0: 
		current_logic_layer.z_index = -10
		
	return current_logic_layer.local_to_map(globalPos)

func tileToAtlasCoords(localToMapCoords: Vector2i):
	#print("updating FOW")
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
			
func _getAreasOnly(group, underground: bool = false):
	#var hiddenAreas
	for area in group.get_children():
		if area is HiddenArea:
			area.underground = underground
			if underground:
				area.id = -area.id
	#		hiddenAreas.append(area)
	#return hiddenAreas
