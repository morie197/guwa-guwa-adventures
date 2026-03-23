extends PanelContainer

const SLOT = preload("uid://b2ro5tjpr3nh3")

@onready var slotsContainer = %slots
@onready var text = %text

@onready var back_button = $menu/VBoxContainer/HBoxContainer/backButton

var mode: String = "load"

var parentMenu

var inPopup: bool = false

var buttonList = []

func _ready():
	if mode.match("load"):
		text.text = tr("LOAD")
	elif mode.match("save") or mode == "saveHard":
		text.text = tr("SAVE")
	
	if mode == "saveHard":
		back_button.text = "exit"
	
	_updateSlots()
		
	back_button.pressed.connect(_back)
	back_button.mouse_entered.connect(%hoversound.play)
		
func _updateSlots():
	if slotsContainer.get_child_count() > 0:
		for slot in slotsContainer.get_children():
			buttonList.erase(slot)
			slot.queue_free()
	
	for i in range(SaveManager.saveSlotCount):
		var slot = SLOT.instantiate()
		slot.slotMode = mode
		buttonList.append(slot)
		slotsContainer.add_child(slot)
		slot.selected.connect(_slotSelected)
		slot.deleted.connect(_slotDeleted)
		
		if SaveManager.saveDataAll.get(i) == null:
			slot.setData({}, i)
			continue
	
		slot.setData(SaveManager.saveDataAll[i], i)

func _slotSelected(slotNumber: int = 0):
	_inPopup()
	%clickSound.play()
	if mode == "load":
		if !SaveManager.saveDataAll[slotNumber].has("levelName"):
			return
	var popup = parentMenu.POPUP.instantiate()
	add_child(popup)
	
	if mode == "load":
		if !parentMenu.has_method("_newgame") and !parentMenu.has_method("gameLost"):
			popup.yes.connect(parentMenu.ui_manager.pause)
		if parentMenu.has_method("gameLost"):
			popup.yes.connect(parentMenu.closeLoadSave)
		
		popup.yes.connect(SaveManager.loadLevel.bind(SaveManager.saveDataAll[slotNumber]["levelName"]))
		
		popup.yes.connect(SaveManager.load_game.bind(slotNumber))
		#popup.yes.connect(GameManager.loadValues)
	
		popup.no.connect(popup.queue_free)
		popup.no.connect(_inPopup)
		#popup.no.connect(parentMenu._inPopup)
	
	elif mode == "save":
		if !parentMenu.has_method("gameLost"):
			popup.yes.connect(parentMenu.ui_manager.pause)
		popup.yes.connect(GameManager.saveValues)
		popup.yes.connect(SaveManager.save_game.bind(slotNumber))
	
		popup.no.connect(popup.queue_free)
		popup.no.connect(_inPopup)
		#popup.no.connect(parentMenu._inPopup)
		
	elif mode == "saveHard":
		if GameManager.worldManager == null:
			return
		if GameManager.worldManager.ui_manager == null:
			return
		popup.yes.connect(func unpause(): GameManager.paused = false)
		popup.yes.connect(GameManager.saveValues)
		popup.yes.connect(queue_free)
		popup.yes.connect(SaveManager.save_game.bind(slotNumber))
		popup.no.connect(popup.queue_free)
		popup.no.connect(_inPopup)
		
func _slotDeleted(slotNumber: int = 0):
	%clickSoundQuit.play()
	var popup = parentMenu.POPUP.instantiate()
	popup.warningText = tr("DELETE_WARNING") % str(slotNumber)
	add_child(popup)
	
	popup.yes.connect(SaveManager.delete_game.bind(slotNumber))
	popup.yes.connect(_updateSlots)
	popup.yes.connect(popup.queue_free)
	
	popup.no.connect(popup.queue_free)
	popup.no.connect(_inPopup)
	#popup.no.connect(parentMenu._inPopup)
	
func _back():
	var clickSound = %clickSoundQuit
	clickSound.reparent(parentMenu)
	clickSound.finished.connect(queue_free)
	clickSound.play()
	
	if parentMenu.has_method("_inPopup"):
		if parentMenu.inPopup:
			parentMenu._inPopup()
	if mode == "saveHard":
		GameManager.paused = false
		GameManager.saved.emit()
	queue_free()


func _inPopup():
	inPopup = !inPopup
	var buttons = [back_button]
	for button in buttons:
		button.disabled = inPopup
	for slot in buttonList:
		if slot != null:
			if !slot.is_queued_for_deletion():
				slot.toggleButtons(inPopup)	
