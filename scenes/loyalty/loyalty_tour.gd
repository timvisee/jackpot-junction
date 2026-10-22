class_name LoyaltyTour
extends Control
## The House showing a member round its map, GAME.md 8.9 "The first look": four steps on the map
## itself, over the loyalty program's dialog, see [LoyaltyDialog]. The welcome's two spotlights
## light what each step speaks of, the rest of the dialog dark under them, see the shade's shader;
## beside it a tag of the House's cream card says the step, see [TourTag], a thin red line run
## from it to what it speaks of.
##
## 1. You are here: the slip road's stamp comes down and its roads draw out, see [LoyaltyReveal].
## 2. Every match counts: the kart drives to the nearest open bet, its slip's parts named.
## 3. Pin one to track it: the slip's Pin lit, and a picture of what a pin gives, see [PinPicture].
## 4. The Jackpot: the map drawn back until all of it shows; Got it leaves it to the member.
##
## Accept, a click or a tap anywhere but on a button goes on, all but at the third step, which
## waits for its buttons; a press while a step's movement is under way brings it all at once. Skip
## tour, Back, B or Escape ends it at once. Nothing of the map takes input while it is up.

## Ended: gone through to its end, [param finished], or skipped.
signal ended(finished: bool)

enum Step { HERE, COUNTS, PIN, JACKPOT, DONE }

const STEPS := 4
## What each step's tag says, its heading and its line, the first's with the program's name by the
## story's stage, and the third's on a screen with no room for the strip by the clock.
const SAID: Array[Array] = [
	[
		"You are here",
		(
			"You activated your %s card, which won the first landmark's bet. Winning a bet opens"
			+ " the roads past it to new landmarks."
		),
	],
	[
		"Every match counts",
		(
			"Each landmark holds a bet and a reward. Every match you play counts toward all open"
			+ " bets at once, so there's no need to pick one."
		),
	],
	[
		"Pin one to track it",
		"Pin a bet to see how far along it is, beside the clock, while you play.",
	],
	["The Jackpot", "Every road leads here. Win bets to open more roads and reach the Jackpot."],
]
const PIN_IN_MENU := "Pin a bet to see how far along it is in the pause menu while you play."
const NEXT := "Next"
const PIN_IT := "Pin it"
const NOT_NOW := "Not now"
const DONE := "Got it"
## The chips naming the slip's parts at the second step, in the House's capitals.
const PARTS: Array[String] = ["What to do", "So far", "What it pays"]

## How dark the dialog is round the spots, their soft edge, the room round what they light, and
## how quickly they come round to the next thing lit.
const DARK := 0.66
const SOFT := 30.0
const AROUND := 26.0
const FOLLOW := 9.0
const MOST_SPOTS := 4
## Where the lamps hang over the screen, a share of its width in from either side and above its
## top, on a stage of [constant OpeningInvitation.STAGE] scaled to the screen's height; and how
## long they take to come on.
const LAMP_IN := 0.16
const LAMP_UP := -160.0
const LIGHTS_UP := 0.5
## The red line from a tag to what it speaks of, and the chips' red.
const LINE := Color(0.8, 0.17, 0.14)
const LINE_WIDE := 3.0
const DOT := 7.0
## How far a tag stands from what it speaks of and from the screen's edges; how long after the
## kart has come to the bet its parts are named, the slip's page turned; how long the map takes to
## draw back; and how long a tag takes to come on.
const GAP := 26.0
const EDGE := 18.0
const TURNED := LoyaltyPane.TURN + 0.1
const DRAW_BACK := 1.1
const TAG_IN := 0.22
## How far an open bet's ticket hangs under its sign, at a zoom of one, lit and kept clear with it.
const TICKET_DOWN := 52.0

var dialog: LoyaltyDialog
var step := Step.HERE

