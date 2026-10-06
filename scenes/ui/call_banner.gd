class_name CallBanner
extends Control
## The announcer's call, GAME.md 3.12 and 8.1a: the player's name and what they just did, under the
## middle of the screen where the eye already is, on a plate of the house's stock framed in their
## color, the name in it and the call in the house's foil capitals. It holds and then goes.
##
## Each kind of call is dressed in something of its own behind the plate, so it is known before it
## is read, see [enum Dress]: a run of kills fans out a hand of cards, a pair for a double up to a
## flush for a spree; a streak burns in the player's color, higher the hotter it is; an overtake
## runs out a band of chevrons; taking the lead a checkered flag; a trade wears the two-way traffic
## sign. Match point, the call that matters most, GAME.md 3.4, is run out on hazard tape behind its
## plate, a little askew, the way the moments that matter are.

enum Dress { PLATE, TAPE, CHECKERS, CHEVRONS, CARDS, FLAMES, TWO_WAY }

## How long a call holds, all told, and how much of that is the fade.
const HOLD := 2.2
const FADE := 0.6
## How big the call is set.
const SIZE := 44
## What each call is dressed in, and how many cards a run of kills fans out, and how hot a streak
## burns.
const DRESSES: Dictionary[String, Dress] = {
	"MATCH POINT": Dress.TAPE,
	"TAKING THE LEAD": Dress.CHECKERS,
	"OVERTAKE": Dress.CHEVRONS,
	"DOUBLE KILL": Dress.CARDS,
	"TRIPLE KILL": Dress.CARDS,
	"QUAD KILL": Dress.CARDS,
	"KILLING SPREE": Dress.CARDS,
	"HOT STREAK": Dress.FLAMES,
	"ON FIRE": Dress.FLAMES,
	"UNTOUCHABLE": Dress.FLAMES,
	"TRADE KILL": Dress.TWO_WAY,
}
const CARDS_FOR: Dictionary[String, int] = {
	"DOUBLE KILL": 2, "TRIPLE KILL": 3, "QUAD KILL": 4, "KILLING SPREE": 5
}
const HEAT_FOR: Dictionary[String, float] = {"HOT STREAK": 0.8, "ON FIRE": 1.1, "UNTOUCHABLE": 1.5}
## The bands behind the plate: how far they reach past it either side and above and below, how
## wide their stripes are, how far they lean, and the tape's two colors.
const TAPE_REACH := Vector2(44.0, 12.0)
const STRIPE := 16.0
const TAPE_TURN := -0.045
const TAPE_YELLOW := Color("#f6c42e")
const TAPE_BLACK := Color("#16151a")
## The checkered flag's squares, and the way it leans.
const CHECK := 14.0
const CHECK_TURN := 0.04
## The chevrons either side of the plate: how far out they reach, how many each side, how thick
## a chevron's stroke is, and how far apart two are.
const CHEVRON_REACH := Vector2(96.0, 0.0)
const CHEVRONS := 3
const CHEVRON_WIDTH := 7.0
const CHEVRON_GAP := 24.0
## The cards of a run: how big, how far apart they fan, and how much of each shows over the plate.
const CARD := Vector2(60.0, 84.0)
const CARD_FAN := 0.26
const CARD_SHOWS := 0.7
## The streak's fire rises off the plate's top edge, from a band this tall.
const FIRE_FOOT := 30.0
## The two-way sign, how big against the plate's height.
const SIGN_SHARE := 1.15

## What the call on show is dressed in.
var dress := Dress.PLATE

