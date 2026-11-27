extends "res://scenes/dev/readme_shots.gd"
## The store trailer's posed shots, docs/STEAM.md "The trailer", as scenes/dev/trailer.gd takes its
## shots of play: one a run, `++ --trailer=` and its name, recorded by Godot's movie writer for
## tools/trailer, everything in it timed in seconds from its action, on the music's beats; the run
## quits [member _length] and [member _tail] seconds after the action, which starts [member _lead]
## seconds in. On the README's throwaway profile, dressed as its shots are.
##
## Shots: invitation (the House's invitation played whole, as a first start shows it: the envelope
## in, the card drawn out, its lamps flickering on, the stub torn off and all of it dropped away,
## slowly pushed in on), bay (the kart dialog, a part changed on every beat: bodies, hats, a paint
## and a trail), loyalty (the road atlas opening, a bet won since it last showed stamped down and
## its roads drawn out), license (the driver's license held up, tilted about as if by a mouse swept
## across it so its hologram runs through its colors, turning over to the line scratched into it;
## with `++ --slide=1` dropped in from the top out of the dark into a pool of light flickering on,
## and slid away out of the bottom again), endcard (the seal stamped down, the name, where to play,
## a light run across it); and for the run of features, `++ --rack=` and its place in it, catalog
## (the jokers' catalog), see scenes/dev/trailer_caption.gd.

const FPS := 60
const KEY_ART := preload("res://scenes/dev/key_art.gd")
const CAPTION := preload("res://scenes/dev/trailer_caption.gd")
## The bay's beats: at what second, the part, and the piece the cursor goes to on it.
const BAY: Array[Array] = [
	[0.0, &"body", "Woodie"],
	[0.5, &"body", "Streamliner"],
	[1.0, &"body", "Microcar"],
	[1.5, &"hat", "Crown"],
	[2.0, &"hat", "Shark fin"],
	[2.5, &"hat", "Traffic cone"],
	[3.0, &"paint", "Card suits"],
	[3.5, &"trail", "Poker chips"],
]
## The share of the loyalty program's bets won before the shot, in the map's own order, and how
## many after those are won since it last showed, to be shown being won.
const LOYALTY_SHARE := 0.5
const LOYALTY_NEW := 2
## The end card: how big the seal is, the name and the lines under it, and the room between them.
const SEAL := 330.0
const NAME := 150
const WHERE := 76
const SUBLINE := 34
## How close the license is held, against the title's view of it, and how far down; and where the
## mouse it leans toward goes, by the second, as shares of half the card from its middle: swept
## across it and back, so its hologram runs through its colors.
const LICENSE_ZOOM := 1.5
const LICENSE_DOWN := 40.0
const LICENSE_MOUSE: Array[Vector3] = [
	Vector3(-0.8, -0.9, 0.5),
	Vector3(0.0, 0.9, -0.6),
	Vector3(0.5, 0.2, 0.0),
	Vector3(1.4, -0.95, 0.65),
	Vector3(2.3, 0.95, -0.7),
	Vector3(3.2, -0.6, 0.3),
	Vector3(4.6, 0.7, -0.5),
	Vector3(5.8, -0.5, 0.4),
]
## When the invitation starts and is accepted, from the shot's start, so it plays whole and its card
## has dropped away by the shot's end; and how far it is pushed in on over the shot.
const INVITE_FROM := -0.3
const INVITE_ACCEPT := 3.15
const INVITE_PUSH := 0.07
## The turn PLAY FREE ON STEAM settles on, its own as every stamp's is; the beats, from the cut to
## the end card, the seal, the name, where to play and how many come in on, and the band of light
## starts: the seal on the bar the card comes in on, each part after it a beat on; how long a stamp
## takes to come down, and how long the name and the line under it take to come up.
const WHERE_TURN := -0.03
## The license slid in and away, `++ --slide=1`: when it comes in from the top and how long it takes
## to settle, how long before the shot's end it goes out of the bottom and how long it takes to be
## gone, in seconds, and how far it is turned as it comes and goes, in radians, as a card slid
## across a table is.
const SLIDE_IN := Vector2(0.0, 1.0)
const SLIDE_OUT := Vector2(1.0, 0.6)
const SLIDE_TURN := 0.14
## The dark round it, and the light where it comes to rest: how dark all round, how soft the light's
## edge, as a share of its reach, and how far it reaches round the card, in the frame's units; when
## the light flickers on, [from, until, how much], and from how long before the shot's end to how
## long before it it goes out again.
const DARK := 0.93
const LIGHT_SOFT := 0.45
const LIGHT_CARD := Vector2(640.0, 430.0)
const LIGHT_ON: Array[Vector3] = [
	Vector3(0.0, 0.1, 0.0),
	Vector3(0.1, 0.16, 1.0),
	Vector3(0.16, 0.24, 0.2),
	Vector3(0.24, 0.28, 1.0),
	Vector3(0.28, 0.4, 0.35),
]
const LIGHT_OUT := Vector2(0.7, 0.1)
const LIGHT_SHADER := preload("res://scenes/dev/trailer_light.gdshader")
const CARD_BEATS: Array[float] = [0.0, 0.5, 1.0, 1.5, 2.25]
const STAMP_DOWN := 0.12
const CARD_RISE := 0.3