var _profile: Profile
var _shade: ColorRect
var _shader: ShaderMaterial
var _beams: Node2D
var _lines: Control
var _tag: TourTag
var _picture: PinPicture
var _reveal: LoyaltyReveal
## The spots as they are drawn now and as they are wanted, each its middle and radii.
var _spots: Array[Vector4] = []
## What each step lights, and where its line runs to and from: worked out afresh every frame, so
## they follow the map as it moves.
var _lit: Callable
var _aim: Callable
## Where a click goes on through to what is under it, the slip's Pin at the third step; and what
## the tag keeps clear of besides what is lit, the slip at that step, so its bet can be read.
var _holes: Array[Control] = []
var _clear: Array[Control] = []
## Whether a press goes on, the step's movement done.
var _settled := false
var _lights := 0.0
var _keyboard := true
var _pointer := false
## The bet the second and third steps are at, and the map's zoom as it starts drawing back.
var _bet := &""
var _since := 0.0
var _drawing_back: Tween
## The signs the slip road's roads opened, lit with it at the first step.
var _opened: Array[StringName] = []
## Whether the tag is up, saying the step.
var _tag_up := false


## Whether [param of] is shown round as its map opens: never once it has been, nor before it is a
## member; always as the welcome opens it, [param welcoming]; and once for a profile welcomed
## before the first look came, while it has won nothing past the slip road.
static func due(of: Profile, welcoming: bool) -> bool:
	if of.loyalty.toured or not of.loyalty.welcomed:
		return false
	if welcoming:
		return true
	for id: String in of.loyalty.won:
		if StringName(id) != Loyalty.SLIP_ROAD:
			return false
	return true


## The bets the first step shows being won: the slip road, and every other bet of the House's won
## since the map last showed them, in the order they were won.
static func showing(of: Profile) -> Array[StringName]:
	var ids: Array[StringName] = [Loyalty.SLIP_ROAD]
	for id: StringName in LoyaltyReveal.due(of, LoyaltyMapLayout.Sheet.HOUSE):
		if id != Loyalty.SLIP_ROAD:
			ids.append(id)
	return ids


## The House's tour over [param on], from its first step.
static func over(on: LoyaltyDialog) -> LoyaltyTour:
	var tour := LoyaltyTour.new()
	tour.name = "Tour"
	tour.dialog = on
	on.root().add_child(tour)
	return tour


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	_profile = Game.settings.profile
	_keyboard = Game.last_input_keyboard
	_pointer = Game.last_input_pointer
	_shade = ColorRect.new()
	_shade.name = "Shade"
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shader = ShaderMaterial.new()
	_shader.shader = preload("res://scenes/loyalty/tour_shade.gdshader")
	_shader.set_shader_parameter(&"dark", DARK)
	_shader.set_shader_parameter(&"soft", SOFT)
	_shade.material = _shader
	add_child(_shade)
	_beams = Node2D.new()
	_beams.name = "Beams"
	_beams.draw.connect(_draw_beams)
	_beams.modulate.a = 0.0
	add_child(_beams)
	_lines = Control.new()
	_lines.name = "Lines"
	_lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lines.draw.connect(_draw_lines)
	add_child(_lines)
	_tag = TourTag.new()
	_tag.modulate.a = 0.0
	_tag.pressed.connect(_on_pressed)
	add_child(_tag)
	ScreenReader.live(_tag)
	# The dark and the lamps come on over the map, rather than all at once.
	var lit := create_tween().set_parallel()
	lit.tween_property(self, "_lights", 1.0, LIGHTS_UP)
	lit.tween_method(
		func(by: float) -> void: _shader.set_shader_parameter(&"dark", DARK * by),
		0.0,
		1.0,
		LIGHTS_UP
	)
	Audio.play_sfx(&"item_use", -10.0, 0.0)
	_go(Step.HERE)


## The dialog's map, its cursor and its slip, where the steps are.
func _map() -> LoyaltyMapView:
	return dialog.map_view


## Goes to [param to], each step setting up what it lights and says.
func _go(to: Step) -> void:
	step = to
	_settled = false
	_since = 0.0
	_holes.clear()
	_clear.clear()
	if _picture != null:
		_picture.queue_free()
		_picture = null
	_hide_tag()
	match to:
		Step.HERE:
			_here()
		Step.COUNTS:
			_counts()
		Step.PIN:
			_pin()
		Step.JACKPOT:
			_jackpot()
		_:
			_end(false)


