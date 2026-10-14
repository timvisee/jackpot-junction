class_name DieLine
extends Control
## A card the profile has never taken, in the catalog's press proof, GAME.md 8.8: not printed yet,
## only the line its die would cut it along, dashed in the die's magenta round the card's own size
## and round corners, and a faint question mark where its face would be, see [method
## ProofArt.die_line]. It says neither what the card is nor what kind nor how rare. It holds a
## card's place in the grid, the size of a [JokerCard].


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = JokerCard.SIZE
	size = JokerCard.SIZE


func _draw() -> void:
	ProofArt.die_line(self, Rect2(Vector2.ZERO, JokerCard.SIZE))
