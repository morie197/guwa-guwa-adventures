extends Node

var level: int = 1
var treats: int = 0
var treatsUntilNextLevel: int = 0
var initialLevel: int = 13
var paused: bool = false

@export var baseRequiredTreats: int = 1
@export var requiredTreatsMultiplierIncrease: float = 0.15

var requiredTreatsMultiplier: int = 1

var upgradeLevels = {"range": 0, "stamina": 0, "speed": 0}
var availableUpgradePoints: int = 0

var abilityUnlockLevels = {1: "swim", 2: "sprint", 3: "quack", 5: "walk", 8: "sonar", 10: "dive", 13: "eggs", 15: "fly", 20: "migrate"}

var shownTutorials: Array[String]

var upgrades := {}
var abilities := []

var worldManager
var playerRef
var worldLayer = 1

signal levelUp
signal startTutorial(String)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
func enterLevel():	
	treatsUntilNextLevel = baseRequiredTreats
	for l in range(level, initialLevel):
		_levelUp()
		
	#if abilities.has("walk"): 
	#	playerRef.set_collision_mask_value(3, false)

func treatGet():
	treats += 1
	treatsUntilNextLevel -= 1
	print(treatsUntilNextLevel)
	if treatsUntilNextLevel == 0:
		_levelUp()

func closeUpgrades():
	calculateBonuses()
	paused = false
	
func showTutorial(tutorialName: String):
	if shownTutorials.has(tutorialName):
		return
	shownTutorials.append(tutorialName)
	startTutorial.emit(tutorialName)

func calculateBonuses():
	if playerRef != null:
		playerRef.staminaMultiplier = _calculateBonus("stamina")
		playerRef.rangeMultiplier = _calculateBonus("range")
		playerRef.speedMultiplier = _calculateBonus("speed")
		playerRef.initializeValues()

func _calculateBonus(upgradeName: String):
	return 1 + (upgradeLevels[upgradeName] * UpgradeData.UPGRADES[upgradeName]["percentIncrease"])/100.0

func _levelUp():
	requiredTreatsMultiplier = 1 + floor(requiredTreatsMultiplierIncrease * level)
	print(requiredTreatsMultiplier)
	treatsUntilNextLevel = round(baseRequiredTreats * requiredTreatsMultiplier)
	level += 1
	if abilityUnlockLevels.has(level):
		abilities.append(abilityUnlockLevels[level])
		
	availableUpgradePoints += 1
	levelUp.emit()
	print("emitted level up")
		
	if abilities.has("walk"): 
		playerRef.set_collision_mask_value(3, false)
		
	if abilities.has("fly"): 
		playerRef.set_collision_mask_value(4, false)
		
	
