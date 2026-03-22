extends PanelContainer

@onready var back_button = $menu/VBoxContainer/HBoxContainer/backButton
@onready var music_slider = $menu/VBoxContainer/music/musicSlider
@onready var sound_slider = $menu/VBoxContainer/sounds/soundSlider

@onready var autosaves = $menu/VBoxContainer/HBoxContainer2/autosaves
@onready var fullscreen = $menu/VBoxContainer/HBoxContainer3/fullscreen

func _ready():
	music_slider.value_changed.connect(_music_changed)
	sound_slider.value_changed.connect(_sound_changed)
	
	music_slider.drag_ended.connect(%clickSound.play)
	sound_slider.drag_ended.connect(%clickSound.play)
	
	back_button.pressed.connect(queue_free)
	back_button.pressed.connect(_back)
	back_button.pressed.connect(SaveManager.saveConfigData)
	back_button.mouse_entered.connect(%hoversound.play)
	
	if SaveManager.autosave == false:
		autosaves.button_pressed = false
	if GameManager.fullscreen == true:
		fullscreen.button_pressed = true
	if GameManager.showTutorials == false:
		%tutorials.button_pressed = false
	
	autosaves.pressed.connect(toggleAutosaves)
	fullscreen.pressed.connect(GameManager.toggleFullscreen)
	%tutorials.pressed.connect(toggleTutorials)
	autosaves.pressed.connect(%clickSound.play)
	fullscreen.pressed.connect(%clickSound.play)
	%tutorials.pressed.connect(%clickSound.play)
	
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
	sound_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))
	
	_localeButtonSetup()
	
func _back():
	var clickSound = %clickSoundQuit
	if get_parent() != null:
		var parent = get_parent()
		clickSound.reparent(parent)
		clickSound.finished.connect(queue_free)
		clickSound.play()
	
func _localeButtonSetup():
	var nativeNames = {
		"en": "English",
		"ja": "日本語",
		"zh_CN": "简体中文",
		"zh_TW": "繁體中文"
	}
	
	var locales = TranslationServer.get_loaded_locales()
	
	for i in range(locales.size()):
		var localCode = locales[i]
		
		%languages.add_item(nativeNames[localCode])
		%languages.set_item_metadata(i, localCode)
		
		if SaveManager.configData.has("other"):
			if SaveManager.configData["other"].has("language"):
				if localCode == SaveManager.configData["other"]["language"]:
					%languages.selected = i
			
	%languages.item_selected.connect(selectLanguage)
	%languages.item_selected.connect(%clickSound.play)
		

func selectLanguage(index):
	TranslationServer.set_locale(%languages.get_item_metadata(index))
	
	SaveManager.configData["other"]["language"] = %languages.get_item_metadata(index)
	
func toggleTutorials():
	GameManager.showTutorials = !GameManager.showTutorials
	
	SaveManager.configData["toggles"]["tutorials"] = GameManager.showTutorials

func toggleAutosaves():
	SaveManager.autosave = !SaveManager.autosave
	
	SaveManager.configData["toggles"]["autosave"] = SaveManager.autosave

func _music_changed(value: float):
	var index = AudioServer.get_bus_index("Music")
	var db_value = linear_to_db(value)
	AudioServer.set_bus_volume_db(index, db_value)
	
	SaveManager.configData["audio"]["music"] = db_value
	
func _sound_changed(value: float):
	var index = AudioServer.get_bus_index("SFX")
	var db_value = linear_to_db(value)
	AudioServer.set_bus_volume_db(index, db_value)
	
	SaveManager.configData["audio"]["sfx"] = db_value

#func _switchFullscreen(on: bool):
	#print("toggled")
	
