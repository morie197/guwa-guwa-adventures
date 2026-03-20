extends Node2D
class_name WorldManager

@onready var player = $Player
@onready var undergroundLayer = $Underground
@onready var overgroundLayer = $Overground
@onready var underground_logic_layer = $Underground/LogicLayer
@onready var overground_logic_layer = $Overground/LogicLayer
@onready var underground_collision_layer = $Underground/CollisionLayer
@onready var overground_collision_layer = $Overground/CollisionLayer
@onready var undergroundTreats = $Underground/treats
@onready var undergroundDucks = $Underground/ducks

@onready var overgroundTreats = $Overground/treats
@onready var overgroundDucks = $Overground/ducks


@onready var underMap = $MapLayers/Under
@onready var overMap = $MapLayers/Over

@onready var underAreas = $Underground/areas
@onready var overAreas = $Overground/areas

@onready var underwater_land_layer = $Underground/LandLayer
#@onready var borders = $Underground/LandLayer/borders
@onready var water = $Underground/LandLayer/water
@onready var water_layer_border = $Underground/WaterLayer3


@onready var lights = $Underground/lights

@onready var underHidden = $MapLayers/Under/visible/hidden
@onready var overHidden = $MapLayers/Over/visible/hidden

var remainingOvergroundTreats
var remainingUndergroundTreats

@onready var ui_manager = $UIManager

@onready var quackNodes = $Overground/cameraNodes/quackNodes
@onready var land_nodes = $Overground/cameraNodes/landNodes
@onready var dive_nodes = $Overground/cameraNodes/diveNodes
@onready var fly_nodes = $Overground/cameraNodes/flyNodes

@onready var darkener = $Underground/darkener

@export var levelName: String = ""

var FOWRadius: int = 6

@onready var spawn_pos = $spawnPos

var current_logic_layer

var zoomInAmount: float = 2
var zoomOutAmount: float = 0.5

const HIDDEN = preload("uid://bhx0dlto56i1j")
const LEVEL_3_MUSIC = preload("uid://c64fa5fkyx48n")
const LEVEL_0_MUSIC = preload("uid://b8kxk1dhvy5xl")

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

var overFow: BitMap
var underFow: BitMap

var lastMousePos: Vector2 = Vector2.ZERO

var updateTilesInFrameOver: Array[Vector2i]
var updateTilesInFrameUnder: Array[Vector2i]

var inMap: bool = false
var mapCam: Camera2D

var toUpdateTilesOver: Dictionary
var toUpdateTilesUnder: Dictionary

var maxUpdatesPerFrame: int = 60

var updates: int = 0

var sinceLastUpdate: float = 0.0

var underOrigin: Vector2i
var overOrigin: Vector2i

var underMat: ShaderMaterial
var overMat: ShaderMaterial

var underMapSize: Vector2 = Vector2.ZERO
var overMapSize: Vector2 = Vector2.ZERO

var underTexture: ImageTexture
var overTexture: ImageTexture


func _unhandled_input(event):
	
	if Input.is_action_just_pressed("openMap"):
		if GameManager.abilities.has("map"):
			if mapLayer != GameManager.worldLayer:
			#	print(mapLayer, " ", GameManager.worldLayer)
				openMap(true)
				openMap()
			else:
				openMap()
		
	if inMap and (Input.is_action_just_pressed("nextTutorialItem") or Input.is_action_just_pressed("dive")):
		if underFow.get_true_bit_count() > 0:
			openMap(true)
		
	#if event is InputEventMouseButton:
	if Input.is_action_just_pressed("zoomin"):
		mouseScrollInput = zoomInAmount
	elif Input.is_action_just_pressed("zoomout"):
		mouseScrollInput = zoomOutAmount
	
	if event is InputEventKey:
		moveVector.y = Input.get_axis("up", "down")
		moveVector.x = Input.get_axis("left", "right")
		
	if GameManager.abilities.has("map") and inMap:
		if event is InputEventMouseMotion and Input.is_action_pressed("leftClick"):
			mouseMoveVector = event.relative
		else:
			mouseMoveVector = Vector2.ZERO

