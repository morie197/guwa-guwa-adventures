extends PanelContainer

@onready var back_button = $menu/VBoxContainer/HBoxContainer/backButton
@onready var music_slider = $menu/VBoxContainer/music/musicSlider
@onready var sound_slider = $menu/VBoxContainer/sounds/soundSlider

func _ready():
	music_slider.value_changed.connect(_music_changed)
	sound_slider.value_changed.connect(_sound_changed)
	back_button.pressed.connect(queue_free)
	
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
	sound_slider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))

func _music_changed(value: float):
	var index = AudioServer.get_bus_index("Music")
	var db_value = linear_to_db(value)
	AudioServer.set_bus_volume_db(index, db_value)
	
func _sound_changed(value: float):
	var index = AudioServer.get_bus_index("SFX")
	var db_value = linear_to_db(value)
	AudioServer.set_bus_volume_db(index, db_value)
