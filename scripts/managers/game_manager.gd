extends Node

var level: int = 0
var initialLevel: int = 0
var paused: bool = false
var minigame: bool = false
var wonGame: bool = false
var inUpgradeMenu: bool = false
var baseHealthValue: int = 10
var cameraShown: bool = false
var healthValue: int = 5
var maxHP: int = 5

var lost: bool = false

var testingCheats: bool = false

enum Difficulty {EASY, NORMAL, HARD}
var difficultyValue: Difficulty = Difficulty.NORMAL

var hpRestoredFromTreat: int = 3

const SAVE_LABEL = preload("uid://dr217ab6yuj6k")
const DUCK_MINIGAME = preload("uid://djxnchr27abqs")
const BRIGHT_NOTIFICATION_352449 = preload("uid://cbayh0an2p7ho")

var upgradeLevels = {"range": 0, "endurance": 0, "speed": 0}
var availableUpgradePoints: int = 0

var duckRegistry: Array[int] = []
var treatRegistry: Array[int] = []

var revealedTiles: Array[Vector2i] = []
var revealedTilesUnder: Array[Vector2i] = []

var hiddenRegistry: Array[int] = []

var shownTutorials = []

var abilities := []

var worldManager
var playerRef
var worldLayer = 1
var switchedWorldLayer: bool = false

var playerCamCredits
var minimapCam

var canDamage: bool = true
var damageCooldown: float = 1.25

signal levelUp
signal startTutorial(String)
signal treatsUpdated
signal levelLoaded
signal upgraded
signal tutorialOver
	
func enterLevel():	
	paused = false
	minigame = false
	inUpgradeMenu = false
	wonGame = false
	
	if initialLevel > 0:
		testingCheats = true
		
	GameManager.worldManager.ui_manager.minimap.world_2d = get_tree().root.get_viewport().world_2d
	minimapCam = GameManager.worldManager.ui_manager.minimap_camera
	
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
	SaveManager.saveData["shownTutorials"] = shownTutorials.duplicate()
	SaveManager.saveData["abilities"] = abilities.duplicate()
	SaveManager.saveData["upgradeLevels"] = upgradeLevels.duplicate()
	SaveManager.saveData["duckRegistry"] = duckRegistry.duplicate()
	SaveManager.saveData["treatRegistry"] = treatRegistry.duplicate()
	SaveManager.saveData["currentHP"] = healthValue
	SaveManager.saveData["difficulty"] = difficultyValue
	SaveManager.saveData["levelName"] = worldManager.levelName
	SaveManager.saveData["revealedTiles"] = stringToVector2i(genericArrayToVector2i(worldManager.revealedTilesDict.keys()))
	SaveManager.saveData["revealedTilesUnder"] = stringToVector2i(genericArrayToVector2i(worldManager.revealedTilesUnderDict.keys()))
	SaveManager.saveData["hiddenRegistry"] = hiddenRegistry.duplicate()
	
	var saveText = SAVE_LABEL.instantiate()
	worldManager.ui_manager.add_child(saveText)

func genericArrayToVector2i(targets) -> Array[Vector2i]:
	var typedArray: Array[Vector2i]
	for target in targets:
		typedArray.append(Vector2i(target))
	return typedArray

func stringToVector2i(targets):
	#print(targets)
	if targets == null:
		return
	if targets.size() == 0:
		print("empty")
		return
	
	if targets is Array and !targets.is_empty() and targets[0] is String:
		var newArray: Array[Vector2i]
		for target in targets:
			newArray.append(str_to_var(target))
		return newArray
	elif targets is Array[Vector2i]:
		#print("array Vector2i")
		var newArray: Array[String]
		for target in targets:
			newArray.append(var_to_str(target))
		return newArray
	else:
		#print("else")
		return


