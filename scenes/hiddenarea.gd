extends Area2D
class_name HiddenArea

@onready var mask = $Mask
@onready var map_mask = $MapMask
@onready var ping = $ping

var showColor: Color = Color.TRANSPARENT
var mapMaskShowColor: Color = Color(0.072, 0.165, 0.4, 0.282)

var mapMaskRef

var targetModulateColor: Color = Color.WHITE
var pingHintColor: Color = Color(1, 0.85, 0.85, 0.90)

@export var modulateSpeed: float = 0.7
@export var pingDelay: float = 0.1

var underground: bool = false
var found: bool = false

var id: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	if name.match("hiddenArea"):
		id = 1
	else:
		id = name.trim_prefix("hiddenArea").to_int()
		
	if map_mask != null:
		mapMaskRef = map_mask
	else:
		print("no map mask for: ", id)
	
	area_entered.connect(_player_detected)
	area_exited.connect(_player_exited)
	body_entered.connect(func(_body): _showarea())
	
	GameManager.treatsUpdated.connect(_areasUpdated)

func _process(delta):
	if mask.modulate != targetModulateColor:
		mask.modulate = mask.modulate.lerp(targetModulateColor, delta * modulateSpeed)

func _player_detected(_area):
	GameManager.playerRef.radar.connect(pingSoundPlay)
	
func _player_exited(_area):
	GameManager.playerRef.radar.disconnect(pingSoundPlay)
	if !found:
		targetModulateColor = Color.WHITE
	
func _areasUpdated():
	if mapMaskRef != null:
		if underground:
			mapMaskRef.reparent(GameManager.worldManager.underMap)
			#print("underground")
		else:
			mapMaskRef.reparent(GameManager.worldManager.overMap)
	
	if GameManager.hiddenRegistry.has(id):
		_showarea()
		found = true
	else:
		_hidearea()
		found = false
	
func _showarea():
	targetModulateColor = showColor
	if !GameManager.hiddenRegistry.has(id):
		GameManager.hiddenRegistry.append(id)
		found = true
	if mapMaskRef == null:
		return
	mapMaskRef.modulate = mapMaskShowColor
		
func pingSoundPlay():
	if found:
		return
	var time = Timer.new()
	add_child(time)
	targetModulateColor = pingHintColor
	time.wait_time = pingDelay + (ping.global_position.distance_to(GameManager.playerRef.global_position)/400.0)
	#print(time.wait_time)
	time.timeout.connect(ping.play)
	time.timeout.connect(time.queue_free)
	time.start()
	
func _hidearea():
	targetModulateColor = Color.WHITE
	if mapMaskRef == null:
		return
	mapMaskRef.modulate = Color.WHITE
	

	
