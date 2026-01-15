extends Control

const KEYSPRITE = preload("uid://b66rrw7uw1r70")

@onready var _1 = $"1"
@onready var _2 = $"2"
@onready var _3 = $"3"
@onready var _4 = $"4"
@onready var _5 = $"5"
@onready var _6 = $"6"

var keyImages

@onready var key_1 = $"1/key1"
@onready var key_2 = $"2/key2"
@onready var key_3 = $"3/key3"
@onready var key_4 = $"4/key4"
@onready var key_5 = $"5/key5"
@onready var key_6 = $"6/key6"

var keyText

func setData(keyData: Dictionary[int, String]):
	print(keyData)
	keyImages= [_1, _2, _3, _4, _5, _6]
	keyText = [key_1, key_2, key_3, key_4, key_5, key_6]
	for image in keyImages:
		image.texture = null
	
	for text in keyText:
		text.text = ""
	
	for d in keyData:
		keyImages[d-1].texture = KEYSPRITE
		keyText[d-1].text = keyData[d]
	
