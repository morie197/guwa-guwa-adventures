extends Node

var saveData: Dictionary = {}

var saveDataAll: Array = []

var saveSlotCount = 4

var autosave: bool = true

var savePath = "user://save_data.json"
var saveWarningTime = 30
var saveWarning = false

var autosaveCooldown = 30
var canAutosave: bool = true

var autosaveCooldownTimer: Timer

var tim: Timer

func _ready():
	loadAllData()
	autosaveCooldownTimer = Timer.new()
	add_child(autosaveCooldownTimer)

func save_game(slot: int = 0):
	saveDataAll[slot] = saveData.duplicate()
	
	saveAllData()
	
	_SaveWarner()
	

func load_game(slot: int = 0):
	if saveData.has("levelName"):
		if saveData["levelName"] != saveDataAll[slot]["levelName"]:
			loadLevel(saveDataAll[slot]["levelName"])
			
	if saveData == {}:
		loadLevel(saveDataAll[slot]["levelName"])
			
	saveData = saveDataAll[slot].duplicate()
	
	GameManager.loadValues()
	
	_SaveWarner()
		
func delete_game(slot: int = 0):
	saveDataAll[slot] = {}
	
	saveAllData()
		
func check_save():
	if FileAccess.file_exists(savePath):
		return true
	return false
	
func _SaveWarner():
	saveWarning = false
	tim = Timer.new()
	add_child(tim)
	tim.wait_time = saveWarningTime
	tim.timeout.connect(func turnOnWarning(): saveWarning = true)
	#tim.timeout.connect(func warn(): print("save warning!"))
	tim.timeout.connect(tim.queue_free)
	tim.start()

func loadAllData():
	var baseData = [{}, {}, {}, {}]
	
	var readFile = FileAccess.open(savePath, FileAccess.READ)
	if readFile == null:
		saveDataAll = baseData
		print("no save data!")
		return
	var data = readFile.get_as_text()
	readFile.close()
	
	if data != "":
		saveDataAll = JSON.parse_string(data)
		
func saveAllData():
	if saveDataAll.is_empty():
		print("empty save data!")
		return
	var writeFile = FileAccess.open(savePath, FileAccess.WRITE)
	if writeFile == null:
		print("failed to open!")
		return
	writeFile.store_string(JSON.stringify(saveDataAll))
	writeFile.close()
	
func autoSave():
	GameManager.showTutorial("saving")
	#if autosaveCooldownTimer.time_left > 0.0:
	#	return
	if canAutosave == false:
		return
	if autosave == false:
		return
	if GameManager.wonGame == true or GameManager.playerRef.migrating == true:
		return
	autosaveCooldownTimer.wait_time = autosaveCooldown
	canAutosave = false
	autosaveCooldownTimer.timeout.connect(func toggleAutosaveCooldown(): canAutosave = true)
	autosaveCooldownTimer.start()

	GameManager.saveValues()
	save_game()
	
func loadLevel(levelName: String):
	if GameManager.worldManager != null:
		if GameManager.worldManager.levelName.match(levelName):
			print("already loaded!")
			return
	
	if levelName.match("Quiet Gardens"):
		get_tree().change_scene_to_file("res://scenes/level2.tscn")
		return
	elif levelName.match("Rocky Forest"):
		get_tree().change_scene_to_file("res://scenes/level.tscn")
		return
	
	