var _plate: PanelContainer
var _look: TicketStyle
var _who: Label
var _what: Label
## What is behind the plate, drawn for its dress.
var _behind: Control
var _flame: PotFlame
var _sign: RoadSign
var _cards := 0
var _ink := Color.WHITE
var _left := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_behind = Control.new()
	_behind.name = "Behind"
	_behind.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_behind.draw.connect(_draw_behind)
	add_child(_behind)
	_flame = PotFlame.in_ink(Color.WHITE, 3.1)
	_flame.name = "Flame"
	_flame.visible = false
	add_child(_flame)
	_plate = PanelContainer.new()
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_look = TicketStyle.cut(Color(HouseTheme.STOCK, 0.92), 10.0, 26.0, 12.0)
	_look.frame_inset = 5.0
	_look.shadow = 12.0
	Surface.wear(_look, "pane")
	_plate.add_theme_stylebox_override("panel", _look)
	add_child(_plate)
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override("separation", 16)
	_plate.add_child(line)
	_sign = RoadSign.of(RoadSign.Kind.TWO_WAY, SIZE * SIGN_SHARE)
	_sign.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_sign.visible = false
	line.add_child(_sign)
	_who = Label.new()
	Type.set_font(_who, Type.display_font(), SIZE)
	HudText.shadowed(_who, 2)
	_who.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(_who)
	_what = MenuTheme.title("", SIZE)
	_what.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(_what)
	_plate.resized.connect(_lay)


## Calls out [param call] for [param who], in [param color], dressed as [constant DRESSES] says;
## [param urgent] runs it out on hazard tape whatever it is.
func show_call(who: String, call: String, color: Color, urgent := false) -> void:
	_who.text = who
	_who.visible = not who.is_empty()
	_who.add_theme_color_override("font_color", color)
	_what.text = call
	dress = Dress.TAPE if urgent else DRESSES.get(call, Dress.PLATE)
	_ink = color
	_cards = CARDS_FOR.get(call, 0)
	_look.frame = Color(HouseTheme.FOIL if dress == Dress.TAPE else color, 0.7)
	_sign.visible = dress == Dress.TWO_WAY
	_flame.visible = dress == Dress.FLAMES
	if _flame.visible:
		PotFlame.dye(_flame, color)
		(_flame.material as ShaderMaterial).set_shader_parameter(&"heat", HEAT_FOR.get(call, 1.0))
	_behind.visible = dress != Dress.PLATE and dress != Dress.TWO_WAY and dress != Dress.FLAMES
	_left = HOLD
	modulate.a = 1.0
	visible = true
	_plate.reset_size()
	_lay()


## What the call says just now: the name and the call, two spaces apart.
func said() -> String:
	return _what.text if _who.text.is_empty() else "%s  %s" % [_who.text, _what.text]


## Takes the call down before its time.
func put_away() -> void:
	_left = 0.0
	visible = false


func _process(delta: float) -> void:
	if _left <= 0.0:
		return
	_left = maxf(_left - delta, 0.0)
	modulate.a = clampf(_left / FADE, 0.0, 1.0)
	visible = _left > 0.0


## The plate in the middle of the banner, and what is behind it.
func _lay() -> void:
	var plate := _plate.get_combined_minimum_size()
	_plate.size = plate
	_plate.position = -plate * 0.5
	var reach := TAPE_REACH
	var turn := 0.0
	match dress:
		Dress.TAPE:
			turn = TAPE_TURN
		Dress.CHECKERS:
			turn = CHECK_TURN
		Dress.CHEVRONS:
			reach = CHEVRON_REACH
		Dress.CARDS:
			reach = Vector2(0.0, CARD.y)
	var behind := plate + reach * 2.0
	_behind.size = behind
	_behind.position = -behind * 0.5
	_behind.pivot_offset = behind * 0.5
	_behind.rotation = turn
	_behind.queue_redraw()
	if _flame.visible:
		_flame.cover(Rect2(_plate.position, Vector2(plate.x, FIRE_FOOT)))


func _draw_behind() -> void:
	match dress:
		Dress.TAPE:
			_draw_tape(TAPE_YELLOW, TAPE_BLACK)
		Dress.CHECKERS:
			_draw_checkers()
		Dress.CHEVRONS:
			_draw_chevrons()
		Dress.CARDS:
			_draw_cards()


