extends Area2D

@onready var mask = $Mask
@onready var ping = $ping

@export var showColor: Color = Color(0.753, 0.0, 0.18, 0.212)

var targetModulateColor: Color = Color.WHITE

@export var modulateSpeed: float = 0.7
@export var pingDelay: float = 0.1

# Called when the node enters the scene tree for the first time.
func _ready():
	area_entered.connect(_player_detected)
	area_exited.connect(_player_exited)
	body_entered.connect(func(_body): _showarea(false))

func _process(delta):
	if mask.modulate != targetModulateColor:
		mask.modulate = mask.modulate.lerp(targetModulateColor, delta * modulateSpeed)

func _player_detected(_area):
	GameManager.playerRef.radar.connect(_showarea.bind(true))
	
func _player_exited(_area):
	GameManager.playerRef.radar.disconnect(_showarea)
	_hidearea()
	
func _showarea(playSound: bool = false):
	targetModulateColor = showColor
	if playSound == true:
		var time = Timer.new()
		add_child(time)
		time.wait_time = pingDelay
		time.timeout.connect(ping.play)
		time.timeout.connect(time.queue_free)
		time.start()
	
func _hidearea():
	targetModulateColor = Color.WHITE
	

	