## The slip road lit, its stamp coming down and its roads drawing out, see [LoyaltyReveal]: every
## bet won since the map last showed them shown with it, the slip road first.
func _here() -> void:
	var map := _map()
	map.zoom_to(LoyaltyMapView.ZOOM_START, map.size * 0.5)
	dialog.turn_to(LoyaltyMapLayout.Sheet.HOUSE)
	map.stand_at(Loyalty.SLIP_ROAD)
	_reveal = dialog.reveal_now(showing(_profile))
	_reveal.finished.connect(_settle)
	# The bets the slip road's roads open lit as the gold reaches them.
	_lit = func() -> Array[Rect2]:
		var rects: Array[Rect2] = [_sign(Loyalty.SLIP_ROAD)]
		var showing := _reveal != null and is_instance_valid(_reveal) and not _reveal.is_done()
		if not showing or _reveal.has_reached(0):
			for id: StringName in _opened:
				rects.append(_sign(id))
		return rects
	_aim = func() -> Rect2: return _sign(Loyalty.SLIP_ROAD)
	_opened = _reveal.opens_of(0)
	# Said once the stamp has come down, as the roads draw out.
	get_tree().create_timer(LoyaltyReveal.ROUND_TO + LoyaltyReveal.STAMP).timeout.connect(
		func() -> void:
			if step == Step.HERE:
				_show_tag(_here_said(), [NEXT])
	)


## What the first step says, the program named as its card is.
func _here_said() -> Array:
	return [SAID[0][0], str(SAID[0][1]) % LoyaltyDialog.program_name(_profile)]


## The kart driven to the nearest open bet, the slip saying it, and once it is there and the page
## has turned, the slip's parts named.
func _counts() -> void:
	_bet = Loyalty.nearest_open(_profile)
	if _bet == &"":
		_go(Step.JACKPOT)
		return
	var map := _map()
	_lit = func() -> Array[Rect2]: return [_sign(_bet)]
	_aim = func() -> Rect2: return _sign(_bet)
	if map.cursor.at == _bet and not map.cursor.is_driving():
		_at_bet()
		return
	map.drive_to(_bet)


## Come to the bet: a moment for the slip's page to turn, then the slip lit beside it and named.
func _at_bet() -> void:
	if step != Step.COUNTS or _settled:
		return
	_settled = true
	_lit = func() -> Array[Rect2]: return [_sign(_bet), _global(dialog.pane)]
	get_tree().create_timer(TURNED).timeout.connect(
		func() -> void:
			if step == Step.COUNTS:
				_show_tag(SAID[1], [NEXT])
	)


## The slip's Pin lit, and a picture of what pinning it gives; Pin it or Not now.
func _pin() -> void:
	var pin := dialog.pane.pin
	if not pin.is_visible_in_tree() or dialog.pane.shown != _bet:
		_go(Step.JACKPOT)
		return
	_holes = [pin]
	_clear = [dialog.pane]
	_picture = PinPicture.of(_profile, _bet, get_viewport_rect().size.x)
	_picture.modulate.a = 0.0
	add_child(_picture)
	move_child(_picture, _tag.get_index())
	_lit = func() -> Array[Rect2]: return [_global(pin), _global(_picture), _global(dialog.pane)]
	_aim = func() -> Rect2: return _global(pin)
	_settled = true
	var said: Array = SAID[2].duplicate()
	if not _picture.strip:
		said[1] = PIN_IN_MENU
	var going: Array[String] = [NOT_NOW, PIN_IT]
	if _profile.loyalty.pinned == _bet:
		going = [NEXT]
	_show_tag(said, going)


## The map drawn back until all of it shows, the JACKPOT lit at its top and the slip road at its
## foot; Got it, the map left to the member.
func _jackpot() -> void:
	var map := _map()
	map.cursor.finish()
	_lit = func() -> Array[Rect2]: return [_sign(Loyalty.ROUNDABOUT), _sign(Loyalty.SLIP_ROAD)]
	_aim = func() -> Rect2: return _sign(Loyalty.ROUNDABOUT)
	var from := map.zoom
	var to := map.fit_zoom()
	_drawing_back = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_drawing_back.tween_method(
		func(zoom: float) -> void: map.zoom_to(zoom, map.size * 0.5), from, to, DRAW_BACK
	)
	_drawing_back.tween_callback(_settle)
	Audio.play_sfx(&"page", -8.0, 0.05)
	_show_tag(SAID[3], [DONE], false)


