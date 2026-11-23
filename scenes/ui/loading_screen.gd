class_name LoadingScreen
extends CanvasLayer
## What is on the screen while a map is being put up, GAME.md 8.6: the house's engraved stock, a
## hand of cards fanned face down over the room's name in foil capitals, in the back the player
## wears, 8.9, a slow wave running through them all the while so the screen is seen to be alive,
## one of them slid out as the room nears up and turned over to the House's face as it is up, the
## room's sticker stuck down in the corner, an edge of it folded back, and a lane whose center line
## is painted gold as the room goes up, GAME.md 8.1a.
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
## How far in from the screen's bottom right corner the room's sticker is stuck, in pixels, and how
## far askew, in degrees.
const STICKER_MARGIN := Vector2(28.0, 20.0)
const STICKER_TILT := -8.0
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
## The ink of the tag under the bar naming a card new to the player, GAME.md 8.6, and of its edge.
const NEW_INK := Color("#ff4fa3")

## The House's face of the card, drawn once a run, see [method _deal].
static var _house_face: Texture2D

## The match's cards, 3.17, the hand being the table's, or -1 for a room between the maps, whose
## hand is the House's, and whether they were dealt for the map by Roulette.
var table := -1
var dealt := false

var room_name := ""
## A line under the room's name, the room itself when the heading is the Final Hand's,
## STORY.md 6.5.
var room_under := ""
## The room's emblem, stuck a little askew in the corner as a sticker for as long as the screen is
## up, so it says which table is going up, see [PeelSticker]; none on a screen for no room.
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
## For a match, each card of the table in the hand, its face and its back, which are turned up as
## the bar passes its share, see [method _turn_up]; and the card new to the player, slid out, with
## the tag that names it under the bar, or -1 and null for none.
var _table_cards: Array[int] = []
var _faces: Array[Control] = []
var _backs: Array[TextureRect] = []
var _up: Array[bool] = []
var _new_card := -1
var _new_tag: Control
## How long the card to turn has been sliding out, or less than nothing before it starts.
var _sliding := -1.0


## Puts [param match_node]'s room up a phase at a time with a loading screen over [param parent]
## saying [param named], and comes back once it is up. Every room is put up this way, the maps and
## the rooms between them alike: the Garage, the test track and the waiting room, GAME.md 8.6.
## With [param a_match] the hand is the table's cards, 3.17, turned up as the room goes up.
static func put_up(parent: Node, match_node: Match, named: String, a_match := false) -> void:
	var arena := match_node.prepare_arena(true)
	# The Final Hand is headed as the House heads it, the room's name under it, STORY.md 6.5.
	var heading := StoryLines.FINAL_HAND if arena.final_hand else named
	var screen := LoadingScreen.new()
	if a_match and not arena.final_hand:
		screen.table = match_node.rules.table
		screen.dealt = match_node.rules.dealt
	screen = add_to(parent, heading, RoomEmblem.of(arena), screen)
	if arena.final_hand:
		screen.room_under = named
	await screen.run(arena.build_steps(), building(arena.final_hand))


## The line under the bar: what is being built and, as the story goes, who for, STORY.md 6.5.
static func building(final_hand := false) -> String:
	if final_hand:
		return StoryLines.LOADING_FINAL_HAND
	return str(StoryLines.at(StoryLines.LOADING, Story.stage_here(), "Building the room"))


## Puts a loading screen up over [param parent] for the room called [param room], with
## [param sticker] stuck down in the corner where it is given.
static func add_to(
	parent: Node, room: String, sticker: Texture2D = null, screen: LoadingScreen = null
) -> LoadingScreen:
	if screen == null:
		screen = LoadingScreen.new()
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
	if table >= 0:
		var tonight := Label.new()
		tonight.text = "TONIGHT'S DEAL" if dealt else "TONIGHT'S TABLE"
		tonight.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Type.display(tonight, Type.LABEL, HouseTheme.FOIL)
		column.add_child(tonight)
	column.add_child(_deal())
	if sticker != null:
		_stick_down()
	column.add_child(MenuTheme.title(room_name, Type.TITLE))
	var table := _table_number()
	if not table.is_empty():
		column.add_child(MenuTheme.title("No. " + table, Type.BODY))
	if not room_under.is_empty():
		column.add_child(MenuTheme.subtitle(room_under, Type.BODY))
	_bar = bar()
	column.add_child(_bar)
	_phase = Label.new()
	_phase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Type.text(_phase, Type.LABEL, Color(0.66, 0.66, 0.72))
	column.add_child(_phase)
	if _new_card >= 0:
		_new_tag = _tag_of(_new_card)
		column.add_child(_new_tag)


