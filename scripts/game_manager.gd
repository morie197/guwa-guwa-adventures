extends Node

var level: int = 1
var EXP: int = 0
var EXPUntilNextLevel: int = 0
var initialLevel: int = 3

@export var baseRequiredEXP: int = 200
@export var requiredEXPMultiplier: float = 1.3

var expMulti: float = 1

var availableUpgrades = {"zoom": 5, "gainedExp": 5, "stamina": 5, "speed": 5}

var abilityUnlockLevels = {1: "swim", 2: "sprint", 3: "quack", 5: "walk", 8: "sonar", 10: "dive", 13: "eggs", 15: "fly", 20: "migrate"}

var upgrades := {}
var abilities := []

var playerRef

# Called when the node enters the scene tree for the first time.
func _ready():
	playerRef = get_tree().get_first_node_in_group("player")
	print(playerRef)
	
	EXPUntilNextLevel = baseRequiredEXP
	for l in range(level, initialLevel):
		_levelUp(0)
		
	if abilities.has("walk"): 
		playerRef.set_collision_mask_value(3, false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func expGain(expAmount: int):
	EXP += expAmount
	if EXP >= EXPUntilNextLevel:
		_levelUp(EXP-EXPUntilNextLevel)

func _levelUp(overflowexp: int):
	EXPUntilNextLevel *= requiredEXPMultiplier
	level += 1
	EXP = overflowexp
	if abilityUnlockLevels.has(level):
		abilities.append(abilityUnlockLevels[level])
	_upgradeScreen()
	print(playerRef.get_collision_mask_value(3))
	if abilities.has("walk"): 
		playerRef.set_collision_mask_value(3, false)
	print(level, " ", abilities)
	
func _upgradeScreen():
	pass