func _process(delta):
	if sinceLastUpdate < 30.0:
		sinceLastUpdate += delta
		
	#print(get_viewport().canvas_cull_mask)
		
	#
	#updates = 0
	#updateTilesInFrameUnder = []
	#updateTilesInFrameOver = []
	#
	#
	#for tile in toUpdateTilesUnder.duplicate():
		#if updates >= maxUpdatesPerFrame:
			##print(updates, " >= ", maxUpdatesPerFrame)
			#break
		#updateTilesInFrameUnder.append(tile)
		##underHidden.set_cell(tile, -1)
		#toUpdateTilesUnder.erase(tile)
		#updates += 1
	#updates = 0
	#for tile in toUpdateTilesOver.duplicate():
		#if updates >= maxUpdatesPerFrame:
			##print(updates, " >= ", maxUpdatesPerFrame)
			#break
		#updateTilesInFrameOver.append(tile)
		##overHidden.set_cell(tile, -1)
		#toUpdateTilesOver.erase(tile)
		#updates += 1
	
	#underHidden.set_cells_terrain_connect(updateTilesInFrameUnder, 0, -1, false)
	#overHidden.set_cells_terrain_connect(updateTilesInFrameOver, 0, -1, false)
		
		
	#print(updates)
	
	if inMap:
		#var newTargetCamPosition = moveVector * cameraMoveSpeed * ((zoomMin - mapCam.zoom.x) + 1)
		var newTargetCamPosition = (moveVector * cameraMoveSpeed) / (mapCam.zoom * 3)
		newTargetCamPosition -= (mouseMoveVector * 10) / (mapCam.zoom * 5)
		#newTargetCamPosition -= (mouseMoveVector) * ((zoomMin - mapCam.zoom.x) + 1)
		
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
	
	underFow = BitMap.new()
	var underRect: Rect2i = underground_logic_layer.get_used_rect()
	underMapSize = underRect.size * 64
	underFow.create(underRect.size)
	
	underOrigin = underRect.position
	
	
	underHidden.size = underMapSize
	underHidden.position = underOrigin * 64
	
	underMat = underHidden.material as ShaderMaterial
	underMat.set_shader_parameter("map_size", underMapSize)
	underMat.set_shader_parameter("map_offset", underOrigin * 64)
	
	underTexture = ImageTexture.new()
	
	overFow = BitMap.new()
	var overRect: Rect2i = overground_logic_layer.get_used_rect()
	overMapSize = overRect.size * 64
	overFow.create(overRect.size)
	
	overOrigin = overRect.position
	
	
	overHidden.size = overMapSize
	overHidden.position = overOrigin * 64
	
	overMat = overHidden.material as ShaderMaterial
	overMat.set_shader_parameter("map_size", overMapSize)
	overMat.set_shader_parameter("map_offset", overOrigin * 64)
	
	overTexture = ImageTexture.new()
	
	underTexture.set_image(underFow.convert_to_image())
	underMat.set_shader_parameter("fow_mask", underTexture)
	overTexture.set_image(overFow.convert_to_image())
	overMat.set_shader_parameter("fow_mask", overTexture)
	
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
	
	undergroundLayer.visible = true
	overgroundLayer.visible = true
	
	_turnOnOffLayer(undergroundLayer, false)
	if levelName == "Hidden Grove":
		darkener.visible = true
	else:
		darkener.visible = false
	lights.hide()
	_turnOnOffLayer(overgroundLayer, true)
	current_logic_layer = overground_logic_layer
	underground_collision_layer.collision_enabled = false
	GameManager.enterLevel()
	
	if underFow.get_size() != underRect.size:
		underFow.create(underRect.size)
	if overFow.get_size() != overRect.size:
		overFow.create(overRect.size)
	
	#request_ready()
	
	overMap.modulate = Color.WHITE
	underMap.modulate = Color.TRANSPARENT
	
	if levelName == "Hidden Grove":
		GameManager.playerRef.bgmVolume = 10
		GameManager.playerRef.bgm.stream = LEVEL_3_MUSIC
	elif levelName == "Rocky Forest":
		GameManager.playerRef.bgm.volume_db += 5
		GameManager.playerRef.bgm.stream = LEVEL_0_MUSIC
	GameManager.playerRef.bgm.play()
	GameManager.playerRef.bgmVolume = GameManager.playerRef.bgm.volume_db
	GameManager.playerRef.bgm.autoplay = true
	
	switchBreathableArea(GameManager.playerRef.isBreathable)

