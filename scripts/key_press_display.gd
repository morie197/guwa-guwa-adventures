extends Control

@onready var h_box_container = $HBoxContainer

func setData(keyData: Array[Texture2D], text: String, type: String):
	if !text.match(""):
		_addText(text)
	if type.match("triangle"):
		var vbox = VBoxContainer.new()
		h_box_container.add_child(vbox)
		_addImage(keyData[0], vbox)
		keyData.erase(keyData[0])
		
		var hbox = HBoxContainer.new()
		vbox.add_child(hbox)
		for image in keyData:
			_addImage(image, hbox)
	elif type.match("or1"):
		_addImage(keyData[0])
		keyData.erase(keyData[0])
		
		_addText(" / ")
		
		for image in keyData:
			_addImage(image)
	else:
		for image in keyData:
			_addImage(image)
		
func _addImage(image: Texture2D, target = h_box_container):
	var tr = TextureRect.new()
	tr.texture = image
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	target.add_child(tr)
	
func _addText(text: String, target = h_box_container):
	var richText = RichTextLabel.new()
	target.add_child(richText)
	richText.text = text
	richText.fit_content = true
	richText.horizontal_alignment =HORIZONTAL_ALIGNMENT_CENTER
	richText.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	richText.autowrap_mode = 0
	richText.add_theme_font_size_override("normal_font_size", 64)
		
	