var _take := ""
var _lead := 0.5
var _length := 3.0
var _tail := 0.5
var _frames := -1
var _done: Dictionary[String, bool] = {}
var _invite: OpeningInvitation
var _held: LicenseView
var _kart_dialog: KartDialog
var _card: Dictionary = {}
var _shine: Control
var _rack := -1
## When the loyalty program opens, `++ --open-at=`, so a reveal's stamp lands where it is wanted;
## when the license turns over, `++ --turn-at=`; and how much quicker its tilting runs than
## [constant LICENSE_MOUSE] has it, `++ --sweep=`, for a short sting of it.
var _open_at := -0.05
var _turn_at := 1.0
var _sweep := 1.0
var _slide := false
## The license's place as the view puts it, and the dark laid over it.
var _held_at := Vector2.ZERO
var _dark: ShaderMaterial
## The title's chips and cards scrolling over it, `++ --drift=1`, `++ --at=` seconds into the
## trailer; and captions, `++ --captions=` as scenes/dev/trailer.gd takes them.
var _drift := 0.0
var _at := 0.0
var _captions: Array[Array] = []
var _shown: CanvasLayer


func _ready() -> void:
	CAPTION.deafen(self)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--trailer="):
			_take = arg.get_slice("=", 1)
		elif arg.begins_with("--lead="):
			_lead = float(arg.get_slice("=", 1))
		elif arg.begins_with("--length="):
			_length = float(arg.get_slice("=", 1))
		elif arg.begins_with("--tail="):
			_tail = float(arg.get_slice("=", 1))
		elif arg.begins_with("--rack="):
			_rack = int(arg.get_slice("=", 1))
		elif arg.begins_with("--open-at="):
			_open_at = float(arg.get_slice("=", 1))
		elif arg.begins_with("--turn-at="):
			_turn_at = float(arg.get_slice("=", 1))
		elif arg.begins_with("--sweep="):
			_sweep = float(arg.get_slice("=", 1))
		elif arg == "--slide=1":
			_slide = true
		elif arg.begins_with("--drift="):
			_drift = float(arg.get_slice("=", 1))
		elif arg.begins_with("--at="):
			_at = float(arg.get_slice("=", 1))
		elif arg.begins_with("--captions="):
			for one: String in arg.get_slice("=", 1).split(";", false):
				var turn := float(one.get_slice("|", 2)) if one.get_slice_count("|") > 2 else -0.025
				var high := float(one.get_slice("|", 3)) if one.get_slice_count("|") > 3 else -1.0
				_captions.append([float(one.get_slice("|", 0)), one.get_slice("|", 1), turn, high])
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	MenuTheme.background(self)
	match _take:
		"invitation":
			_invite = OpeningInvitation.over(self, Game.settings.profile)
			_invite.accept.self_modulate.a = 0.0
			# Deaf to the pointer the hidden display moves now and then, which would bring it all
			# on at once, or press its button early.
			_invite.set_process_input(false)
			_invite.set_process_unhandled_input(false)
			_invite.accept.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_invite.accept.focus_mode = Control.FOCUS_NONE
			# Pushed in on smoothly: a Control's place is otherwise held to whole pixels, so the
			# slow push moved a pixel every few frames.
			get_viewport().gui_snap_controls_to_pixels = false
		"license":
			_license()
		"bay":
			_kart(KartStyle.PARTS.find(&"body"), KartStyle.BODIES.find("Racer"))
		"loyalty":
			_loyalty_won()
		"endcard":
			_endcard()
		"catalog":
			_catalog()


