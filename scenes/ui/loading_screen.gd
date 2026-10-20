class_name LoadingScreen
extends CanvasLayer
## What is on the screen while a map is being put up, GAME.md 8.6: the house's engraved stock, a
## hand of cards fanned face down over the room's name in foil capitals, in the back the player
## wears, 8.9, a slow wave running through them all the while so the screen is seen to be alive,
## one of them slid out as the room nears up and turned over to the House's face as it is up, the
## room's sticker stuck on it, and a lane whose center line is painted gold as the room goes up,
## GAME.md 8.1a.
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
## How big the cards fanned over the name are against a [JokerCard], and the House's face the one
## slid out turns over to: its seal in foil on black, as the Final Hand's invitation's back has
## it.
const CARD_SCALE := 0.7
const FACE_SEAL := 0.62
## How wide the room's sticker on the face is, against the card's width.
const STICKER := 0.78
## The fan: how many cards, how far apart their middles are, how far each leans from the next and
## how much lower the outer ones stand, as a hand held; and the wave through it, how high a card
## rises, how long a wave takes, and how far behind the one before each card rises.
const FAN := 5
const FAN_STEP := 40.0
const FAN_TILT := 7.0
const FAN_DROP := 3.0
## How far clear of the room's name the lowest corner of the hand keeps.
const FAN_CLEAR := 24.0
## A card of the hand, any one, slid up out of it as the room nears up, over the others and clear
## of them to be turned over: from how far along the bar it starts, how far up it goes, as a share
## of its height, and how long it takes, eased in and out, in its own time rather than a phase's
## so it slides smoothly whatever the phases take; the wave lets it go as it rises.
const SLIDE_FROM := 0.7
const SLIDE_OUT := 0.45
const SLIDE_TIME := 0.25
const WAVE_RISE := 12.0
const WAVE_SECONDS := 1.4
const WAVE_LAG := 0.55
## What the toasts of GAME.md 8.10 wait for to be gone: an achievement earned as a room goes up
## comes up once it is up, rather than unseen under this.
const GROUP := &"loading_screens"

## The House's face of the card, drawn once a run, see [method _deal].
static var _house_face: Texture2D

var room_name := ""
## A line under the room's name, the room itself when the heading is the Final Hand's,
## STORY.md 6.5.
var room_under := ""
## The room's emblem, stuck a little askew on the House's face of the card that turns over, so the
## card says which table is going up, see [RoomEmblem]; none on a screen for no room.
var sticker: Texture2D

var _bar: ProgressBar
var _phase: Label
## The cards fanned over the name, the one to turn's back and its face, see [method _turn_to], and
## how far the wave through them has gone: each a picture drawn once a run rather than a card's
## engraving drawn again every frame, see [method _deal].
var _cards: Array[Control] = []
var _rests: Array[Vector2] = []
var _card: Control
var _back: TextureRect
var _face: TextureRect
var _wave := 0.0
var _slid := 0.0
## How long the card to turn has been sliding out, or less than nothing before it starts.
var _sliding := -1.0


## Puts [param match_node]'s room up a phase at a time with a loading screen over [param parent]
## saying [param named], and comes back once it is up. Every room is put up this way, the maps and
## the rooms between them alike: the Garage, the test track and the waiting room, GAME.md 8.6.
static func put_up(parent: Node, match_node: Match, named: String) -> void:
	var arena := match_node.prepare_arena(true)
	# The Final Hand is headed as the House heads it, the room's name under it, STORY.md 6.5.
	var heading := StoryLines.FINAL_HAND if arena.final_hand else named
	var screen := add_to(parent, heading, RoomEmblem.of(arena))
	if arena.final_hand:
		screen.room_under = named
	await screen.run(arena.build_steps(), building(arena.final_hand))


## The line under the bar: what is being built and, as the story goes, who for, STORY.md 6.5.
static func building(final_hand := false) -> String:
	if final_hand:
		return StoryLines.LOADING_FINAL_HAND
	return str(StoryLines.at(StoryLines.LOADING, Story.stage_here(), "Building the room"))


## Puts a loading screen up over [param parent] for the room called [param room], its card turning
## over to [param sticker] stuck on the House's face where it is given.
static func add_to(parent: Node, room: String, sticker: Texture2D = null) -> LoadingScreen:
	var screen := LoadingScreen.new()
	screen.name = "LoadingScreen"
	screen.room_name = room
	screen.sticker = sticker
	screen.layer = LAYER
	parent.add_child(screen)
	return screen


func _ready() -> void:
	add_to_group(GROUP)
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
		if _bar.value >= SLIDE_FROM:
			_slide_out()
		Events.room_building.emit(_bar.value)
		await get_tree().process_frame
	# Up: the card, slid all the way out, turns over while the full bar is seen.
	_slide_out()
	while _slid < 1.0:
		await get_tree().process_frame
	var turning := create_tween()
	turning.tween_method(_turn_to, 0.0, 1.0, LINGER)
	await turning.finished
	queue_free()