func switchBreathableArea(breathable: bool = false):
	print("called, ", breathable)
	if breathable:
		undergroundTreats.visible = true
		#undergroundDucks.visible = true
		undergroundTreats.process_mode = Node.PROCESS_MODE_ALWAYS
			
		GameManager.changeBreathableLayer.emit(breathable)
			
		water_layer_border.modulate = Color.TRANSPARENT
		underwater_land_layer.self_modulate = Color.WHITE
		
		for child in underwater_land_layer.get_children():
			child.modulate = Color.WHITE
	else:
		undergroundTreats.visible = false
		#undergroundDucks.visible = false
		undergroundTreats.process_mode = Node.PROCESS_MODE_DISABLED
			
		GameManager.changeBreathableLayer.emit(breathable)
			
		water_layer_border.modulate = Color.WHITE
		underwater_land_layer.self_modulate = Color.TRANSPARENT
		
		for child in underwater_land_layer.get_children():
			child.modulate = Color.TRANSPARENT
		water.modulate = Color(1,1,1,0.4)

func openMap(switching: bool = false):
	#print("opening", inMap)
	if inMap and !switching:
		get_viewport().canvas_cull_mask = 1
		mapCam.enabled = false
		GameManager.paused = false
		inMap = false
		#GameManager.playerRef.healTimer.paused = false
		if GameManager.worldLayer == 1:
			if levelName == "Hidden Grove":
				darkener.show()
			else:
				darkener.hide()
			undergroundLayer.modulate = Color.TRANSPARENT
			overgroundLayer.modulate = Color.WHITE
			
			
		else:
			#darkener.hide()
			darkener.show()
			overgroundLayer.modulate = Color.TRANSPARENT
			undergroundLayer.modulate = Color.WHITE
		#underMap.modulate = Color.TRANSPARENT
		#overMap.modulate = Color.TRANSPARENT
		return
	
	if inMap == false:
		if GameManager.paused:
			return
		if ui_manager != null:
			if underFow.get_true_bit_count() > 0:
				ui_manager.switch.show()
			else:
				ui_manager.switch.hide()
		#GameManager.playerRef.healTimer.paused = true
		darkener.hide()
		#overAreas.hide()
		#overAreas.process_mode = Node.PROCESS_MODE_DISABLED
		#underAreas.hide()
		#underAreas.process_mode = Node.PROCESS_MODE_DISABLED
		#
		#overgroundTreats.hide()
		#overgroundTreats.process_mode = Node.PROCESS_MODE_DISABLED
		#undergroundTreats.hide()
		#undergroundTreats.process_mode = Node.PROCESS_MODE_DISABLED
		
		mapLayer = GameManager.worldLayer
		get_viewport().canvas_cull_mask = 2
		mapCam.global_position = GameManager.playerRef.global_position
		#mapCam.zoom = GameManager.minimapCam.zoom * 2
		#targetZoom = GameManager.minimapCam.zoom * 2
	inMap = true
	mapCam.enabled = true
	mapCam.make_current()
	GameManager.paused = true
	
	if switching:
		mapLayer = abs(mapLayer - 1)
		GameManager.changedMapLevel.emit(mapLayer == GameManager.worldLayer)
	
	if mapLayer == 0:
		underMap.modulate = Color.WHITE
		overMap.modulate = Color.TRANSPARENT
		overgroundLayer.modulate = Color.TRANSPARENT
		undergroundLayer.modulate = Color.WHITE
	else:
		overMap.modulate = Color.WHITE
		underMap.modulate = Color.TRANSPARENT
		overgroundLayer.modulate = Color.WHITE
		undergroundLayer.modulate = Color.TRANSPARENT

func updateMinimap():
	if mapLayer == 0:
		underMap.modulate = Color.WHITE
		overMap.modulate = Color.TRANSPARENT
	else:
		overMap.modulate = Color.WHITE
		underMap.modulate = Color.TRANSPARENT

