extends Node

var saveData: Dictionary = {}

var saveDataAll: Array = []

var fowSaveDataAll: Dictionary[int, Dictionary] = {}

var fowSaveData = {}

var saveSlotCount = 6

var autosave: bool = true

var savePath = "user://save_data.json"
var fowSavePath = "user://fow_data/"
var saveWarningTime = 30
var saveWarning = false

var autosaveCooldown = 30
var canAutosave: bool = true

var autosaveCooldownTimer: Timer

var tim: Timer

func _ready():
	loadAllData()
	if saveDataAll.size() < saveSlotCount:
		for i in range(saveDataAll.size(), saveSlotCount):
			saveDataAll.append({})
	autosaveCooldownTimer = Timer.new()
	add_child(autosaveCooldownTimer)

func save_game(slot: int = 0):
	saveDataAll[slot] = saveData.duplicate()
	
	saveAllData()
	
	_SaveWarner()
	
	save_fow(slot)
	
func save_fow(slot: int = 0):
	var path = fowSavePath + str(slot)
	if !DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_recursive_absolute(path)
	if fowSaveData != {}:
		if fowSaveData.has(0):
			var underImage = fowSaveData[0].convert_to_image()
			underImage.save_png(path + "/0.png")
		if fowSaveData.has(1):
			var overImage = fowSaveData[1].convert_to_image()
			overImage.save_png(path + "/1.png")
			print(path + "/1.png")

func load_game(slot: int = 0):
	GameManager.loadingLevel = true
	var reloadRefs: bool = false
	
	if saveData.has("levelName"):
		if saveDataAll[slot].has("levelName"):
			if saveData["levelName"] != saveDataAll[slot]["levelName"]:
				loadLevel(saveDataAll[slot]["levelName"])
				reloadRefs = true
	else:
		reloadRefs = true
	
	saveData = saveDataAll[slot].duplicate()
	
	#if saveData.has("levelName"):
	#	if saveData["levelName"] != saveDataAll[slot]["levelName"]:
	#		print("loading level")
	
	GameManager.loadValues(reloadRefs)
	
	_SaveWarner()
	
	load_fow(slot)
		
func load_fow(slot: int = 0):
	fowSaveData = {}
	print(fowSaveDataAll)
	if fowSaveDataAll.has(slot):
		fowSaveData = fowSaveDataAll[slot].duplicate()
		print(fowSaveData)
		
func load_all_fow():
	for slot in range(saveSlotCount):
		var dict: Dictionary[int, BitMap] = {}
		var path = fowSavePath + str(slot)
		if !DirAccess.dir_exists_absolute(path):
			DirAccess.make_dir_recursive_absolute(path)
		if FileAccess.file_exists(path + "/0.png"):
			var underImage = Image.load_from_file(path + "/0.png")
			if underImage != null:
				var underBitmap = bitmap_to_image(underImage)
				if underBitmap != null:
					dict[0] = underBitmap
		if FileAccess.file_exists(path + "/1.png"):
			var overImage = Image.load_from_file(path + "/1.png")
			if overImage != null:
				var overBitmap = bitmap_to_image(overImage)
				if overBitmap != null:
					dict[1] = overBitmap
			
		fowSaveDataAll[slot] = dict
	
func bitmap_to_image(img: Image) -> BitMap:
	var bitmap = BitMap.new()
	bitmap.create(img.get_size())
	for y in img.get_height():
		for x in img.get_width():
			var color = img.get_pixel(x, y)
			if color.v > 0.5:
				bitmap.set_bit(x, y, true)
	return bitmap
	
func delete_game(slot: int = 0):
	saveDataAll[slot] = {}
	
	fowSaveDataAll[slot].erase(0)
	fowSaveDataAll[slot].erase(1)
	
	if DirAccess.dir_exists_absolute(fowSavePath + str(slot) + "-0.png"):
		DirAccess.remove_absolute(fowSavePath + str(slot) + "-0.png")
	if DirAccess.dir_exists_absolute(fowSavePath + str(slot) + "-1.png"):
		DirAccess.remove_absolute(fowSavePath + str(slot) + "-1.png")
	
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
	var baseData = [{}, {}, {}, {}, {}, {}]
	
	var readFile = FileAccess.open(savePath, FileAccess.READ)
	if readFile == null:
		#push_warning("Failed to open file because: %s (Error code: %d)" % [error_str, error_code])
		saveDataAll = baseData.duplicate()
		return
	var data = readFile.get_as_text()
	readFile.close()
	
	if data != "":
		saveDataAll = JSON.parse_string(data)
		
	load_all_fow()
		
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
			#print("already loaded!")
			return
	
	
	
	if levelName.match("Quiet Gardens"):
		get_tree().change_scene_to_file("res://scenes/levels/level2.tscn")
		return
	elif levelName.match("Rocky Forest"):
		get_tree().change_scene_to_file("res://scenes/levels/level.tscn")
		return
	elif levelName.match("Hidden Grove"):
		get_tree().change_scene_to_file("res://scenes/levels/level3.tscn")
		return
	
	