func _process(delta: float) -> void:
	super(delta)
	_frames += 1
	if _frames == 0 and _drift > 0.0:
		CAPTION.drift(self, _at - _lead)
	if _frames == 0:
		var dialogs := find_children("*", "KartDialog", true, false)
		if not dialogs.is_empty():
			_kart_dialog = dialogs.front()
		_license_view()
	var lead_frames := roundi(_lead * FPS)
	if _frames == lead_frames:
		print("TRAILER_ACTION ", Engine.get_frames_drawn())
	var t := float(_frames - lead_frames) / FPS
	if _rack >= 0 and _once("rack", t >= 0.0):
		CAPTION.rack(self, _rack)
	for i: int in _captions.size():
		var down: float = _captions[i][0] - (CAPTION.STAMP if _captions[i][0] > 0.0 else 0.0)
		if _once("caption%d" % i, t >= down):
			# A fourth field stands it that far down the frame instead, clear of what is below.
			var middle: Vector2 = CAPTION.STANDS
			if _captions[i][3] >= 0.0:
				middle.y = _captions[i][3]
			var words := (_captions[i][1] as String).replace("_", " ")
			_shown = CAPTION.over(self, words, _captions[i][2], middle)
		var until: float = _captions[i + 1][0] if i + 1 < _captions.size() else _length
		if _once("caption_off%d" % i, t >= until - 0.22) and _shown != null:
			_shown.call("go")
	match _take:
		"invitation":
			_invitation_at(t)
		"license":
			_lean_license(t / _sweep)
			if _once("turn", t >= _turn_at) and _held != null:
				_held.stand.turn_over()
			if _slide:
				_slide_license(t)
		"bay":
			_bay_at(t)
		"loyalty":
			# Opened a moment before the shot, so the reveal's first stamp lands on its beat.
			if _once("open", t >= _open_at):
				LoyaltyDialog.open(self)
		"endcard":
			_animate_card(t)
	if _frames - lead_frames >= roundi((_length + _tail) * FPS):
		get_tree().quit()


## Whether [param due] has just come true for the first time under [param key].
func _once(key: String, due: bool) -> bool:
	if not due or _done.has(key):
		return false
	_done[key] = true
	return true


## The invitation from its start, as a first start plays it, accepted once it has all come on so the
## stub tears off and card and envelope drop away by the shot's end, as the music drops; pushed in
## on slowly all the while.
func _invitation_at(t: float) -> void:
	if _once("start", t >= INVITE_FROM):
		_invite.start()
	if _once("accept", t >= INVITE_ACCEPT):
		_invite._on_accept()
	if not is_instance_valid(_invite):
		return
	_invite.pivot_offset = _invite.size * 0.5
	var along := clampf((t - INVITE_FROM) / (_length - INVITE_FROM), 0.0, 1.0)
	_invite.scale = Vector2.ONE * (1.0 + INVITE_PUSH * along)


## The cursor walked to a piece on every beat, the rack of its part brought out first where it is
## not the one out, so the kart tries on each, see [constant BAY].
func _bay_at(t: float) -> void:
	if _kart_dialog == null:
		return
	for i: int in BAY.size():
		var beat: Array = BAY[i]
		if not _once("bay%d" % i, t >= float(beat[0])):
			continue
		var part := KartStyle.PARTS.find(beat[1])
		var piece := (KartStyle.CHOICES[part] as Array).find(beat[2])
		if _kart_dialog.open_part != part or not _kart_dialog.tray.is_out():
			_kart_dialog.open_tray(part, piece)
		else:
			var cell: Control = _kart_dialog.tray.cell_at(piece)
			if cell != null:
				cell.grab_focus()


## A profile some way round the loyalty program's map, every piece of it won so far seen, and the
## next few bets in the map's order won since it last showed: the map reveals those as it opens.
func _loyalty_won() -> void:
	var profile := Game.settings.profile
	var landmarks := Loyalty.map().landmarks
	var won := int(landmarks.size() * LOYALTY_SHARE)
	for i: int in won:
		profile.loyalty.win(landmarks[i].id)
	Loyalty.settle(profile)
	profile.loyalty.fresh.clear()
	profile.loyalty.dress_fresh.clear()
	for i: int in range(won, mini(won + LOYALTY_NEW, landmarks.size())):
		profile.loyalty.win(landmarks[i].id)
	Loyalty.settle(profile)


## The license held up close, its buttons and what they say out of the shot, so the line scratched
## into its back can be read.
func _license_view() -> void:
	var views := find_children("*", "LicenseView", true, false)
	if views.is_empty():
		return
	_held = views.front()
	_held.pivot_offset = _held.size * 0.5
	_held.scale = Vector2.ONE * LICENSE_ZOOM
	# Held a little low, so the line scratched along the top of its back is clear of the frame.
	_held.position.y += LICENSE_DOWN
	for button: BaseButton in _held.find_children("*", "BaseButton", true, false):
		button.modulate.a = 0.0
	# What the view says round the card too, but nothing drawn on the card itself.
	for words: Label in _held.find_children("*", "Label", true, false):
		if not _held.stand.is_ancestor_of(words):
			words.modulate.a = 0.0
	_held_at = _held.position
	if _slide:
		_in_the_dark()