## The room's table number for the loading screen, one of the millions the House runs, once the
## directory note of STORY.md 7.3 has shown there are that many, see [constant
## StoryNotes.TABLE_DIRECTORY]; empty before it is found, or for a screen that is not a table of the
## House. Steady for a room, taken from its name, so a table keeps its number.
func _table_number() -> String:
	if sticker == null or Game.settings == null or Game.settings.profile == null:
		return ""
	if not Game.settings.profile.story.has_note(StoryNotes.TABLE_DIRECTORY):
		return ""
	return _grouped(absi(hash(room_name)) % 99_000_000 + 1_000_000)


## [param number] with a comma every three digits, the way the House prints its big ones.
static func _grouped(number: int) -> String:
	var digits := str(number)
	var out := ""
	for i: int in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			out += ","
		out += digits[i]
	return out


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
		_turn_up(_bar.value)
		if _bar.value >= SLIDE_FROM and _card != null:
			_slide_out()
		Events.room_building.emit(_bar.value)
		await get_tree().process_frame
	if table >= 0:
		# Up: every card of the table face up, the new one slid out and named, a moment to be read.
		_turn_up(1.0)
		if _card != null:
			_slide_out()
			while _slid < 1.0:
				await get_tree().process_frame
		await get_tree().create_timer(LINGER * (6.0 if _new_tag != null else 2.0)).timeout
		queue_free()
		return
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
	if table >= 0:
		_table_cards = TableCards.cards_of(table)
		var fresh := Game.settings.profile.table.fresh & table if Game.settings != null else 0
		var news := TableCards.cards_of(fresh)
		_new_card = news[0] if not news.is_empty() else -1
	var count := _hand()
	var tall := JokerCard.SIZE.y * CARD_SCALE
	var room := Control.new()
	room.name = "Dealt"
	# Down past the middle one's foot reach the outer cards, standing lower and tipped out, their
	# outer corners lowest of all.
	var outer := float(count - 1) * 0.5
	var tip := JokerCard.SIZE.x * CARD_SCALE * 0.5 * sin(deg_to_rad(FAN_TILT * outer))
	var below := FAN_DROP * outer * outer + tip + FAN_CLEAR
	room.custom_minimum_size = Vector2(
		_step() * float(count - 1) + JokerCard.SIZE.x * CARD_SCALE * 1.4,
		tall * (1.0 + SLIDE_OUT) + WAVE_RISE + below
	)
	room.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	room.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var foot := Vector2(room.custom_minimum_size.x * 0.5, room.custom_minimum_size.y - below)
	var backs: Array[TextureRect] = []
	for i: int in count:
		var out := float(i) - float(count - 1) * 0.5
		var card := Control.new()
		card.size = JokerCard.SIZE
		card.pivot_offset = Vector2(JokerCard.SIZE.x * 0.5, JokerCard.SIZE.y)
		card.scale = Vector2.ONE * CARD_SCALE
		card.rotation = deg_to_rad(FAN_TILT * out)
		# Each over the one before, as a hand held lies.
		card.z_index = i
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var rest := foot + Vector2(_step() * out, FAN_DROP * out * out) - card.pivot_offset
		card.position = rest
		room.add_child(card)
		_cards.append(card)
		_rests.append(rest)
		backs.append(_side(card, "Back"))
	CardBack.picture(
		CardBack.worn(),
		self,
		func(drawn: Texture2D) -> void:
			for back: TextureRect in backs:
				back.texture = drawn
	)
	if table >= 0:
		_deal_table(backs)
		return room
	# A card of the hand, any one, to slide out of it and turn over, see [method _slide_out].
	var drawn := randi() % FAN
	_card = _cards[drawn]
	_back = backs[drawn]
	_face = _side(_card, "Face")
	_face.visible = false
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
		var rise := maxf(sin((_wave - float(i) * WAVE_LAG / float(_hand())) * TAU), 0.0)
		var up := WAVE_RISE * rise * rise
		if _cards[i] == _card:
			# Let go of by the wave as it slides out, held still once it is.
			up = up * (1.0 - _slid) + JokerCard.SIZE.y * CARD_SCALE * SLIDE_OUT * _slid
		_cards[i].position = _rests[i] - Vector2(0.0, up)


