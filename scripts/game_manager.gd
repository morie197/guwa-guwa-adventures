extends Node

var level: int = 1
var EXP: int = 0
var EXPUntilNextLevel: int = 0
var initialLevel: int = 3
var paused: bool = false

@export var baseRequiredEXP: int = 200
@export var requiredEXPMultiplier: float = 1.3

var expMulti: float = 1.0

var upgradeLevels = {"zoom": 0, "gainedExp": 0, "stamina": 0, "speed": 0}
var availableUpgradePoints: int = 0

var abilityUnlockLevels = {1: "swim", 2: "sprint", 3: "quack", 5: "walk", 8: "sonar", 10: "dive", 13: "eggs", 15: "fly", 20: "migrate"}

var upgrades := {}
var abilities := []

var playerRef

signal levelUp

# Called when the node enters the scene tree for the first time.
func _ready():
	playerRef = get_tree().get_first_node_in_group("player")
	
	EXPUntilNextLevel = baseRequiredEXP
	for l in range(level, initialLevel):
		_levelUp(0)
		
	if abilities.has("walk"): 
		playerRef.set_collision_mask_value(3, false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func expGain(expAmount: int):
	EXP += round(expAmount * expMulti)
	if EXP >= EXPUntilNextLevel:
		_levelUp(EXP-EXPUntilNextLevel)

func closeUpgrades():
	expMulti = calculateBonus("gainedExp")
	if playerRef != null:
		playerRef.staminaMultiplier = calculateBonus("stamina")
		playerRef.zoomMultiplier = calculateBonus("zoom")
		playerRef.speedMultiplier = calculateBonus("speed")
	
	paused = false

func calculateBonus(upgradeName: String):
	return 1 + (upgradeLevels[upgradeName] * UpgradeData.UPGRADES[upgradeName]["percentIncrease"])/100.0

func _levelUp(overflowexp: int):
	EXPUntilNextLevel = round(EXPUntilNextLevel * requiredEXPMultiplier)
	level += 1
	EXP = overflowexp
	if abilityUnlockLevels.has(level):
		abilities.append(abilityUnlockLevels[level])
		
	availableUpgradePoints += 1
	levelUp.emit()
	print("emitted level up")
		
	if abilities.has("walk"): 
		playerRef.set_collision_mask_value(3, false)
		
	