## The step's movement done: a press goes on.
func _settle() -> void:
	_settled = true


func _process(delta: float) -> void:
	_since += delta
	if step == Step.COUNTS and not _settled and not _map().cursor.is_driving():
		if _map().cursor.at == _bet:
			_at_bet()
	_follow(delta)
	_place_tag()
	_lines.queue_redraw()
	_beams.queue_redraw()
	_beams.modulate.a = _lights
	_beams.scale = Vector2.ONE * size.y / OpeningInvitation.STAGE.y
	if not _tag_up and _tag.modulate.a > 0.0:
		_tag.modulate.a = 0.0


## The spots come round to what the step lights, each eased toward its own, a new one opening from
## its middle and one no longer wanted closing to it.
func _follow(delta: float) -> void:
	var wanted: Array[Vector4] = []
	if _lit.is_valid():
		for rect: Rect2 in _lit.call():
			if rect.size == Vector2.ZERO:
				continue
			var reach := rect.size * 0.5 + Vector2.ONE * AROUND
			wanted.append(Vector4(rect.get_center().x, rect.get_center().y, reach.x, reach.y))
			if wanted.size() >= MOST_SPOTS:
				break
	var toward := 1.0 - exp(-FOLLOW * delta)
	while _spots.size() < wanted.size():
		var middle := wanted[_spots.size()]
		_spots.append(Vector4(middle.x, middle.y, 0.0, 0.0))
	for i: int in _spots.size():
		var goal := wanted[i] if i < wanted.size() else Vector4(_spots[i].x, _spots[i].y, 0.0, 0.0)
		_spots[i] = _spots[i].lerp(goal, toward)
	while _spots.size() > wanted.size() and _spots[-1].z < 2.0:
		_spots.pop_back()
	var packed: Array[Vector4] = []
	for i: int in MOST_SPOTS:
		packed.append(_spots[i] if i < _spots.size() else Vector4.ZERO)
	_shader.set_shader_parameter(&"room", size)
	_shader.set_shader_parameter(&"spots", packed)
	_shader.set_shader_parameter(&"count", mini(_spots.size(), MOST_SPOTS))


## The sign of [param id] where it is on the screen, here; nothing for one not on the sheet shown
## or out of the map's sight.
func _sign(id: StringName) -> Rect2:
	var map := _map()
	if id != Loyalty.ROUNDABOUT and not map.is_on_sheet(id):
		return Rect2()
	var rect := map.sign_rect(id)
	var landmark := Loyalty.map().landmark(id)
	if (
		landmark != null
		and landmark.kind != LoyaltyLandmark.Kind.CARD
		and Loyalty.standing(map.profile, landmark) == Loyalty.Standing.OPEN
	):
		rect.size.y += TICKET_DOWN * map.zoom
	if not Rect2(Vector2.ZERO, map.size).intersects(rect):
		return Rect2()
	return get_global_transform().affine_inverse() * map.get_global_transform() * rect


## [param control]'s rect here.
func _global(control: Control) -> Rect2:
	if control == null or not is_instance_valid(control) or not control.is_visible_in_tree():
		return Rect2()
	return get_global_transform().affine_inverse() * control.get_global_rect()


## The tag saying [param said], its heading and line, with [param going] the buttons that go on,
## Skip tour with them where [param skippable]; the cursor on the last.
func _show_tag(said: Array, going: Array[String], skippable := true) -> void:
	_tag.say(step + 1, STEPS, str(said[0]), str(said[1]), going, skippable)
	_tag.fit_to(minf(size.x - EDGE * 2.0, TourTag.WIDE))
	_tag_up = true
	_place_tag()
	var coming := create_tween().set_parallel()
	coming.tween_property(_tag, "modulate:a", 1.0, TAG_IN)
	if _picture != null:
		coming.tween_property(_picture, "modulate:a", 1.0, TAG_IN)
	_tag.main().grab_focus.call_deferred()
	_tag.show_binds(_keyboard, not _pointer and not TouchInput.enabled)
	ScreenReader.say(self, ScreenReader.spoken(str(said[0])) + ". " + str(said[1]))
	Audio.play_sfx(&"page", -10.0, 0.05)


