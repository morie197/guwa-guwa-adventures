extends PanelContainer

@onready var slot_name = %slotName
@onready var health = %Health
@onready var difficulty = %Difficulty
@onready var level = %Level
@onready var upgrades = %Upgrades

@onready var stage_name = %StageName
@onready var empty_text = %emptyText

@onready var h_box_container = $VBoxContainer/HBoxContainer
@onready var h_box_container_2 = $VBoxContainer/HBoxContainer2

@onready var button = %Button

@onready var delete_button = %deleteButton

signal selected(slot: int)
signal deleted(slot: int)

var slotMode: String = "load"

func setData(data, slotNumber: int = 0):
	
	if slotNumber == 0:
		if slotMode.match("load"):
			slot_name.text = "Autosave"
			delete_button.disabled = true
			delete_button.hide()
		elif slotMode.match("save"):
			queue_free()
	else:
		slot_name.text = "Slot " + str(slotNumber)
		
	button.pressed.connect(func emitPressed(): selected.emit(slotNumber))
	delete_button.pressed.connect(func emitPressed(): deleted.emit(slotNumber))
		
	if data == {}:
		empty_text.show()
		h_box_container.hide()
		h_box_container_2.hide()
		return
		
	level.text = str(data["currentHP"])
	upgrades.text = "R:" + str(int(data["upgradeLevels"]["range"])) + " | E:" + str(int(data["upgradeLevels"]["endurance"])) + " | S:" + str(int(data["upgradeLevels"]["speed"]))
	level.text = "LVL: " + str(int(data["level"]))
	if int(data["difficulty"]) == 0:
		difficulty.text = "Difficulty: Easy"
	elif int(data["difficulty"]) == 1:
		difficulty.text = "Difficulty: Normal"
		
	stage_name.text = "Map: " + data["levelName"]
	
	health.text = "HP: " + str(int(data["currentHP"])) + " / " + str(GameManager.baseHealthValue + floor(int(data["upgradeLevels"]["endurance"] / 2.0)))
	

	
	
