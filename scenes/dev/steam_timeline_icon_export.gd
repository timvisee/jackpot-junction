extends Node
## Writes the game's own icons for the timeline of Steam's game recording, GAME.md 10.8, and quits,
## which is what `make steam-timeline-icons` runs: each of [constant Timeline.OWN_ICONS] as an SVG,
## white on nothing, as Steam's own are, [constant SIZE] units square and named as the game calls
## it, into `build/steam-timeline-icons/`, emptied first, for uploading by hand on Steamworks,
## docs/STEAM.md. The pictures are the game's own drawings of GAME.md 8.3a, the suits, three of the
## slot machines' sevens and the table card of the suits and hands, printed flat as [IconPress]
## prints them, each drawing nested in the icon's square; this is the one place they become files.
##
## Vectors all the way: nothing is drawn on a screen, so it runs headless.

const OUT := "res://build/steam-timeline-icons"
const SIZE := 256
## How far in from the square's edge a picture keeps, and how big each suit of the four is.
const MARGIN := 0.06
const SUIT := 0.44
## The drawings of the three sevens and of a hand of cards, see [method placed].
const SEVENS := &"timeline_777"
const HAND := &"table_suits_and_hands"
const HEAD := '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d">'


func _ready() -> void:
	var folder := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(folder)
	var ignored := OUT.get_base_dir().path_join(".gdignore")
	if not FileAccess.file_exists(ignored):
		FileAccess.open(ignored, FileAccess.WRITE).close()
	for old: String in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(old))
	for icon: String in Timeline.OWN_ICONS:
		var path := OUT.path_join(icon + ".svg")
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			push_error("could not write %s" % path)
			continue
		file.store_string(svg_of(icon))
		file.close()
	print("timeline icons: %d into %s" % [Timeline.OWN_ICONS.size(), OUT])
	get_tree().quit()


## The whole of timeline icon [param icon] as SVG text: a [constant SIZE] square holding its
## drawings, white, see [method placed].
static func svg_of(icon: String) -> String:
	var inner := PackedStringArray()
	var box := Rect2(Vector2.ZERO, Vector2.ONE * SIZE).grow(-SIZE * MARGIN)
	var placed_drawings := placed(icon, box)
	for i: int in placed_drawings.size():
		var id: StringName = placed_drawings[i][0]
		var at: Rect2 = placed_drawings[i][1]
		inner.append(_nested(IconPress.flat_svg(id, Color.WHITE), at, "d%d-" % i))
	return HEAD % [SIZE, SIZE, SIZE, SIZE] + "".join(inner) + "</svg>\n"


## Which drawings timeline icon [param icon] is made of and where in [param box] each goes: the four
## suits two by two, the game's three sevens, or the table card of the suits and hands.
static func placed(icon: String, box: Rect2) -> Array:
	match icon:
		"jj_royal_flush":
			var side := box.size * SUIT
			var suits := []
			for suit: int in JokerSuits.PICTURES.size():
				var at := box.position + Vector2(suit % 2, suit / 2) * (box.size - side)
				suits.append([JokerSuits.PICTURES[suit], Rect2(at, side)])
			return suits
		"jj_777":
			return [[SEVENS, box]]
		"jj_cards":
			return [[HAND, box]]
	push_error("no picture for the timeline icon %s" % icon)
	return []


## [param svg], a drawing's own SVG on its 48-unit grid, as a group laid over [param at] of the
## icon's square, moved and scaled rather than nested as an SVG of its own, which not every renderer
## draws; every id in it and every reference to one given [param prefix], so the drawings side by
## side never take each other's masks.
static func _nested(svg: String, at: Rect2, prefix: String) -> String:
	var body := svg.substr(svg.find(">") + 1)
	body = body.substr(0, body.rfind("</svg>"))
	body = body.replace('id="', 'id="%s' % prefix).replace("url(#", "url(#%s" % prefix)
	var scale := snappedf(at.size.x / IconPress.GRID, 0.0001)
	var x := snappedf(at.position.x, 0.01)
	var y := snappedf(at.position.y, 0.01)
	return '<g transform="translate(%s %s) scale(%s)">%s</g>' % [x, y, scale, body]
