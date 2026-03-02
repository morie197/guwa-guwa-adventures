extends Node

var saveData: Dictionary = {}

var saveDataAll: Array = []

var fowSaveDataAll: Dictionary[int, Dictionary] = {}

var fowSaveData = {}

var saveSlotCount = 6

var autosave: bool = true

var savePath = "user://save_data.json"
var fowSavePath = "user://fow_data/"
var imageSavePath = "user://thumbnails/"
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
	#print("before: ", saveDataAll)
	#print(saveData)
	saveDataAll[slot] = saveData.duplicate(true)
	
	save_game_image(slot)
	
	saveAllData()
	
	_SaveWarner()
	
	save_fow(slot)
	
	if GameManager.worldManager == null:
		return
		
	await RenderingServer.frame_post_draw
	
	var saveText = GameManager.SAVE_LABEL.instantiate()
	GameManager.worldManager.ui_manager.hud.add_child(saveText)
	
	#print("saved slot: ", slot)
	#print(saveDataAll)
	#print(saveData)
	
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
		fowSaveDataAll[slot] = fowSaveData

func save_game_image(slot: int = 0):
	if GameManager.worldManager == null:
		return
	if GameManager.worldManager.ui_manager == null:
		return
		
	if !DirAccess.dir_exists_absolute(imageSavePath):
		DirAccess.make_dir_absolute(imageSavePath)
		
	GameManager.worldManager.ui_manager.hud.hide()
	await RenderingServer.frame_post_draw
	var image = get_viewport().get_texture().get_image()
	image.save_jpg(imageSavePath + str(slot) + ".jpg", 0.5)
	GameManager.worldManager.ui_manager.hud.show()

func load_game(slot: int = 0, forceLoad: bool = false):
	GameManager.loadingLevel = true
	var reloadRefs: bool = false
	
	if forceLoad:
		loadLevel(saveDataAll[slot]["levelName"], slot)
		reloadRefs = true
	elif saveData.has("levelName"):
		if saveDataAll[slot].has("levelName"):
			if saveData["levelName"] != saveDataAll[slot]["levelName"]:
				loadLevel(saveDataAll[slot]["levelName"], slot)
				reloadRefs = true
	else:
		reloadRefs = true
	
	saveData = saveDataAll[slot].duplicate(true)
	
	#if saveData.has("levelName"):
	#	if saveData["levelName"] != saveDataAll[slot]["levelName"]:
	#		print("loading level")

	load_fow(slot)
	
	GameManager.loadValues(reloadRefs)
	
	_SaveWarner()
	
		
func load_fow(slot: int = 0):
	fowSaveData = {}
	#print(fowSaveDataAll)
	if fowSaveDataAll.has(slot):
		fowSaveData = fowSaveDataAll[slot].duplicate(true)
		#print(fowSaveData)
		
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
	
	#print("deleting")
	
	var path = fowSavePath + str(slot)
	if FileAccess.file_exists(path + "/0.png"):
		DirAccess.remove_absolute(path + "/0.png")
	if FileAccess.file_exists(path + "/1.png"):
		DirAccess.remove_absolute(path + "/1.png")
	
	if FileAccess.file_exists(imageSavePath + str(slot) + ".jpg"):
		DirAccess.remove_absolute(imageSavePath + str(slot) + ".jpg")
	
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
	
func autoSave(forced: bool = false):
	GameManager.showTutorial("saving")
	#if autosaveCooldownTimer.time_left > 0.0:
	#	return
	if GameManager.lost:
		return
	if canAutosave == false and !forced:
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
	
func loadLevel(levelName: String, slot: int = -1):
	if GameManager.worldManager != null:
		if GameManager.worldManager.levelName.match(levelName):
			#print("already loaded!")
			return
	#if slot != -1:
		#if DirAccess.dir_exists_absolute(fowSavePath + str(slot) + "-0.png"):
			#print("deleting0")
			#DirAccess.remove_absolute(fowSavePath + str(slot) + "-0.png")
		#if DirAccess.dir_exists_absolute(fowSavePath + str(slot) + "-1.png"):
			#print("deleting1")
			#DirAccess.remove_absolute(fowSavePath + str(slot) + "-1.png")
	if levelName.match("Quiet Gardens"):
		get_tree().change_scene_to_file("res://scenes/levels/level2.tscn")
		return
	elif levelName.match("Rocky Forest"):
		get_tree().change_scene_to_file("res://scenes/levels/level.tscn")
		return
	elif levelName.match("Hidden Grove"):
		get_tree().change_scene_to_file("res://scenes/levels/level3.tscn")
		return
	
	
