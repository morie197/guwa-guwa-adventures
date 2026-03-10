extends RichTextLabel

var originalText: String = "For taking the time to play and beat my game!
Any feedback, negative or positive is welcome!"

func _ready():
	if GameManager.worldManager.levelName == "Hidden Grove":
		text = tr("CREDITS_YOU_DESCRIPTION_FULL")