func _hide_tag() -> void:
	_tag_up = false
	_tag.modulate.a = 0.0


## The tag and the picture clear of what the step lights, beside what it speaks of: under it,
## over it, or beside it, whichever has the room, and kept on the screen.
func _place_tag() -> void:
	if not _tag_up:
		return
	var aim: Rect2 = _aim.call() if _aim.is_valid() else Rect2()
	var lit: Array[Rect2] = []
	if _lit.is_valid():
		lit.assign(_lit.call())
	for each: Control in _clear:
		lit.append(_global(each))
	# Clear of what it lights, but not of its own picture, which goes with it.
	if _picture != null:
		lit.erase(_global(_picture))
	var room := Rect2(Vector2.ONE * EDGE, size - Vector2.ONE * EDGE * 2.0)
	var tag_size := _tag.get_combined_minimum_size()
	tag_size.x = maxf(tag_size.x, _tag.custom_minimum_size.x)
	var whole := tag_size
	if _picture != null:
		whole.y += _picture.size.y + GAP * 0.6
		whole.x = maxf(whole.x, _picture.size.x)
	var at := _beside(aim, whole, room, lit)
	_tag.size = tag_size
	_tag.position = at
	if _picture != null:
		_picture.position = Vector2(at.x, at.y + tag_size.y + GAP * 0.6)
		var fits := _picture.size.x <= room.size.x
		_picture.scale = Vector2.ONE * (1.0 if fits else room.size.x / _picture.size.x)


## Where something [param whole] big goes beside [param aim] inside [param room], clear of every
## rect in [param clear] where it can be: under, over, left of or right of it, the first that is.
static func _beside(aim: Rect2, whole: Vector2, room: Rect2, clear: Array[Rect2]) -> Vector2:
	var middle := aim.get_center() if aim.size != Vector2.ZERO else room.get_center()
	var tries: Array[Vector2] = [
		Vector2(middle.x - whole.x * 0.5, aim.end.y + GAP),
		Vector2(middle.x - whole.x * 0.5, aim.position.y - GAP - whole.y),
		Vector2(aim.position.x - GAP - whole.x, middle.y - whole.y * 0.5),
		Vector2(aim.end.x + GAP, middle.y - whole.y * 0.5),
	]
	var best := Vector2.ZERO
	var least := INF
	for at: Vector2 in tries:
		var kept := at.clamp(room.position, (room.end - whole).max(room.position))
		var rect := Rect2(kept, whole)
		var over := 0.0
		for each: Rect2 in clear:
			over += rect.intersection(each).get_area()
		# Pulled back onto the screen, a try may be over what it was beside: that counts too.
		over += (kept - at).length() * 4.0
		if over < least:
			least = over
			best = kept
	return best


## The two beams from the lamps over the screen, both on the first thing lit, as the welcome's are
## on its card, see [method OpeningInvitation.draw_beams]: each a core of light, its edges fading
## out, narrow at its lamp and as wide as the spot where it ends on it, brighter near its lamp; and
## the glare of the lamps themselves.
func _draw_beams() -> void:
	if _spots.is_empty() or _spots[0].z < 2.0:
		return
	var by := size.y / OpeningInvitation.STAGE.y
	var stage_wide := size.x / by
	var on := Vector2(_spots[0].x, _spots[0].y) / by
	var reach := maxf(_spots[0].z, _spots[0].w) / by
	var near := Color(OpeningInvitation.LIGHT, OpeningInvitation.BEAM_NEAR)
	var far := Color(OpeningInvitation.LIGHT, OpeningInvitation.BEAM_FAR)
	var none := Color(OpeningInvitation.LIGHT, 0.0)
	for lamp: Vector2 in [
		Vector2(stage_wide * LAMP_IN, LAMP_UP), Vector2(stage_wide * (1.0 - LAMP_IN), LAMP_UP)
	]:
		var along := (on - lamp).normalized()
		var across := Vector2(-along.y, along.x)
		var edges: Array[float] = [
			-1.0, -OpeningInvitation.BEAM_CORE, OpeningInvitation.BEAM_CORE, 1.0
		]
		for i: int in 3:
			var points := PackedVector2Array(
				[
					lamp + across * OpeningInvitation.BEAM_FROM * edges[i],
					on + across * reach * edges[i],
					on + across * reach * edges[i + 1],
					lamp + across * OpeningInvitation.BEAM_FROM * edges[i + 1],
				]
			)
			var colors := PackedColorArray(
				[
					none if i == 0 else near,
					none if i == 0 else far,
					none if i == 2 else far,
					none if i == 2 else near,
				]
			)
			_beams.draw_polygon(points, colors)
		_beams.draw_texture_rect(
			OpeningInvitation.glow(),
			Rect2(
				lamp - Vector2.ONE * OpeningInvitation.GLARE,
				Vector2.ONE * OpeningInvitation.GLARE * 2.0
			),
			false,
			Color(OpeningInvitation.LIGHT, OpeningInvitation.GLARE_LIGHT)
		)


