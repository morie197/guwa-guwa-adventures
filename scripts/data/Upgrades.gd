extends Node
class_name UpgradeData

const UPGRADES = {
	"range": {
		"levels": 20,
		"percentIncrease": 5,
		"description": "Increases quack, sonar, and zoom out range."
	},
	"endurance": {
		"levels": 20,
		"percentIncrease": 5,
		"description": "+1 HP every 2 levels, " + "+5%" + " stamina recovery."
	},
	"speed": {
		"levels": 20,
		"percentIncrease": 3,
		"description": "Increases player speed."
	}
	
}

const POSTGAMEUPGRADES = {
	"resistance": {
		"levels": 10,
		"percentIncrease": 10,
		"description": "+1 HP and +10% stamina."
	},
	"reach": {
		"levels": 10,
		"percentIncrease": 20,
		"description": "Increases hidden area visibility by 5%, player light radius by 20%, and attack range by 10%."
	},
	"power": {
		"levels": 10,
		"percentIncrease": 5,
		"description": "Increases speed by 5%, +1 ATK per 5 levels."
	}
	
}