func updateFOW(usual: bool = false):
	#if usual and sinceLastUpdate < (FOWRadius + (GameManager.upgradeLevels["range"]/2.0))/20.0:
		##print("returning")
		#return
	if usual and sinceLastUpdate < 0.3:
		#print("returning")
		return
	else:
		sinceLastUpdate = 0
	#var FOWTileMap: TileMapLayer
	
	#print("updating")
	var dict
	if GameManager.worldLayer == 0:
		dict = toUpdateTilesUnder
		#FOWTileMap = underHidden
	elif GameManager.worldLayer == 1:
		dict = toUpdateTilesOver
		#FOWTileMap = overHidden
	else:
		#print("no tile map ;(")
		return
		
	var finalFOWRadius
	if levelName == "Hidden Grove":
		finalFOWRadius = FOWRadius/2 + (GameManager.postgameUpgradeLevels["reach"] * GameManager.treatRegistry.size()/10.0)
	else:
		finalFOWRadius = FOWRadius + (GameManager.upgradeLevels["range"])
	var playerCell = getTileUnderPos(GameManager.playerRef.global_position)
	for x in range(-finalFOWRadius, finalFOWRadius + 1):
		for y in range(-finalFOWRadius, finalFOWRadius + 1):
			var cellReveal = Vector2i(playerCell.x + x, playerCell.y + y)
			#dict[cellReveal] = true
			#FOWTileMap.set_cell(cellReveal, -1)
		
			if GameManager.worldLayer == 0:
				revealedTilesUnderDict[cellReveal] = true
				var til = cellReveal - underOrigin
				if !(til.x < 0 or til.y < 0 or til.y >= underFow.get_size().y or til.x >= underFow.get_size().x):
					underFow.set_bitv(cellReveal - underOrigin, true)
			elif GameManager.worldLayer == 1:
				revealedTilesDict[cellReveal] = true
				var til = cellReveal - overOrigin
				if !(til.x < 0 or til.y < 0 or til.y >= overFow.get_size().y or til.x >= overFow.get_size().x):
					overFow.set_bitv(cellReveal - overOrigin, true)

			
	if GameManager.worldLayer == 0:	
		#var img = underFow.convert_to_image()
		underTexture.set_image(underFow.convert_to_image())
		#underTexture = ImageTexture.create_from_image(img)
		#underTexture.update(img)
		underMat.set_shader_parameter("fow_mask", underTexture)
	elif GameManager.worldLayer == 1:
		#var img = underFow.convert_to_image()
		overTexture.set_image(overFow.convert_to_image())
		#overTexture = ImageTexture.create_from_image(img)
		#overTexture.update(img)
		#overTexture.set_image(overFow.convert_to_image())
		overMat.set_shader_parameter("fow_mask", overTexture)
		
	#print(underMat, overMat)
			
func loadFOW():	
	#revealedTilesDict = {}
	#revealedTilesUnderDict = {}
	
	#print("loaded FOW")
	
	#print(underFow)
	#print(overFow)
	
	underTexture.set_image(underFow.convert_to_image())
	underMat.set_shader_parameter("fow_mask", underTexture)
	overTexture.set_image(overFow.convert_to_image())
	overMat.set_shader_parameter("fow_mask", overTexture)
	
	#for tile in GameManager.revealedTilesUnder:
		#toUpdateTilesUnder[tile] = true
	#for tile in GameManager.revealedTiles:
		#toUpdateTilesOver[tile] = true
	
	#overHidden.set_cells_terrain_connect(GameManager.revealedTiles, 0, -1, false)
	#underHidden.set_cells_terrain_connect(GameManager.revealedTilesUnder, 0, -1, false)
	
	for val in GameManager.revealedTiles:
		revealedTilesDict[val] = true
	
	for val in GameManager.revealedTilesUnder:
		revealedTilesUnderDict[val] = true
			

func clearFOW():
	#print("cleared FOW")
	
	underFow = BitMap.new()
	var underRect: Rect2i = underground_logic_layer.get_used_rect()
	underFow.create(underRect.size)
	
	overFow = BitMap.new()
	var overRect: Rect2i = overground_logic_layer.get_used_rect()
	overFow.create(overRect.size)
	
	#var parentMap
	#parentMap = overHidden.get_parent()
	#overHidden.queue_free()
	#overHidden = HIDDEN.instantiate()
	#parentMap.add_child(overHidden)
	
	#parentMap = underHidden.get_parent()
	#underHidden.queue_free()
	#underHidden = HIDDEN.instantiate()
	#parentMap.add_child(underHidden)