## The red line from the tag to what it speaks of, a dot at its end; and at the second step the
## chips naming the slip's parts.
func _draw_lines() -> void:
	if not _tag_up:
		return
	var alpha := _tag.modulate.a
	var aim: Rect2 = _aim.call() if _aim.is_valid() else Rect2()
	if aim.size != Vector2.ZERO:
		var tag := Rect2(_tag.position, _tag.size)
		var to := _nearest_on(aim, tag.get_center())
		var from := _nearest_on(tag, to)
		if not tag.grow(-2.0).has_point(to):
			_lines.draw_line(from, to, Color(LINE, alpha), LINE_WIDE, true)
			_lines.draw_circle(to, DOT, Color(HouseTheme.PAPER, alpha))
			_lines.draw_circle(to, DOT - 2.0, Color(LINE, alpha))
	if step == Step.COUNTS:
		_draw_parts(alpha)


## The chips naming the slip's parts, each just left of its part and pointing at it.
func _draw_parts(alpha: float) -> void:
	var pane := dialog.pane
	var parts: Array[Control] = []
	for named: String in ["Bet", "Bar", "Pays"]:
		parts.append(pane.find_child(named, true, false) as Control)
	var font := Type.display_font()
	var tall := float(Type.LABEL + 3)
	for i: int in parts.size():
		var rect := _global(parts[i])
		if rect.size == Vector2.ZERO:
			continue
		var words := PARTS[i].to_upper()
		var wide := font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, int(tall)).x + 20.0
		var right := _global(pane).position.x - 6.0
		var chip := Rect2(
			Vector2(right - 16.0 - wide, rect.get_center().y - 15.0), Vector2(wide, 30.0)
		)
		var look := StyleBoxFlat.new()
		look.bg_color = Color(LINE, alpha)
		look.set_corner_radius_all(4)
		_lines.draw_style_box(look, chip)
		(
			_lines
			. draw_colored_polygon(
				PackedVector2Array(
					[
						Vector2(chip.end.x, chip.position.y + 7.0),
						Vector2(right, chip.get_center().y),
						Vector2(chip.end.x, chip.end.y - 7.0),
					]
				),
				Color(LINE, alpha)
			)
		)
		_lines.draw_string(
			font,
			Vector2(chip.position.x + 10.0, chip.get_center().y + tall * 0.36),
			words,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			int(tall),
			Color(HouseTheme.PAPER, alpha)
		)


## The point of [param rect] nearest [param to].
static func _nearest_on(rect: Rect2, to: Vector2) -> Vector2:
	return to.clamp(rect.position, rect.end)


## A button along the tag's foot pressed.
func _on_pressed(words: String) -> void:
	if step == Step.DONE:
		return
	match words:
		TourTag.SKIP:
			_end(false)
		PIN_IT:
			if _profile.loyalty.pinned != _bet:
				dialog.toggle_pin()
			_go(Step.JACKPOT)
		DONE:
			_end(true)
		_:
			# Next, or at the third step Not now, which pins nothing.
			if step == Step.PIN:
				_go(Step.JACKPOT)
			else:
				_on()


