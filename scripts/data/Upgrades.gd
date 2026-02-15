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
		"percentIncrease": 5,
		"description": "+1 HP, +5% stamina and resistance to stream/wind forces."
	},
	"visibility": {
		"levels": 10,
		"percentIncrease": 20,
		"description": "Increases hidden area visibility by 5% and player light radius by 20%."
	},
	"agility": {
		"levels": 10,
		"percentIncrease": 10,
		"description": "Increases swimming and flying speed by 10%."
	}
	
}