## Hazard tape: black stripes leaning across yellow.
func _draw_tape(ground: Color, stripes: Color) -> void:
	var size_of := _behind.size
	_behind.draw_rect(Rect2(Vector2.ZERO, size_of), ground)
	var band := PackedVector2Array(
		[Vector2.ZERO, Vector2(size_of.x, 0.0), size_of, Vector2(0.0, size_of.y)]
	)
	var x := -size_of.y
	while x < size_of.x:
		var stripe := PackedVector2Array(
			[
				Vector2(x, size_of.y),
				Vector2(x + size_of.y, 0.0),
				Vector2(x + size_of.y + STRIPE, 0.0),
				Vector2(x + STRIPE, size_of.y),
			]
		)
		for part: PackedVector2Array in Geometry2D.intersect_polygons(stripe, band):
			_behind.draw_colored_polygon(part, stripes)
		x += STRIPE * 2.0


## A checkered flag run out behind the plate: two rows of squares, black and white.
func _draw_checkers() -> void:
	var size_of := _behind.size
	_behind.draw_rect(Rect2(Vector2.ZERO, size_of), Color.WHITE)
	var rows := ceili(size_of.y / CHECK)
	var columns := ceili(size_of.x / CHECK)
	for row: int in rows:
		for column: int in columns:
			if (row + column) % 2 == 0:
				var square := Rect2(Vector2(column, row) * CHECK, Vector2.ONE * CHECK)
				_behind.draw_rect(square.intersection(Rect2(Vector2.ZERO, size_of)), TAPE_BLACK)


## Chevrons pointing on either side of the plate, the way a bend is signed: whole ones, in foil
## edged in black, the way the field is being passed.
func _draw_chevrons() -> void:
	var h := _behind.size.y
	var half := h * 0.32
	var plate := _plate.size.x
	var middle := _behind.size.x * 0.5
	for side: float in [-1.0, 1.0]:
		var start := middle + side * (plate * 0.5 + 14.0)
		for i: int in CHEVRONS:
			var x := start + side * CHEVRON_GAP * float(i)
			if side < 0.0:
				x -= half * 0.6
			var arrow := PackedVector2Array(
				[
					Vector2(x, h * 0.5 - half),
					Vector2(x + half * 0.6, h * 0.5),
					Vector2(x, h * 0.5 + half),
				]
			)
			_behind.draw_polyline(arrow, TAPE_BLACK, CHEVRON_WIDTH + 4.0, true)
			_behind.draw_polyline(arrow, HouseTheme.FOIL, CHEVRON_WIDTH, true)


## The hand a run of kills makes, fanned up out from behind the plate: a pair, three, four of a
## kind, and a whole flush for a spree, each card a suit in the player's color on cream.
func _draw_cards() -> void:
	# Fanned about a point under the plate's top edge, so each card stands up out from behind it.
	var top := _behind.size.y * 0.5 - _plate.size.y * 0.5
	var pivot := Vector2(_behind.size.x * 0.5, top + CARD.y * 0.6)
	for i: int in _cards:
		var lean := (float(i) - float(_cards - 1) * 0.5) * CARD_FAN
		var reach := CARD.y * (0.6 + CARD_SHOWS - 0.5)
		var at := pivot + Vector2(sin(lean), -cos(lean)) * reach
		_behind.draw_set_transform(at, lean)
		var face := StyleBoxFlat.new()
		face.bg_color = HouseTheme.PAPER
		face.set_corner_radius_all(6)
		face.set_border_width_all(2)
		face.border_color = Color(HouseTheme.INK, 0.6)
		face.shadow_color = Color(0.0, 0.0, 0.0, 0.4)
		face.shadow_size = 6
		face.anti_aliasing = true
		_behind.draw_style_box(face, Rect2(-CARD * 0.5, CARD))
		var pip := Vector2.ONE * CARD.x * 0.5
		var box := Rect2(Vector2(-pip.x * 0.5, -CARD.y * 0.36), pip)
		SuitArt.draw_into(_behind, box, i % 4, HouseTheme.on_paper(_ink), 0.0)
	_behind.draw_set_transform(Vector2.ZERO)
