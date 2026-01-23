extends Node

var saveData = {}

var savePath = "user://save_data.json"
var saveWarningTime = 30
var saveWarning = false
var tim: Timer

func save_game():
	if saveData.is_empty():
		print("empty save data!")
		return
	var writeFile = FileAccess.open(savePath, FileAccess.WRITE)
	if writeFile == null:
		print("failed to open!")
		return
	writeFile.store_string(JSON.stringify(saveData))
	writeFile.close()
	
	_SaveWarner()

func load_game():
	var readFile = FileAccess.open(savePath, FileAccess.READ)
	if readFile == null:
		print("no save data!")
		return
	var data = readFile.get_as_text()
	readFile.close()
	
	if data != "":
		saveData = JSON.parse_string(data)
		
	_SaveWarner()
		
func new_game():
	if FileAccess.file_exists(savePath):
		DirAccess.remove_absolute(savePath)
		saveData = {}
	_SaveWarner()
		
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