## The view's own shade put away for a dark of the trailer's own, with a light in it, over all of
## it: see [method _slide_license].
func _in_the_dark() -> void:
	var shade: Variant = _held.get("_shade")
	if shade is CanvasItem:
		(shade as CanvasItem).visible = false
	var layer := CanvasLayer.new()
	layer.name = "Dark"
	layer.layer = 70
	add_child(layer)
	var dark := ColorRect.new()
	dark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dark = ShaderMaterial.new()
	_dark.shader = LIGHT_SHADER
	_dark.set_shader_parameter(&"dark", DARK)
	_dark.set_shader_parameter(&"soft", LIGHT_SOFT)
	dark.material = _dark
	layer.add_child(dark)


## The license dropped in from the top out of the dark, [param t] seconds in, turned a little as it
## comes and settling in a pool of light flickering on where it comes to rest; then slid away out
## of the bottom, turning the other way, into the dark, the light going out after it.
func _slide_license(t: float) -> void:
	if _held == null or _dark == null:
		return
	var frame := get_viewport_rect().size
	var coming := clampf((t - SLIDE_IN.x) / SLIDE_IN.y, 0.0, 1.0)
	coming = 1.0 - pow(1.0 - coming, 3.0)
	var going := clampf((t - _length + SLIDE_OUT.x) / SLIDE_OUT.y, 0.0, 1.0)
	going = going * going * going
	var off := Vector2(0.0, frame.y * (going - (1.0 - coming)))
	_held.position = _held_at + off
	_held.rotation = SLIDE_TURN * (1.0 - coming) - SLIDE_TURN * 0.7 * going
	if _once("slid_in", t >= SLIDE_IN.x):
		Audio.play_sfx(&"joker_drop", -6.0, 0.0)
	if _once("slid_out", t >= _length - SLIDE_OUT.x):
		Audio.play_sfx(&"joker_drop", -6.0, 0.0)
	# The switch heard as the light first comes on, as the invitation's lamps are, see
	# [OpeningInvitation].
	if _once("switched", t >= LIGHT_ON[1].x):
		Audio.play_sfx(&"item_use", -10.0, 0.0)
	# The light on where the card comes to rest, not following it in or out.
	var stand := _held.stand
	var resting := stand.get_global_transform() * (stand.size * 0.5) - off
	var lit := 1.0
	for flicker: Vector3 in LIGHT_ON:
		if t < flicker.y:
			lit = flicker.z if t >= flicker.x else 0.0
			break
	lit *= 1.0 - smoothstep(_length - LIGHT_OUT.x, _length - LIGHT_OUT.y, t)
	_dark.set_shader_parameter(&"frame", frame)
	_dark.set_shader_parameter(&"center", resting)
	_dark.set_shader_parameter(&"reach", LIGHT_CARD)
	_dark.set_shader_parameter(&"lit", lit if t >= 0.0 else 0.0)


## The license leaning toward a mouse moved slowly across its top right, [param t] seconds in: no
## longer held square on, as the README's shot holds it.
func _lean_license(t: float) -> void:
	_square_on = null
	if _held == null:
		return
	var stand := _held.stand
	stand.calm = 1.0
	# Turned by the mouse laid down here alone, not one the hidden display moves.
	stand.set_process_input(false)
	var card := Rect2(stand.global_position, stand.size * _held.scale)
	var toward := Vector2.ZERO
	for i: int in LICENSE_MOUSE.size() - 1:
		var from := LICENSE_MOUSE[i]
		var to := LICENSE_MOUSE[i + 1]
		if t <= to.x or i == LICENSE_MOUSE.size() - 2:
			var along := smoothstep(from.x, to.x, t)
			toward = Vector2(from.y, from.z).lerp(Vector2(to.y, to.z), along)
			break
	stand.set("_mouse_at", card.get_center() + toward * card.size * 0.5)
	stand.set("_mouse_seen", true)


