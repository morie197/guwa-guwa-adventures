extends PanelContainer

@onready var back_button = $menu/VBoxContainer/HBoxContainer/backButton
@onready var music_slider = $menu/VBoxContainer/music/musicSlider
@onready var sound_slider = $menu/VBoxContainer/sounds/soundSlider

@onready var autosaves = $menu/VBoxContainer/HBoxContainer2/autosaves
@onready var fullscreen = $menu/VBoxContainer/HBoxContainer3/fullscreen

func _ready():
	music_slider.value_changed.connect(_music_changed)
	sound_slider.value_changed.connect(_sound_changed)
	back_button.pressed.connect(queue_free)
	back_button.pressed.connect(SaveManager.saveConfigData)
	
	if SaveManager.autosave == false:
		autosaves.button_pressed = false
	if GameManager.fullscreen == true:
		fullscreen.button_pressed = true
	
	autosaves.pressed.connect(toggleAutosaves)
	fullscreen.pressed.connect(GameManager.toggleFullscreen)
	
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
	sound_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))
	
	_localeButtonSetup()
	
func _localeButtonSetup():
	var nativeNames = {
		"en": "English",
		"ja": "日本語",
		"zh_CN": "简体中文",
		'zh_TW': "繁體中文"
	}
	
	var locales = TranslationServer.get_loaded_locales()
	
	for i in range(locales.size()):
		var localCode = locales[i]
		print(localCode)
		
		%languages.add_item(nativeNames[localCode])
		%languages.set_item_metadata(i, localCode)
		
		if SaveManager.configData.has("other"):
			if SaveManager.configData["other"].has("language"):
				if localCode == SaveManager.configData["other"]["language"]:
					%languages.selected = i
			
	%languages.item_selected.connect(selectLanguage)
		

func selectLanguage(index):
	TranslationServer.set_locale(%languages.get_item_metadata(index))
	
	SaveManager.configData["other"]["language"] = %languages.get_item_metadata(index)
	

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
	
