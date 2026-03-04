extends Node
class_name UpgradeData

const UPGRADES = {
	"range": {
		"levels": 20,
		"percentIncrease": 5,
		"description": "Increases quack, sonar, map reveal, and zoom out range."
	},
	"endurance": {
		"levels": 20,
		"percentIncrease": 5,
		"description": "+1 max HP every 2 levels, " + "+5%" + " stamina recovery."
	},
	"speed": {
		"levels": 20,
		"percentIncrease": 3,
		"description": "Increases player movement and attack speed."
	}
	
}

const POSTGAMEUPGRADES = {
	"resistance": {
		"levels": 10,
		"percentIncrease": 10,
		"description": "+1 max HP and +10% max stamina."
	},
	"reach": {
		"levels": 10,
		"percentIncrease": 20,
		"description": "Increases map reveal range by 1 tile, player light radius by 20%, and attack range by 10%."
	},
	"power": {
		"levels": 10,
		"percentIncrease": 5,
		"description": "Increases speed by 5%, +1 ATK per 5 levels."
	}
	
}
