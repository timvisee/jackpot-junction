class_name LoadingScreen
extends CanvasLayer
## What is on the screen while a map is being put up, GAME.md 8.6: the house's engraved stock, a
## card dealt face down over the room's name in foil capitals, in the back the player wears, 8.9,
## turned over to the House's face as the room is up, and a lane whose center line is painted gold
## as the room goes up, GAME.md 8.1a.
##
## A room takes about a sixth of a second to build and bake, which is ten frames of nothing
## happening if it is done while the last screen is still up. So it is done a phase at a time
## with this over the top: the name of the room, a bar, and the phase it is on.
##
## The bar is the real thing rather than an animation. It moves when a phase finishes, and the
## phases are the ones in [method Arena.build_steps], so a room that takes longer to build shows
## a bar that takes longer to fill rather than one that lies faster.

## What a room is put up in front of, and what anything said while one is on its way is said on,
## so the words and the loading screen after them are one dark screen rather than two.
const BACKDROP := Color(0.04, 0.04, 0.05)
## Over everything, including the match's own HUD.
const LAYER := 100
## How long the screen stays up after the last phase, so the bar is seen full rather than seen
## to vanish at nine tenths.
const LINGER := 0.12
## How long and how tall the lane is.
const LANE := Vector2(460.0, 24.0)
## How big the card dealt over the name is against a [JokerCard], and the House's face it turns
## over to: its seal in foil on black, as the Final Hand's invitation's back has it.
const CARD_SCALE := 0.7
const FACE_SEAL := 0.62

var room_name := ""
## A line under the room's name, the room itself when the heading is the Final Hand's,
## STORY.md 6.5.
var room_under := ""

var _bar: ProgressBar
var _phase: Label
## The card dealt over the name, its back and its face, see [method _turn_to].
var _card: Control
var _back: CardBack
var _face: Control


## Puts [param match_node]'s room up a phase at a time with a loading screen over [param parent]
## saying [param named], and comes back once it is up. Every room is put up this way, the maps and
## the rooms between them alike: the Garage, the test track and the waiting room, GAME.md 8.6.
static func put_up(parent: Node, match_node: Match, named: String) -> void:
	var arena := match_node.prepare_arena(true)
	# The Final Hand is headed as the House heads it, the room's name under it, STORY.md 6.5.
	var screen := add_to(parent, StoryLines.FINAL_HAND if arena.final_hand else named)
	if arena.final_hand:
		screen.room_under = named
	await screen.run(arena.build_steps(), building(arena.final_hand))


## The line under the bar: what is being built and, as the story goes, who for, STORY.md 6.5.
static func building(final_hand := false) -> String:
	if final_hand:
		return StoryLines.LOADING_FINAL_HAND
	return str(StoryLines.at(StoryLines.LOADING, Story.stage_here(), "Building the room"))


## Puts a loading screen up over [param parent] for the room called [param room].
static func add_to(parent: Node, room: String) -> LoadingScreen:
	var screen := LoadingScreen.new()
	screen.name = "LoadingScreen"
	screen.room_name = room
	screen.layer = LAYER
	parent.add_child(screen)
	return screen


func _ready() -> void:
	var back := Backdrop.new()
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.add_theme_constant_override("separation", 14)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(column)
	column.add_child(_deal())
	column.add_child(MenuTheme.title(room_name, Type.TITLE))
	if not room_under.is_empty():
		column.add_child(MenuTheme.subtitle(room_under, Type.BODY))
	_bar = bar()
	column.add_child(_bar)
	_phase = Label.new()
	_phase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Type.text(_phase, Type.LABEL, Color(0.66, 0.66, 0.72))
	column.add_child(_phase)


## Runs [param steps] one to a frame with the bar following them, and takes the screen down after
## the last one. Awaited by whoever is loading the map.
func run(steps: Array[Callable], label: String) -> void:
	_phase.text = label
	# Two frames before the first phase: one for this to be laid out, one for it to be drawn.
	# Otherwise the first thing on the screen is the frame the room was built in.
	await get_tree().process_frame
	await get_tree().process_frame
	for i: int in steps.size():
		steps[i].call()
		_bar.value = float(i + 1) / float(steps.size())
		Events.room_building.emit(_bar.value)
		await get_tree().process_frame
	# Up: the card turns over while the full bar is seen.
	var turning := create_tween()
	turning.tween_method(_turn_to, 0.0, 1.0, LINGER)
	await turning.finished
	queue_free()


## The card dealt over the room's name, face down in the back worn: as big as [constant CARD_SCALE]
## of a card, turned about its middle.
func _deal() -> Control:
	var room := Control.new()
	room.name = "Dealt"
	room.custom_minimum_size = JokerCard.SIZE * CARD_SCALE
	room.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card = Control.new()
	_card.size = JokerCard.SIZE
	_card.pivot_offset = JokerCard.SIZE * 0.5
	_card.position = (JokerCard.SIZE * CARD_SCALE - JokerCard.SIZE) * 0.5
	_card.scale = Vector2.ONE * CARD_SCALE
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room.add_child(_card)
	_back = CardBack.new(-1, false)
	_back.name = "Back"
	_card.add_child(_back)
	_face = Control.new()
	_face.name = "Face"
	_face.size = JokerCard.SIZE
	_face.visible = false
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.draw.connect(_draw_face)
	_card.add_child(_face)
	return room


## The card [param turned] of the way over: edge-on half way, its back before and its face after.
func _turn_to(turned: float) -> void:
	_card.scale.x = CARD_SCALE * maxf(absf(cos(turned * PI)), 0.02)
	_back.visible = turned < 0.5
	_face.visible = turned >= 0.5


## The House's face of the card: black edged in foil, the seal in foil in its middle.
func _draw_face() -> void:
	var look := StyleBoxFlat.new()
	look.bg_color = InvitationCard.CARD
	look.border_color = HouseTheme.FOIL
	look.set_border_width_all(3)
	look.set_corner_radius_all(10)
	_face.draw_style_box(look, Rect2(Vector2.ZERO, JokerCard.SIZE))
	InvitationCard.draw_seal(_face, JokerCard.SIZE * 0.5, FACE_SEAL, true)


## The bar a room fills as it is put up, from 0 to 1: the one on this screen, and the one a player
## watches while a dedicated server makes them a game, GAME.md 9.3a. A lane, see
## [method LaneStyle.road_and_paint].
static func bar() -> ProgressBar:
	var made := ProgressBar.new()
	made.custom_minimum_size = Vector2(LANE.x, LANE.y)
	made.max_value = 1.0
	made.value = 0.0
	made.show_percentage = false
	var looks := LaneStyle.road_and_paint()
	made.add_theme_stylebox_override("background", looks[0])
	made.add_theme_stylebox_override("fill", looks[1])
	return made