func loadValues(resetRefs: bool = false):
	if resetRefs:
		playerRef = null
		worldManager = null
	
	if playerRef == null or worldManager == null:
		print("waiting")
		await levelLoaded
	
	worldManager.clearFOW()
	
	if SaveManager.saveData.is_empty():
		print("no save data")
	
	playerRef.global_position = Vector2(SaveManager.saveData.get("player_pos_x", 0), SaveManager.saveData.get("player_pos_y", 0))
	level = int(SaveManager.saveData.get("level", 0))
	shownTutorials = SaveManager.saveData.get("shownTutorials", [])
	abilities = SaveManager.saveData.get("abilities", [])
	var upgradeLevelsData = SaveManager.saveData.get("upgradeLevels", {})
	upgradeLevels["range"] = int(upgradeLevelsData.get("range", 0))
	upgradeLevels["endurance"] = int(upgradeLevelsData.get("endurance", 0))
	upgradeLevels["speed"] = int(upgradeLevelsData.get("speed", 0))
	
	difficultyValue = SaveManager.saveData.get("difficulty", Difficulty.NORMAL)
	
	canDamage = false
	healthValue = SaveManager.saveData.get("currentHP", 5)
	
	duckRegistry.assign(SaveManager.saveData.get("duckRegistry", []))
	treatRegistry.assign(SaveManager.saveData.get("treatRegistry", []))
	hiddenRegistry.assign(SaveManager.saveData.get("hiddenRegistry", []))
	
	revealedTiles = []
	revealedTilesUnder = []
	
	var revTiles = SaveManager.saveData.get("revealedTiles", null)
	if revTiles != null:
		print("not null1")
		revealedTiles.assign(stringToVector2i(revTiles))
		
	var revTilesUnder = SaveManager.saveData.get("revealedTilesUnder", null)
	if revTilesUnder != null:
		revealedTilesUnder.assign(stringToVector2i(revTilesUnder))
	
	if worldManager != null:
		worldManager.loadFOW()
	
	levelUp.emit()
	
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	if SaveManager.saveData.get("worldLayer", 1) != worldLayer:
		if worldManager == null:
			print("null world manager")
		else:
			worldManager.switchUnderOverGround()
	
	canDamage = true
	treatsUpdated.emit()
	
	playerRef.loadGameChecks()
	
	calculateBonuses(false)
	
	upgraded.emit()
	
	abilityCheck()
	
	worldManager.ui_manager.updateNextAbility()
	

func treatGet():
	_levelUp()

func closeUpgrades():
	inUpgradeMenu = false
	calculateBonuses()
	paused = false
	upgraded.emit()
	
	if abilities.has("quack"):
		showTutorial("quack")
	if abilities.has("sprint"):
		showTutorial("sprint")
	if abilities.has("sonar"):
		showTutorial("radar")
	if abilities.has("walk"):
		showTutorial("land")
	if abilities.has("dive"):
		showTutorial("dive")
	if abilities.has("fly"):
		showTutorial("fly")
	if abilities.has("migrate"):
		showTutorial("migrate")
	if abilities.has("map"):
		showTutorial("map")
	
	if testingCheats == true:
		testingCheats = false
		return
	
	SaveManager.autoSave()
	
func cameraShow(category: String):
	paused = true
	if shownTutorials.has(category) or playerRef == null:
		#print("already shown")
		return
	
	var nodes
	match category:
		"quack":
			nodes = worldManager.quackNodes
		"land":
			nodes = worldManager.land_nodes
		"dive":
			nodes = worldManager.dive_nodes
		"fly":
			nodes = worldManager.fly_nodes
	
	if nodes == null:
		#print(category)
		#print("none")
		return
	
	var finalNodePos = Vector2.INF
	for node in nodes.get_children():
		if playerRef.global_position.distance_to(node.global_position) < playerRef.global_position.distance_to(finalNodePos):
			finalNodePos = node.global_position
	
	var cam = Camera2D.new()
	cam.global_position = finalNodePos
	add_child(cam)
	cam.make_current()
	
	var tim = Timer.new()
	tim.wait_time = 5
	add_child(tim)
	
	if worldLayer == 0:
		switchedWorldLayer = true
		worldManager.switchUnderOverGround()
	
	if !tutorialOver.is_connected(cameraShowPause):
		tutorialOver.connect(cameraShowPause)
	
	tutorialOver.connect(cam.queue_free)
	tutorialOver.connect(tim.queue_free)
	
	tim.timeout.connect(cam.queue_free)
	tim.timeout.connect(cameraShowPause)
	tim.timeout.connect(tim.queue_free)

	tim.start()
	cameraShown = true

func cameraShowPause():
	if tutorialOver.is_connected(cameraShowPause):
		tutorialOver.disconnect(cameraShowPause)
	
	if switchedWorldLayer:
		cameraSwitchWorldLayer()
		switchedWorldLayer = false
	
	if cameraShown:
		paused = false
		cameraShown = false
		
func cameraSwitchWorldLayer():
	if switchedWorldLayer == true:
		worldManager.switchUnderOverGround()
	
	
func showTutorial(tutorialName: String):
	if shownTutorials.has(tutorialName):
		return
		
	if tutorialName.match("quack") or tutorialName.match("land") or tutorialName.match("dive") or tutorialName.match("fly"):
		print("showing")
		cameraShow(tutorialName)
		
	shownTutorials.append(tutorialName)
	startTutorial.emit(tutorialName)
	
