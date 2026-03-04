extends RichTextLabel

var originalText: String = "For taking the time to play and beat my game!
Any feedback, negative or positive is welcome!"

func _ready():
	if GameManager.worldManager.levelName == "Hidden Grove":
		text = "For taking the time to play and [color=blue]100%[/color] my game!
Any feedback, negative or positive is welcome!"
