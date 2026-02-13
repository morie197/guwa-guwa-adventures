extends Area2D

@export var requiredAbility: String

const SKILL_HINT = preload("uid://ctrk2bwc2f63d")

var displayName: String
var requiredLevel: int

var displayCooldown: float = 10

var canDisplay: bool = true

var timerBoi: Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	displayName = requiredAbility
	requiredLevel = -1
	for level in AbilityData.ABILITIES:
		if AbilityData.ABILITIES[level]["name"] == requiredAbility:
			displayName = AbilityData.ABILITIES[level]["displayName"]
			requiredLevel = level
			break


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func showHint(spawnPos: Vector2):
	#print(canDisplay)
	#print(timerBoi)
	if canDisplay == false:
		return
	if GameManager.abilities.has(requiredAbility):
		if !is_queued_for_deletion():
			queue_free()
	else:
		var skillHint = SKILL_HINT.instantiate()
		add_child(skillHint)
		skillHint.setText(displayName, requiredLevel)
		skillHint.global_position = spawnPos
		skillHint.position.x -= skillHint.size.x/2.0
		#skillHint.position += Vector2.RIGHT * 0
		skillHint.position += Vector2.UP * 160
		canDisplay = false
		if timerBoi == null:
			timerBoi = Timer.new()
			add_child(timerBoi)
			timerBoi.wait_time = displayCooldown
			timerBoi.timeout.connect(func allowDisplay(): canDisplay = true)
			timerBoi.timeout.connect(timerBoi.queue_free)
			timerBoi.start()
		
		
		
