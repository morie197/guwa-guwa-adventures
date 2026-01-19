extends MarginContainer

@onready var namePlate = $VBoxContainer/name
@onready var hpbar = $VBoxContainer/hpbar

var infoOwner
var entityName: String = "Jerry"
			
var max_hp_value: int = 5:
	set(new_maxhp):
		max_hp_value = new_maxhp
		hpbar.max_value = max_hp_value

var hpValue: int = 5:
	set(new_hp):
		#print("updated panel")
		hpValue = new_hp
		namePlate.text = entityName + " " + str(hpValue) + "/" + str(max_hp_value)
		hpbar.value = hpValue
