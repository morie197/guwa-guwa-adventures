extends PanelContainer

const SLOT = preload("uid://b2ro5tjpr3nh3")

@onready var slotsContainer = %slots
@onready var text = %text

@onready var back_button = $menu/VBoxContainer/HBoxContainer/backButton

var mode: String = "load"

var parentMenu

func _ready():
	if mode.match("load"):
		text.text = "Load"
	elif mode.match("save"):
		text.text = "Save"
		
	print("updated")
	
	_updateSlots()
		
	back_button.pressed.connect(_back)
		
func _updateSlots():
	if slotsContainer.get_child_count() > 0:
		for slot in slotsContainer.get_children():
			slot.queue_free()
	
	for i in range(SaveManager.saveSlotCount):
		var slot = SLOT.instantiate()
		slot.slotMode = mode
		slotsContainer.add_child(slot)
		slot.selected.connect(_slotSelected)
		slot.deleted.connect(_slotDeleted)
		
		if SaveManager.saveDataAll.get(i) == null:
			slot.setData({}, i)
			continue
	
		slot.setData(SaveManager.saveDataAll[i], i)

func _slotSelected(slotNumber: int = 0):
	if mode.match("load"):
		if !SaveManager.saveDataAll[slotNumber].has("levelName"):
			print("invalid save")
			return
	var popup = parentMenu.POPUP.instantiate()
	add_child(popup)
	
	if mode.match("load"):
		if !parentMenu.has_method("_newgame") and !parentMenu.has_method("gameLost"):
			popup.yes.connect(parentMenu.ui_manager.pause)
		if parentMenu.has_method("gameLost"):
			popup.yes.connect(parentMenu.closeLoadSave)
		
		popup.yes.connect(SaveManager.loadLevel.bind(SaveManager.saveDataAll[slotNumber]["levelName"]))
		
		popup.yes.connect(SaveManager.load_game.bind(slotNumber))
		#popup.yes.connect(GameManager.loadValues)
	
		popup.no.connect(popup.queue_free)
		#popup.no.connect(parentMenu._inPopup)
	
	elif mode.match("save"):
		if !parentMenu.has_method("gameLost"):
			popup.yes.connect(parentMenu.ui_manager.pause)
		popup.yes.connect(GameManager.saveValues)
		popup.yes.connect(SaveManager.save_game.bind(slotNumber))
	
		popup.no.connect(popup.queue_free)
		#popup.no.connect(parentMenu._inPopup)
		
func _slotDeleted(slotNumber: int = 0):
	var popup = parentMenu.POPUP.instantiate()
	popup.warningText = "Are you sure you want to delete slot " + str(slotNumber) + "?"
	add_child(popup)
	
	popup.yes.connect(SaveManager.delete_game.bind(slotNumber))
	popup.yes.connect(_updateSlots)
	popup.yes.connect(popup.queue_free)
	
	popup.no.connect(popup.queue_free)
	#popup.no.connect(parentMenu._inPopup)
	
func _back():
	parentMenu._inPopup()
	queue_free()