## The hand fanned over the room's name, face down in the back worn: [constant FAN] cards
## [constant CARD_SCALE] of a card's size, each turning about the middle of its foot, any one of
## them to turn over. Their backs and its face are pictures, see [method CardBack.picture], drawn
## once a run and shown from then on: the back by the title already, and the face the first time
## a room goes up.
func _deal() -> Control:
	var tall := JokerCard.SIZE.y * CARD_SCALE
	var room := Control.new()
	room.name = "Dealt"
	# Down past the middle one's foot reach the outer cards, standing lower and tipped out, their
	# outer corners lowest of all.
	var outer := float(FAN - 1) * 0.5
	var tip := JokerCard.SIZE.x * CARD_SCALE * 0.5 * sin(deg_to_rad(FAN_TILT * outer))
	var below := FAN_DROP * outer * outer + tip + FAN_CLEAR
	room.custom_minimum_size = Vector2(
		FAN_STEP * float(FAN - 1) + JokerCard.SIZE.x * CARD_SCALE * 1.4,
		tall * (1.0 + SLIDE_OUT) + WAVE_RISE + below
	)
	room.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var foot := Vector2(room.custom_minimum_size.x * 0.5, room.custom_minimum_size.y - below)
	var backs: Array[TextureRect] = []
	for i: int in FAN:
		var out := float(i) - float(FAN - 1) * 0.5
		var card := Control.new()
		card.size = JokerCard.SIZE
		card.pivot_offset = Vector2(JokerCard.SIZE.x * 0.5, JokerCard.SIZE.y)
		card.scale = Vector2.ONE * CARD_SCALE
		card.rotation = deg_to_rad(FAN_TILT * out)
		# Each over the one before, as a hand held lies.
		card.z_index = i
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rest := foot + Vector2(FAN_STEP * out, FAN_DROP * out * out) - card.pivot_offset
		card.position = rest
		room.add_child(card)
		_cards.append(card)
		_rests.append(rest)
		backs.append(_side(card, "Back"))
	# A card of the hand, any one, to slide out of it and turn over, see [method _slide_out].
	var drawn := randi() % FAN
	_card = _cards[drawn]
	_back = backs[drawn]
	_face = _side(_card, "Face")
	_face.visible = false
	if sticker != null:
		_stick_on(_face)
	CardBack.picture(
		CardBack.worn(),
		self,
		func(drawn: Texture2D) -> void:
			for back: TextureRect in backs:
				back.texture = drawn
	)
	if _house_face != null:
		_face.texture = _house_face
	else:
		var sheet := Control.new()
		var scaled := Node2D.new()
		scaled.scale = Vector2.ONE * CardBack.PICTURE_SCALE
		sheet.add_child(scaled)
		var face := Control.new()
		face.size = JokerCard.SIZE
		face.draw.connect(_draw_face.bind(face))
		scaled.add_child(face)
		var pixels := Vector2i(JokerCard.SIZE * CardBack.PICTURE_SCALE)
		DrawnTexture.kept(self, sheet, pixels, _keep_face)
	return room


## The wave through the hand: each card rising and settling in turn, a little after the one before,
## and on round again, whatever the room is doing.
func _process(delta: float) -> void:
	_wave += delta / WAVE_SECONDS
	if _sliding >= 0.0:
		_sliding += delta
		_slid = smoothstep(0.0, 1.0, minf(_sliding / SLIDE_TIME, 1.0))
	for i: int in _cards.size():
		var rise := maxf(sin((_wave - float(i) * WAVE_LAG / float(FAN)) * TAU), 0.0)
		var up := WAVE_RISE * rise * rise
		if _cards[i] == _card:
			# Let go of by the wave as it slides out, held still once it is.
			up = up * (1.0 - _slid) + JokerCard.SIZE.y * CARD_SCALE * SLIDE_OUT * _slid
		_cards[i].position = _rests[i] - Vector2(0.0, up)


## The card to turn starting to slide out of the hand, over the others; once only.
func _slide_out() -> void:
	if _sliding >= 0.0:
		return
	_sliding = 0.0
	_card.z_index = FAN


## One side of [param card], the size of a card, its picture shrunk to fit.
func _side(card: Control, named: String) -> TextureRect:
	var side := TextureRect.new()
	side.name = named
	side.size = JokerCard.SIZE
	side.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	side.stretch_mode = TextureRect.STRETCH_SCALE
	side.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(side)
	return side


func _keep_face(drawn: Texture2D) -> void:
	_house_face = drawn
	_face.texture = drawn


## The room's sticker over the seal in the middle of [param face], askew as the pause menu's is.
func _stick_on(face: Control) -> void:
	var stuck := TextureRect.new()
	stuck.name = "Sticker"
	stuck.texture = sticker
	stuck.size = Vector2.ONE * JokerCard.SIZE.x * STICKER
	stuck.position = (JokerCard.SIZE - stuck.size) * 0.5
	stuck.pivot_offset = stuck.size * 0.5
	stuck.rotation_degrees = RoomEmblem.TILT
	stuck.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stuck.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stuck.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	stuck.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.add_child(stuck)


## The card [param turned] of the way over: edge-on half way, its back before and its face after.
func _turn_to(turned: float) -> void:
	_card.scale.x = CARD_SCALE * maxf(absf(cos(turned * PI)), 0.02)
	_back.visible = turned < 0.5
	_face.visible = turned >= 0.5


## The House's face of the card, on [param on]: black edged in foil, the seal in foil in its middle.
static func _draw_face(on: Control) -> void:
	var look := StyleBoxFlat.new()
	look.bg_color = InvitationCard.CARD
	look.border_color = HouseTheme.FOIL
	look.set_border_width_all(3)
	look.set_corner_radius_all(10)
	on.draw_style_box(look, Rect2(Vector2.ZERO, JokerCard.SIZE))
	InvitationCard.draw_seal(on, JokerCard.SIZE * 0.5, FACE_SEAL, true)


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
