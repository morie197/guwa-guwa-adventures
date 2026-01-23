extends Node

var level: int = 1
var initialLevel: int = 6
var paused: bool = false
var minigame: bool = false
var wonGame: bool = false
var inUpgradeMenu: bool = false

const DUCK_MINIGAME = preload("uid://djxnchr27abqs")

var upgradeLevels = {"range": 0, "stamina": 0, "speed": 0}
var availableUpgradePoints: int = 0

var duckRegistry: Array[int] = []
var treatRegistry: Array[int] = []

var shownTutorials = []

var abilities := []

var worldManager
var playerRef
var worldLayer = 1

signal levelUp
signal startTutorial(String)
signal treatsUpdated
signal levelLoaded
	
func enterLevel():	
	paused = false
	minigame = false
	inUpgradeMenu = false
	wonGame = false
	
	levelLoaded.emit()
	for l in range(level, initialLevel):
		treatGet()
	playerRef.updatedStamina.connect(GameManager.worldManager.ui_manager.updateStaminaBar)
	playerRef.emitUpdatedStaminaValue()
	
func saveValues():
	SaveManager.saveData["player_pos_x"] = playerRef.global_position.x
	SaveManager.saveData["player_pos_y"] = playerRef.global_position.y
	SaveManager.saveData["worldLayer"] = worldLayer
	SaveManager.saveData["level"] = level
	SaveManager.saveData["shownTutorials"] = shownTutorials
	SaveManager.saveData["abilities"] = abilities
	SaveManager.saveData["upgradeLevels"] = upgradeLevels
	SaveManager.saveData["duckRegistry"] = duckRegistry
	SaveManager.saveData["treatRegistry"] = treatRegistry

func loadValues():
	if SaveManager.saveData.is_empty():
		print("no save data")
		await levelLoaded
	playerRef.global_position = Vector2(SaveManager.saveData.get("player_pos_x", 0), SaveManager.saveData.get("player_pos_y", 0))
	if SaveManager.saveData.get("worldLayer", 1) != worldLayer:
		if worldManager == null:
			print("null world manager")
		else:
			worldManager.switchUnderOverGround()
	level = int(SaveManager.saveData.get("level", 1))
	shownTutorials = SaveManager.saveData.get("shownTutorials", [])
	abilities = SaveManager.saveData.get("abilities", [])
	var upgradeLevelsData = SaveManager.saveData.get("upgradeLevels", {})
	upgradeLevels["range"] = int(upgradeLevelsData.get("range", 0))
	upgradeLevels["stamina"] = int(upgradeLevelsData.get("stamina", 0))
	upgradeLevels["speed"] = int(upgradeLevelsData.get("speed", 0))
	
	duckRegistry.assign(SaveManager.saveData.get("duckRegistry", []))
	treatRegistry.assign(SaveManager.saveData.get("treatRegistry", []))
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	treatsUpdated.emit()
	
	abilityCheck()

func treatGet():
	_levelUp()

func closeUpgrades():
	inUpgradeMenu = false
	calculateBonuses()
	paused = false
	
func showTutorial(tutorialName: String):
	if shownTutorials.has(tutorialName):
		return
	shownTutorials.append(tutorialName)
	startTutorial.emit(tutorialName)
	
func initiateMinigame(entityNames: Array[String], entityHealth: Array[int], stageName: String, owners):
	paused = true
	minigame = true
	if worldLayer == 0:
		worldManager.darkener.hide()
	var minigame_stage = DUCK_MINIGAME.instantiate()
	if owners.size() == 0:
		print("not properly setup!")
		return
	minigame_stage.global_position = owners[0].global_position
	worldManager.add_child(minigame_stage)
	for index in range(entityNames.size()):
		minigame_stage.enemyNames.append(entityNames[index])
		minigame_stage.enemyHealthValues.append(entityHealth[index])
		
	minigame_stage.enemyCount = entityNames.size()
	minigame_stage.level = level
	minigame_stage.speedMultiplier = playerRef.speedMultiplier
	minigame_stage.rangeMultiplier = playerRef.rangeMultiplier
	minigame_stage.staminaMultiplier = playerRef.staminaMultiplier
	minigame_stage.position = minigame_stage.position - Vector2(1920/2, 1080/2)
	
	minigame_stage.stage = stageName
	minigame_stage.initValues()
	
	for own in owners:
		minigame_stage.won.connect(own.playerWon)
		minigame_stage.lost.connect(own.playerLost)
	
	minigame_stage.won.connect(minigame_stage.queue_free)
	minigame_stage.lost.connect(minigame_stage.queue_free)

func calculateBonuses():
	if playerRef != null:
		playerRef.staminaMultiplier = _calculateBonus("stamina")
		playerRef.rangeMultiplier = _calculateBonus("range")
		playerRef.speedMultiplier = _calculateBonus("speed")
		playerRef.initializeValues()

func _calculateBonus(upgradeName: String):
	return 1 + (upgradeLevels[upgradeName] * UpgradeData.UPGRADES[upgradeName]["percentIncrease"])/100.0

func _levelUp():
	level += 1
	if AbilityData.ABILITIES.has(level):
		abilities.append(AbilityData.ABILITIES[level]["name"])
		
	availableUpgradePoints += 1
	inUpgradeMenu = true
	levelUp.emit()
		
	abilityCheck()
		
func won():
	wonGame = true
	paused = true
	worldManager.ui_manager.gameWon()
	
func abilityCheck():
	if abilities.has("sprint"):
		worldManager.ui_manager.stamina_bar.show()
	else:
		worldManager.ui_manager.stamina_bar.hide()
		
	if abilities.has("walk"): 
		playerRef.set_collision_mask_value(3, false)
	else:
		playerRef.set_collision_mask_value(3, true)
		
	if abilities.has("fly"): 
		playerRef.set_collision_mask_value(4, false)
	else:
		playerRef.set_collision_mask_value(4, true)
	