func switchUnderOverGround():
	if overgroundLayer == null or undergroundLayer == null:
		#print("no overground or underground tilemap")
		return
		
	GameManager.switchedWorldLevel.emit()
		
	if GameManager.worldLayer == 1:
		GameManager.worldLayer = 0
		lights.show()
		_turnOnOffLayer(overgroundLayer, false)
		overMap.modulate = Color.TRANSPARENT
		underMap.modulate = Color.WHITE
		#print(overMap.modulate)
		overground_collision_layer.collision_enabled = false
		mapLayer = 0
		
		darkener.show()
		_turnOnOffLayer(undergroundLayer, true)
		underground_collision_layer.collision_enabled = true
		current_logic_layer = underground_logic_layer
	else:
		GameManager.worldLayer = 1 
		lights.hide()
		if levelName == "Hidden Grove":
			darkener.show()
		else:
			#print(levelName)
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
		#print("no logic layer present")
		return
		
	if current_logic_layer.z_index == 0: 
		current_logic_layer.z_index = -10
		
	return current_logic_layer.local_to_map(globalPos)

func tileToAtlasCoords(localToMapCoords: Vector2i):
	#print("updating FOW")
	if current_logic_layer == null:
		#print("no logic layer present")
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
	
func getClosestTreat() -> Node2D:
	remainingUndergroundTreats = _getTreats(undergroundTreats)
	remainingOvergroundTreats = _getTreats(overgroundTreats)
	
	var closestTreat  = null
	var closestDistance: float = 9999999999999
	var closestDistanceHidden: float = 9999999999999
	var closestHiddenTreat = null
	
	if GameManager.worldLayer == 1:
		for treat in remainingOvergroundTreats:
			if !treat.hiddenOnRadar:
				if treat.global_position.distance_to(GameManager.playerRef.global_position) < closestDistance:
					closestTreat = treat
					closestDistance = treat.global_position.distance_to(GameManager.playerRef.global_position)
			if treat.hiddenOnRadar:
				if treat.global_position.distance_to(GameManager.playerRef.global_position) < closestDistanceHidden:
					closestHiddenTreat = treat
					closestDistanceHidden = treat.global_position.distance_to(GameManager.playerRef.global_position)
	elif GameManager.worldLayer == 0:
		for treat in remainingUndergroundTreats:
			if !treat.hiddenOnRadar:
				if treat.global_position.distance_to(GameManager.playerRef.global_position) < closestDistance:
					closestTreat = treat
					closestDistance = treat.global_position.distance_to(GameManager.playerRef.global_position)
			if treat.hiddenOnRadar:
				if treat.global_position.distance_to(GameManager.playerRef.global_position) < closestDistanceHidden:
					closestHiddenTreat = treat
					closestDistanceHidden = treat.global_position.distance_to(GameManager.playerRef.global_position)
					
	#print(closestTreat)
	#print(closestHiddenTreat)
	
	if closestTreat != null:
		if GameManager.playerRef.distanceToTreatFormula(closestTreat.global_position):
			return closestTreat
	if closestHiddenTreat != null:
		if GameManager.playerRef.distanceToTreatFormula(closestHiddenTreat.global_position):
			closestHiddenTreat.hiddenOnRadar = false
			return closestHiddenTreat
	#print("null")
	return null
		
func _getTreats(group) -> Array[Node2D]:
	var treats: Array[Node2D] = []
	for treat in group.get_children():
		if treat is DuckTreat:
			if GameManager.treatRegistry.has(treat.id):
				continue  
			treats.append(treat)
		elif treat.get_child_count() > 0:
			var recursiveTreats = _getTreats(treat)
			for rTreat in recursiveTreats:
				treats.append(rTreat)
	
	#print(treats)
	return treats
		
		
func _getAreasOnly(group, underground: bool = false):
	#var hiddenAreas
	for area in group.get_children():
		if area is HiddenArea:
			area.underground = underground
			if underground:
				area.id = -area.id
	#		hiddenAreas.append(area)
	#return hiddenAreas