## Goes on from the step, as accept or a click anywhere asks: the movement brought all at once if
## it is under way, the next step otherwise. The third waits for its buttons.
func _on() -> void:
	if not _settled or not _tag_up:
		_hurry()
		return
	if step == Step.PIN:
		return
	if step == Step.JACKPOT:
		_end(true)
		return
	_go((step + 1) as Step)


## The step's movement brought all at once.
func _hurry() -> void:
	match step:
		Step.HERE:
			if _reveal != null and is_instance_valid(_reveal):
				_reveal.finish_now()
			_settled = true
			_show_tag(_here_said(), [NEXT])
		Step.COUNTS:
			_map().cursor.finish()
			_map().show_point(_map().cursor.point, false)
		Step.JACKPOT:
			if _drawing_back != null and _drawing_back.is_valid():
				_drawing_back.custom_step(DRAW_BACK)


## The slip's own Pin clicked at the third step: pinned as Pin it pins.
func pinned_from_slip() -> void:
	if step == Step.PIN:
		_go(Step.JACKPOT)


## Ended, [param finished] or skipped: kept in the profile, so it does not come again by itself;
## the map as the steps would have left it, the cursor on it, and drawn back in to the cursor from
## all of it, the member's to look round.
func _end(finished: bool) -> void:
	if step == Step.DONE:
		return
	step = Step.DONE
	if _reveal != null and is_instance_valid(_reveal):
		_reveal.finish_now()
	if _drawing_back != null and _drawing_back.is_valid():
		_drawing_back.kill()
	var map := _map()
	map.cursor.finish()
	if map.zoom < LoyaltyMapView.ZOOM_START - 0.01:
		var back := map.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		back.tween_method(
			func(zoom: float) -> void: map.zoom_to(zoom, map.to_view(map.cursor.point)),
			map.zoom,
			LoyaltyMapView.ZOOM_START,
			DRAW_BACK * 0.8
		)
		back.tween_callback(func() -> void: map.show_point(map.cursor.point, true))
	if not _profile.loyalty.toured:
		_profile.loyalty.toured = true
		if not Game.is_headless():
			Game.settings.save_to_disk()
	ended.emit(finished)
	# The dark and the lamps going off, the map the player's at once.
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var going := create_tween()
	going.tween_property(self, "modulate:a", 0.0, TAG_IN)
	going.tween_callback(queue_free)


## Keys, a pad, a click or a finger: Back skips it, accept goes on unless the cursor is on a
## button, which presses it, and nothing gets past to the map.
func _input(event: InputEvent) -> void:
	if step == Step.DONE:
		return
	var keyboard := LicenseView.keyboard_after(event, _keyboard)
	var pointer := ButtonBinds.pointer_after(event, _pointer)
	if keyboard != _keyboard or pointer != _pointer:
		_keyboard = keyboard
		_pointer = pointer
		_tag.show_binds(_keyboard, not _pointer and not TouchInput.enabled)
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		Audio.play_sfx(&"ui_back", MenuTheme.CLICK_DB, 0.0)
		_end(false)
		return
	if event.is_action_pressed(&"ui_accept") and not event.is_echo():
		get_viewport().set_input_as_handled()
		var focused := get_viewport().gui_get_focus_owner() as Button
		if _settled and _tag_up and focused != null and _tag.is_ancestor_of(focused):
			# Press the go button the cursor is on, so a pad's A continues as a click or a key does:
			# the tour swallows the pad's buttons below, so a focused button never hears it itself.
			focused.pressed.emit()
		else:
			_on()
		return
	# The cursor goes between the tag's buttons; nothing else of the keys or a pad goes past it.
	for way: StringName in [&"ui_left", &"ui_right", &"ui_focus_next", &"ui_focus_prev"]:
		if event.is_action(way):
			return
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		get_viewport().set_input_as_handled()


## A click or a tap anywhere but on the tag goes on; the wheel and a drag do nothing to the map.
func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.button_index == MOUSE_BUTTON_LEFT and click.pressed:
		_on()
	accept_event()


## Clicks go through the holes, the slip's Pin at the third step, to what is under them.
func _has_point(point: Vector2) -> bool:
	for hole: Control in _holes:
		if is_instance_valid(hole) and _global(hole).has_point(point):
			return false
	return Rect2(Vector2.ZERO, size).has_point(point)
