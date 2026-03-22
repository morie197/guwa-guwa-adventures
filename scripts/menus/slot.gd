extends PanelContainer

@onready var slot_name = %slotName
@onready var health = %Health
@onready var difficulty = %Difficulty
@onready var level = %Level
@onready var upgrades = %Upgrades

@onready var stage_name = %StageName
@onready var empty_text = %emptyText

@onready var h_box_container = %HBoxContainer
@onready var h_box_container_2 = %HBoxContainer2
@onready var h_box_container_3 = %HBoxContainer3

@onready var img_panel_container = %imgPanelContainer

@onready var button = %Button
@onready var img = %img

@onready var delete_button = %deleteButton

signal selected(slot: int)
signal deleted(slot: int)

var slotMode: String = "load"

func setData(data, slotNumber: int = 0):
	if slotNumber == 0:
		if slotMode.match("load"):
			slot_name.text = tr("AUTOSAVE_SLOT")
			delete_button.disabled = true
			delete_button.hide()
		elif slotMode == "save" or slotMode == "saveHard":
			queue_free()
	else:
		#slot_name.text = "Slot " + str(slotNumber)
		h_box_container_3.hide()
		slot_name.hide()
		
	button.pressed.connect(func emitPressed(): selected.emit(slotNumber))
	delete_button.pressed.connect(func emitPressed(): deleted.emit(slotNumber))
		
	if data == {}:
		empty_text.show()
		delete_button.disabled = true
		delete_button.hide()
		h_box_container.hide()
		h_box_container_2.hide()
		h_box_container_3.hide()
		img_panel_container.hide()
		return
		
	if FileAccess.file_exists(SaveManager.imageSavePath + str(slotNumber) + ".jpg"):
		#print("jpg exists")
		var tex = ImageTexture.new()
		var image = Image.load_from_file(SaveManager.imageSavePath + str(slotNumber) + ".jpg")
		tex.set_image(image)
		img.texture = tex
	else:
		img_panel_container.hide()
		
		
	#level.text = str(data["currentHP"])
	#if data["abilities"].has("travel"):
		#if data.has("postgameUpgradeLevels"):
			#upgrades.text = "RES:" + str(int(data["postgameUpgradeLevels"]["resistance"])) + " | REA:" + str(int(data["postgameUpgradeLevels"]["reach"])) + " | POW:" + str(int(data["postgameUpgradeLevels"]["power"]))
	#else:
		#upgrades.text = "RAN:" + str(int(data["upgradeLevels"]["range"])) + " | END:" + str(int(data["upgradeLevels"]["endurance"])) + " | SPE:" + str(int(data["upgradeLevels"]["speed"]))
	level.text = tr("TREATS") + ": " + str(int(data["level"]))
	var levelName = data["levelName"]
	if levelName == "Quiet Gardens":
		stage_name.text = tr("STAGE_1")
	elif levelName == "Rocky Forest":
		stage_name.text = tr("STAGE_2")
	elif levelName == "Hidden Grove":
		stage_name.text = tr("STAGE_3")
	if int(data["difficulty"]) == 0:
		difficulty.text = tr("EASY")
		health.text = "HP: " + str(GameManager.baseHealthValue + floor(int(data["upgradeLevels"]["endurance"] / 2.0)))
	elif int(data["difficulty"]) == 1:
		difficulty.text = tr("MEDIUM")
		health.text = "HP: " + str(int(data["currentHP"])) + " / " + str(GameManager.baseHealthValue + floor(int(data["upgradeLevels"]["endurance"] / 2.0)))
	elif int(data["difficulty"]) == 2:
		difficulty.text = "[color=RED]" + tr("HARD") + "[/color]"
		health.text = "HP: " + str(int(data["currentHP"])) + " / " + str(GameManager.baseHealthValue + floor(int(data["upgradeLevels"]["endurance"] / 2.0)))
		
		
	#stage_name.text = "Map: " + data["levelName"]
	
	
	

	
	
