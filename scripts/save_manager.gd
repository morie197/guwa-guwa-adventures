extends Node

var saveData = {}

var savePath = "user://save_data.json"

var playerPos: Vector2
var worldLevel: int
var playerLevel: int
var upgradeLevels: Dictionary[String, int]
var shownTutorials: Array[String]
var abilities: Array[String]

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

func load_game():
	var readFile = FileAccess.open(savePath, FileAccess.READ)
	if readFile == null:
		print("no save data!")
		return
	var data = readFile.get_as_text()
	readFile.close()
	
	if data != "":
		saveData = JSON.parse_string(data)
		