func initiateMinigame(entityNames: Array[String], entityHealth: Array[int], stageName: String, owners):
	paused = true
	minigame = true
	
	worldManager.ui_manager.hud.hide()
	
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
	minigame_stage.enduranceMultiplier = playerRef.enduranceMultiplier
	minigame_stage.position = minigame_stage.position - Vector2(1920/2, 1080/2)
	
	minigame_stage.stage = stageName
	minigame_stage.initValues()
	
	for own in owners:
		minigame_stage.won.connect(own.playerWon)
		minigame_stage.lost.connect(own.playerLost)
	
	minigame_stage.won.connect(minigame_stage.queue_free)
	minigame_stage.lost.connect(minigame_stage.queue_free)
	
	minigame_stage.won.connect(worldManager.ui_manager.hud.show)
	minigame_stage.lost.connect(worldManager.ui_manager.hud.show)
	

func calculateBonuses(heal: bool = true):
	if playerRef != null:
		playerRef.enduranceMultiplier = _calculateBonus("endurance")
		playerRef.rangeMultiplier = _calculateBonus("range")
		playerRef.speedMultiplier = _calculateBonus("speed")
		playerRef.initializeValues()
		
	maxHP = baseHealthValue + floor(upgradeLevels["endurance"] / 2.0)
	playerRef.emitUpdatedStaminaValue()
	
	if heal:
		healPlayer(hpRestoredFromTreat)
		
func healPlayer(amount: int = 1):
	if healthValue < maxHP:
		playerRef.heal_sound.pitch_scale = 1.6 + clampf(healthValue/maxHP, 0, 1)
		playerRef.heal_sound.play(0.15)
	
	healthValue = clamp(healthValue + amount, 0, maxHP)
	if worldManager != null:
		worldManager.ui_manager._updateMaxHP()

func _calculateBonus(upgradeName: String):
	return 1 + (upgradeLevels[upgradeName] * UpgradeData.UPGRADES[upgradeName]["percentIncrease"])/100.0

func _levelUp():
	level += 1
	for i in range(level + 1):
		if AbilityData.ABILITIES.has(i):
			if !abilities.has(AbilityData.ABILITIES[i]["name"]):
				abilities.append(AbilityData.ABILITIES[i]["name"])
		
	availableUpgradePoints += 1
	inUpgradeMenu = true
	levelUp.emit()
		
	abilityCheck()
		
func won():
	wonGame = true
	paused = true
	SaveManager.saveData = {}
	worldManager.ui_manager.gameWon()
	
func abilityCheck():
	for i in range(level + 1):
		if AbilityData.ABILITIES.has(i):
			if !abilities.has(AbilityData.ABILITIES[i]["name"]):
				abilities.append(AbilityData.ABILITIES[i]["name"])
	
	if abilities.has("sprint"):
		worldManager.ui_manager.stamina_bar.show()
		playerRef.emitUpdatedStaminaValue()
	else:
		worldManager.ui_manager.stamina_bar.hide()
		
	if abilities.has("quack") and !difficultyValue == Difficulty.EASY:
		worldManager.ui_manager.hp_bars.show()
		worldManager.ui_manager.hp_text.show()
	else:
		worldManager.ui_manager.hp_bars.hide()
		worldManager.ui_manager.hp_text.hide()
		
	if abilities.has("walk"): 
		playerRef.set_collision_mask_value(3, false)
	else:
		playerRef.set_collision_mask_value(3, true)
		
	if abilities.has("fly"): 
		playerRef.set_collision_mask_value(4, false)
	else:
		playerRef.set_collision_mask_value(4, true)
		
	if abilities.has("map"):
		worldManager.ui_manager.mini_map_panel.show()
	else:
		worldManager.ui_manager.mini_map_panel.hide()
	
func lostGame():
	GameManager.paused = true
	lost = true
	worldManager.ui_manager.gameLost()
	
func damagePlayer(amount: int = 1):
	if GameManager.difficultyValue == GameManager.Difficulty.EASY:
		return
	if canDamage == false:
		return
	canDamage = false
	playerRef.damaged_sound.play()
	healthValue = clamp(healthValue - amount, 0, maxHP)
	upgraded.emit()
	if healthValue <= 0:
		lostGame()
	var tim = Timer.new()
	add_child(tim)
	tim.wait_time = damageCooldown
	tim.timeout.connect(func canDamagePlayer(): canDamage = true)
	tim.timeout.connect(func canDamagedPlayer(): print(canDamage))
	tim.timeout.connect(tim.queue_free)
	tim.start()
	
func changeDifficulty(diff: Difficulty):
	difficultyValue = diff
		
		
	