## The card to turn starting to slide out of the hand, over the others; once only.
func _slide_out() -> void:
	if _sliding >= 0.0 or _card == null:
		return
	_sliding = 0.0
	_card.z_index = _hand()


## How many cards the hand holds: the table's, or the House's [constant FAN].
func _hand() -> int:
	return maxi(_table_cards.size(), 1) if table >= 0 else FAN


## How far apart the cards' middles are: closer in a hand of more than the House's five.
func _step() -> float:
	return FAN_STEP * minf(1.0, float(FAN) / float(_hand()) * 1.4)


## The table's cards dealt into the hand, face down to start with, GAME.md 8.6: a face of each over
## its [param backs], and the card new to the player the one to slide out.
func _deal_table(backs: Array[TextureRect]) -> void:
	for i: int in _cards.size():
		var face := TableFace.new()
		face.name = "Face"
		face.card = _table_cards[i] if i < _table_cards.size() else 0
		face.size = JokerCard.SIZE
		face.visible = false
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		face.fresh = face.card == _new_card
		_cards[i].add_child(face)
		_faces.append(face)
		_up.append(false)
	_backs = backs
	var at := _table_cards.find(_new_card)
	_card = _cards[at] if at >= 0 else null


## The table's cards turned up as far as [param done] of the bar has gone, each at its share of it,
## left to right, GAME.md 8.6.
func _turn_up(done: float) -> void:
	for i: int in _faces.size():
		if _up[i] or done < float(i + 1) / float(_faces.size() + 1):
			continue
		_up[i] = true
		var card := _cards[i]
		var face := _faces[i]
		var back := _backs[i]
		var turning := create_tween()
		turning.tween_method(
			func(turned: float) -> void:
				card.scale.x = CARD_SCALE * maxf(absf(cos(turned * PI)), 0.02)
				back.visible = turned < 0.5
				face.visible = turned >= 0.5,
			0.0,
			1.0,
			LINGER
		)
	if _new_tag != null and done >= 1.0 and _new_tag.modulate.a <= 0.0:
		create_tween().tween_property(_new_tag, "modulate:a", 1.0, LINGER * 2.0)


## The tag under the bar naming [param card], new to the player, GAME.md 8.6, see [TableTag]:
## unseen until the room is up.
func _tag_of(card: int) -> Control:
	var tag := TableTag.make()
	tag.name = "NewCard"
	tag.show_card(card, TableTag.Chip.NEW)
	# In its place from the start, so nothing moves as it fades up once the room is.
	tag.modulate.a = 0.0
	ScreenReader.name(tag, "New: %s" % TableCards.NAMES[card], TableCards.LINES[card])
	return tag


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


## The room's sticker, stuck down on its own in the corner of the screen, a little askew, see
## [PeelSticker].
func _stick_down() -> void:
	var corner := Control.new()
	corner.name = "StickerCorner"
	corner.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	corner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(corner)
	var stuck := PeelSticker.new(sticker)
	stuck.position = -stuck.size - STICKER_MARGIN
	stuck.rotation_degrees = STICKER_TILT
	corner.add_child(stuck)


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


## A card of the table's face in the hand, the size of a card, GAME.md 8.6; edged in the neon's
## magenta where it is new to the player.
class TableFace:
	extends Control

	var card := 0
	var fresh := false

	func _draw() -> void:
		var box := Rect2(Vector2.ZERO, size)
		if fresh:
			var edge := StyleBoxFlat.new()
			edge.bg_color = LoadingScreen.NEW_INK
			edge.set_corner_radius_all(roundi(size.x * TableCardArt.CORNER) + 6)
			edge.anti_aliasing = true
			draw_style_box(edge, box.grow(7.0))
		TableCardArt.face(self, box, card)