## The end card: the title's backdrop dimmed, the seal and the name, PLAY FREE ON STEAM in foil,
## and how many play, each brought on in turn by [method _animate_card], and a light run over it.
func _endcard() -> void:
	TitleBackground.add_to(self)
	add_child(MenuTheme.closer_shade(0.72))
	var middle := VBoxContainer.new()
	middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	middle.alignment = BoxContainer.ALIGNMENT_CENTER
	middle.add_theme_constant_override("separation", 26)
	add_child(middle)
	var lockup: Container = KEY_ART.lockup(SEAL, NAME, 46.0)
	middle.add_child(lockup)
	var where := Label.new()
	where.text = "PLAY FREE ON STEAM"
	where.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Type.set_font(where, Type.mark_font(), WHERE)
	where.add_theme_color_override(&"font_color", HouseTheme.FOIL)
	middle.add_child(where)
	var subline := Label.new()
	subline.text = "Up to 4 on one screen  ·  8 online"
	subline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Type.set_font(subline, Type.STRONG, SUBLINE)
	subline.add_theme_color_override(&"font_color", Color("#efe8d6"))
	middle.add_child(subline)
	_card = {
		"seal": lockup.get_child(0),
		"name": lockup.get_child(1),
		"where": where,
		"subline": subline,
	}
	for part: String in _card:
		(_card[part] as Control).modulate.a = 0.0
	_shine = Control.new()
	_shine.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var adding := CanvasItemMaterial.new()
	adding.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_shine.material = adding
	_shine.draw.connect(_draw_shine)
	add_child(_shine)


## Each part of the end card coming in on its beat, starting there, as the eye takes a beat: the
## seal stamped down with a turn on the bar the card comes in on, heard as it comes; the name
## rising in beside it on the next beat; where to play stamped under it on the one after, heard
## too; how many rising in under that on the next; and a band of light run across them all.
func _animate_card(t: float) -> void:
	if _card.is_empty():
		return
	_stamp(_card["seal"], t, CARD_BEATS[0], 1.8, -0.5)
	if _once("seal_heard", t >= CARD_BEATS[0]):
		Audio.play_sfx(&"stamp", CAPTION.STAMP_DB, 0.0)
	var named: Control = _card["name"]
	var rise := clampf((t - CARD_BEATS[1]) / CARD_RISE, 0.0, 1.0)
	named.modulate.a = rise
	named.pivot_offset = Vector2(0.0, named.size.y * 0.5)
	named.scale = Vector2.ONE * lerpf(0.9, 1.0, ease(rise, 0.4))
	_stamp(_card["where"], t, CARD_BEATS[2], 1.6, 0.06, WHERE_TURN)
	if _once("where_heard", t >= CARD_BEATS[2]):
		Audio.play_sfx(&"stamp", CAPTION.STAMP_DB, 0.0)
	var under: Control = _card["subline"]
	under.modulate.a = clampf((t - CARD_BEATS[3]) / CARD_RISE, 0.0, 1.0)
	_shine.set_meta("at", clampf((t - CARD_BEATS[4]) / 0.7, 0.0, 1.0))
	_shine.queue_redraw()


## [param part] stamped down at [param at] seconds from [param big] times its size and
## [param turn] onto [param settle], as the caption's ticket is, [param t] seconds into the shot.
static func _stamp(
	part: Control, t: float, at: float, big: float, turn: float, settle := 0.0
) -> void:
	var down := clampf((t - at) / 0.12, 0.0, 1.0)
	var bounce := sin(clampf((t - at - 0.12) / 0.16, 0.0, 1.0) * PI) * 0.03
	part.pivot_offset = part.size * 0.5
	part.modulate.a = clampf(down * 1.5, 0.0, 1.0)
	part.scale = Vector2.ONE * (lerpf(big, 1.0, down * down) + bounce)
	part.rotation = lerpf(turn + settle, settle, down)


## The band of light, leaning, crossing the card from left to right.
func _draw_shine() -> void:
	var along: float = _shine.get_meta("at", 0.0)
	if along <= 0.0 or along >= 1.0:
		return
	var frame := _shine.size
	var x := lerpf(-300.0, frame.x + 300.0, ease(along, -1.6))
	var lean := 220.0
	var wide := 120.0
	var clear := Color(1.0, 0.9, 0.6, 0.0)
	var lit := Color(1.0, 0.9, 0.6, 0.16)
	var points := PackedVector2Array(
		[
			Vector2(x - wide + lean, 0.0),
			Vector2(x + lean, 0.0),
			Vector2(x + wide + lean, 0.0),
			Vector2(x + wide - lean, frame.y),
			Vector2(x - lean, frame.y),
			Vector2(x - wide - lean, frame.y),
		]
	)
	_shine.draw_polygon(
		PackedVector2Array([points[0], points[1], points[4], points[5]]),
		PackedColorArray([clear, lit, lit, clear])
	)
	_shine.draw_polygon(
		PackedVector2Array([points[1], points[2], points[3], points[4]]),
		PackedColorArray([lit, clear, clear, lit])
	)
