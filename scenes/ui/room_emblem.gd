class_name RoomEmblem
extends TextureRect
## The room's emblem on the pause menu's corner, GAME.md 8.1c: one thing from the room the menu was
## opened over, its chip or its pinball or its hard hat, drawn flat as a die-cut sticker and stuck
## on a little askew, so the House's menu says which of its tables it is standing on. The sticker
## is the map's own where it has one, [member ArenaLayout.emblem], or its room's,
## [member RoomLook.emblem], or else the House's chip; a menu with no room under it shows none.

const HOUSE := preload("res://assets/ui/emblems/house.svg")
## How big it is drawn, in pixels of the menu, and how far askew it is stuck on, in degrees.
const SIDE := 132.0
const TILT := -8.0


func _init() -> void:
	name = "RoomEmblem"
	custom_minimum_size = Vector2.ONE * SIDE
	size = custom_minimum_size
	pivot_offset = size * 0.5
	rotation_degrees = TILT
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# The sticker is drawn at twice its size, and smoothed down rather than sampled.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


## Shows the emblem of the room [param arena] is built in, or nothing for no arena.
func show_for(arena: Arena) -> void:
	var room := arena.room if arena != null else null
	visible = room != null
	if room == null:
		texture = null
		return
	var own: Texture2D = arena.layout.emblem if arena.layout != null else null
	if own != null:
		texture = own
	else:
		texture = room.emblem if room.emblem != null else HOUSE
