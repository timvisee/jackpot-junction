class_name LicenseCard
extends Control
## The driver license the driving test ends on, GAME.md 9.4a: a card the shape of one in a
## wallet, cream paper under a dark band, the game's mark and DRIVER LICENSE on the band, the
## holder's kart in their own color and hat in the photo, turning slowly as a photo of a kart
## should, their name large beside it, the class, K for Kart, the day it was issued and the day,
## 420 years on, it expires, a number of its own, the endorsements earned in the final exam as chips
## along the foot, lit for the ones earned, a signature in blue ink, and the fine print. Drawn,
## as every picture in the game is, 8.3a, so it is one control that can be shaken and stamped.
## The stamp's impression is drawn on it once it has come down, see [RubberStamp]. It has a back,
## which it turns over to show, see [method flip]: a magnetic stripe, a hologram with the game's
## mark in it that shimmers as it is looked at, the number as a barcode, the small print of
## whose card it is, and, for whoever reads that far, a cheat code that does nothing.

const SIZE := Vector2(560.0, 352.0)
const RADIUS := 18.0
const PAPER := Color(0.95, 0.92, 0.84)
const PAPER_LOW := Color(0.86, 0.82, 0.71)
const BAND := Color(0.1, 0.1, 0.13)
const BAND_HEIGHT := 64.0
const INK := Color(0.13, 0.12, 0.14)
const FAINT := Color(0.47, 0.45, 0.46)
const SIGNATURE_INK := Color(0.14, 0.2, 0.46)
## The hand the signature is written in: Homemade Apple, a handwriting face under the Apache
## license, see assets/fonts, the one face in the game that is not Inter, since a signature set
## in a text face is a name typed on a line.
const SIGNATURE_FONT: Font = preload("res://assets/fonts/HomemadeApple-Regular.ttf")
const SIGNATURE_SIZE := 17
const STAMP_INK := Color(0.8, 0.17, 0.14, 0.82)
const PHOTO := Rect2(Vector2(26.0, 84.0), Vector2(148.0, 148.0))
const PHOTO_BACK := Color(0.18, 0.2, 0.26)
const MARK_SIDE := 44.0
const COLUMN := 200.0
const RIGHT := 534.0
const AGENCY := "JACKPOT JUNCTION  ·  DEPT. OF KARTS"
const TITLE := "DRIVER LICENSE"
const CLASS_WORD := "CLASS K"
const CLASS_LINE := "K  ·  Kart"
## How long a license is good for, in years: unreasonably.
const GOOD_FOR := 420
const MICRO := "VALID ON ALL TABLES  ·  NOT VALID AS ID  ·  KEEP OFF THE FELT  ·  NO CASH VALUE"
## The stamp's mark, where it lands and how it lies: the lower right, a little askew.
const STAMP_AT := Vector2(474.0, 296.0)
const STAMP_TURN := -0.2
const STAMP_RADIUS := 52.0
const STAMP_WORD := "PASSED"
## How long the photo takes to turn all the way round, in seconds.
const SPIN_SECONDS := 9.0
## The back: the stripe, the hologram and where its mark sits, the barcode, and the turn over,
## each half of which takes this long.
const STRIPE := Rect2(Vector2(0.0, 30.0), Vector2(SIZE.x, 44.0))
const STRIPE_INK := Color(0.1, 0.1, 0.12)
const HOLOGRAM_AT := Vector2(120.0, 210.0)
const HOLOGRAM_RADIUS := 78.0
const HOLOGRAM_MARK := 68.0
const BARCODE := Rect2(Vector2(232.0, 232.0), Vector2(300.0, 54.0))
const BACK_COLUMN := 232.0
const FLIP_HALF := 0.17
const PROPERTY := "PROPERTY OF THE DEPT. OF KARTS"
const BACK_LINES: Array[String] = [
	"If found, return to the nearest Junction. Any Junction.",
	"Valid for Class K karts only. Not transferable, not edible,",
	"not a coaster. Keep away from pits, turrets and plumbers.",
	"The holder agrees to drift responsibly, or at least often.",
]
const CODE := "CHEAT CODE"
const CODE_LINE := "Does nothing. We checked."
const EXAMINER := "The Examiner"
const BACK_MICRO := (
	"VOID WHERE PROHIBITED. ESPECIALLY THERE.  ·  " + "ISSUED BY A BOT, REVIEWED BY NOBODY."
)

var holder_name := ""
var number := ""
var issued := ""
var color_index := 0
var style: KartStyle
## The endorsements along the foot, each word to whether it was earned, in order.
var endorsements: Dictionary[String, bool] = {}
## Whether the stamp has come down on it.
var stamped := false
## Whether the back is up, see [method flip].
var flipped := false

var _photo: SubViewportContainer
var _kart: Node3D
var _mark: LogoArt
var _back_mark: LogoArt
var _shimmer := 0.0
var _turning := false


## A card for [param of], numbered [param numbered], issued on [param on], the kart in its color
## and dress in the photo, with [param earned] along the foot.
static func create(
	of: String,
	numbered: String,
	on: String,
	in_color: int,
	dressed: KartStyle,
	earned: Dictionary[String, bool]
) -> LicenseCard:
	var card := LicenseCard.new()
	card.name = "LicenseCard"
	# Nothing to press on a card, unless whoever shows it says otherwise, as the title does.
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.holder_name = of
	card.number = numbered
	card.issued = on
	card.color_index = in_color
	card.style = dressed
	card.endorsements = earned
	return card


## A number for a new license: JJ and six digits, drawn with [param rng].
static func new_number(rng: RandomNumberGenerator) -> String:
	return "JJ-%06d" % rng.randi_range(100000, 999999)


## Today, the way the card writes a date.
static func today() -> String:
	return Time.get_date_string_from_system()


## When a license issued on [param issued] expires: the same day, [constant GOOD_FOR] years on.
static func expiry(issued: String) -> String:
	if issued.length() < 4 or not issued.substr(0, 4).is_valid_int():
		return "NEVER"
	return "%04d%s" % [issued.substr(0, 4).to_int() + GOOD_FOR, issued.substr(4)]


## The license this machine holds, as the settings keep it, GAME.md 9.4a, stamped as it was:
## for the title and the settings to show. The kart in the photo is the first seat's.
static func from_settings() -> LicenseCard:
	var settings := Game.settings
	var holder := settings.license_holder
	if holder.is_empty():
		holder = settings.player_names[0]
	if holder.is_empty():
		holder = "Player 1"
	var earned: Dictionary[String, bool] = {}
	for word: String in TutorialFight.ENDORSEMENTS:
		earned[word] = word in settings.license_endorsements
	var card := create(
		holder,
		settings.license_number,
		settings.license_date,
		0,
		KartStyle.from_array(settings.kart_styles[0]),
		earned
	)
	card.stamped = true
	return card


func _ready() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	pivot_offset = SIZE * 0.5
	_mark = LogoArt.new()
	_mark.plate = false
	_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mark.position = Vector2(16.0, (BAND_HEIGHT - MARK_SIDE) * 0.5)
	_mark.size = Vector2(MARK_SIDE, MARK_SIDE)
	add_child(_mark)
	_build_photo()
	# The mark in the hologram on the back, which the shimmer plays over.
	_back_mark = LogoArt.new()
	_back_mark.plate = false
	_back_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_back_mark.position = HOLOGRAM_AT - Vector2.ONE * HOLOGRAM_MARK * 0.5
	_back_mark.size = Vector2.ONE * HOLOGRAM_MARK
	_back_mark.modulate = Color(1.0, 1.0, 1.0, 0.85)
	_back_mark.visible = false
	add_child(_back_mark)


## The stamp has come down: its mark is on the card from here on.
func stamp() -> void:
	stamped = true
	queue_redraw()


func _process(delta: float) -> void:
	if _kart != null and not flipped:
		_kart.rotate_y(TAU * delta / SPIN_SECONDS)
	if flipped:
		_shimmer += delta
		queue_redraw()


## Turns the card over, to its back or its front again: it narrows to nothing about its middle,
## the other side comes round, and it widens again, the way a card turned in the hand does.
func flip() -> void:
	if _turning:
		return
	_turning = true
	var wide := scale.x
	var turn := create_tween()
	turn.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	turn.tween_property(self, "scale:x", 0.0, FLIP_HALF)
	turn.tween_callback(_other_side)
	turn.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	turn.tween_property(self, "scale:x", wide, FLIP_HALF)
	turn.tween_callback(func() -> void: _turning = false)
	Audio.play_sfx(&"page", -10.0, 0.0)


## The other side up: the photo and the front's mark go with the front, the hologram's mark
## comes with the back.
func _other_side() -> void:
	flipped = not flipped
	_photo.visible = not flipped
	_mark.visible = not flipped
	_back_mark.visible = flipped
	queue_redraw()


## Whether the card is in the middle of turning over.
func is_turning() -> bool:
	return _turning


## The photo: the holder's kart in a little world of its own, lit evenly, turning.
func _build_photo() -> void:
	_photo = SubViewportContainer.new()
	_photo.name = "Photo"
	_photo.stretch = true
	_photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_photo.position = PHOTO.position
	_photo.size = PHOTO.size
	var viewport := SubViewport.new()
	viewport.size = Vector2i(PHOTO.size * 2.0)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	var world := World3D.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.62, 0.62, 0.7)
	environment.ambient_light_energy = 1.0
	world.environment = environment
	viewport.world_3d = world
	_photo.add_child(viewport)
	_kart = KartVisuals.display_model(color_index, style)
	_kart.rotation.y = 0.6
	# Low in the frame, so the hat has the room.
	_kart.position.y = -0.22
	viewport.add_child(_kart)
	var camera := Camera3D.new()
	camera.fov = 34.0
	camera.look_at_from_position(Vector3(0.0, 1.55, 3.3), Vector3(0.0, 0.9, 0.0), Vector3.UP)
	viewport.add_child(camera)
	var light := DirectionalLight3D.new()
	light.light_energy = 1.1
	light.rotation_degrees = Vector3(-40.0, -30.0, 0.0)
	light.shadow_enabled = false
	viewport.add_child(light)
	add_child(_photo)


func _draw() -> void:
	_draw_paper()
	if flipped:
		_draw_back()
		return
	_draw_band()
	_draw_photo_frame()
	_draw_fields()
	_draw_endorsements()
	_draw_signature()
	_draw_micro()
	if stamped:
		_draw_stamp()


## The back: the magnetic stripe along the top, the hologram with the mark in it, whose card it
## is in small print with the number as a barcode under it, the examiner's own signature, the
## fine print, and the cheat code.
func _draw_back() -> void:
	draw_rect(STRIPE, STRIPE_INK)
	draw_rect(
		Rect2(STRIPE.position + Vector2(0.0, 6.0), Vector2(STRIPE.size.x, 1.0)),
		Color(1.0, 1.0, 1.0, 0.08)
	)
	_draw_hologram()
	_text(Vector2(BACK_COLUMN, 96.0), PROPERTY, Type.STRONG, 11, INK)
	for i: int in BACK_LINES.size():
		_text(Vector2(BACK_COLUMN, 114.0 + float(i) * 15.0), BACK_LINES[i], Type.TEXT, 10, FAINT)
	_text(Vector2(BACK_COLUMN, 182.0), "EXAMINER", Type.STRONG, 8, FAINT)
	var hand := SIGNATURE_FONT
	draw_string(
		hand,
		Vector2(BACK_COLUMN + 60.0, 198.0),
		EXAMINER,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14,
		SIGNATURE_INK
	)
	draw_line(
		Vector2(BACK_COLUMN, 204.0), Vector2(BACK_COLUMN + 200.0, 204.0), Color(INK, 0.4), 1.0
	)
	_draw_barcode()
	# The cheat code, under the hologram, for whoever turns the card over and reads the back.
	_text(Vector2(26.0, 298.0), CODE, Type.STRONG, 8, FAINT)
	var at := Vector2(26.0, 310.0)
	for way: float in [0.0, 0.0, 180.0, 180.0, 270.0, 90.0, 270.0, 90.0]:
		IconShapes.tri(self, Rect2(at, Vector2(12.0, 12.0)), 0.5, 0.5, 0.95, way, INK)
		at.x += 15.0
	_text(at + Vector2(2.0, -1.0), "B  A", Type.STRONG, 10, INK)
	_text(Vector2(26.0, 324.0), CODE_LINE, Type.TEXT, 8, FAINT)
	_text(
		Vector2(0.0, SIZE.y - 14.0),
		BACK_MICRO,
		Type.STRONG,
		7,
		FAINT,
		HORIZONTAL_ALIGNMENT_CENTER,
		SIZE.x
	)


## The hologram: rings of light whose colors run round and through as the card is looked at,
## with the game's mark sitting in the middle of them.
func _draw_hologram() -> void:
	draw_circle(HOLOGRAM_AT, HOLOGRAM_RADIUS + 3.0, Color(INK, 0.08))
	var rings := 6
	for ring: int in rings:
		var radius := HOLOGRAM_RADIUS - float(ring) * 10.0
		var segments := 36
		for i: int in segments:
			var from := TAU * float(i) / float(segments)
			var hue := fmod(float(i) / float(segments) + _shimmer * 0.15 + float(ring) * 0.07, 1.0)
			var glow := 0.55 + 0.45 * sin(_shimmer * 2.2 + from * 3.0 + float(ring))
			var color := Color.from_hsv(hue, 0.45, 1.0, 0.18 + 0.3 * glow)
			draw_arc(
				HOLOGRAM_AT, radius, from, from + TAU / float(segments) + 0.02, 4, color, 7.0, true
			)
	# A sheen that sweeps across, the way the light does over a real one.
	var sweep := fmod(_shimmer * 0.4, 1.0) * 2.0 - 1.0
	var band := HOLOGRAM_AT + Vector2(sweep * HOLOGRAM_RADIUS, 0.0)
	draw_set_transform(band, -0.6, Vector2.ONE)
	draw_rect(
		Rect2(Vector2(-6.0, -HOLOGRAM_RADIUS), Vector2(12.0, HOLOGRAM_RADIUS * 2.0)),
		Color(1.0, 1.0, 1.0, 0.18)
	)
	draw_set_transform(Vector2.ZERO)
	draw_arc(HOLOGRAM_AT, HOLOGRAM_RADIUS + 3.0, 0.0, TAU, 64, Color(INK, 0.35), 1.0, true)


## The number as a barcode: each digit a run of bars, wide for a one and narrow for a zero in its
## bits, with the number written under it.
func _draw_barcode() -> void:
	var x := BARCODE.position.x
	var top := BARCODE.position.y
	var tall := BARCODE.size.y - 16.0
	for character: String in number:
		if not character.is_valid_int():
			x += 4.0
			continue
		var digit := character.to_int()
		for bit: int in 4:
			var wide := 3.0 if (digit >> bit) & 1 else 1.5
			draw_rect(Rect2(Vector2(x, top), Vector2(wide, tall)), INK)
			x += wide + 2.0
		x += 2.0
	_text(Vector2(BARCODE.position.x, top + tall + 3.0), number, Type.numbers_text_font(), 11, INK)


## The paper: cream, darker toward the foot, with the fine curves a banknote wears and the four
## suits as a watermark.
func _draw_paper() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.set_corner_radius_all(roundi(RADIUS))
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 16
	draw_style_box(style, Rect2(Vector2.ZERO, SIZE))
	var low := StyleBoxFlat.new()
	low.bg_color = Color(PAPER_LOW, 0.5)
	low.corner_radius_bottom_left = roundi(RADIUS)
	low.corner_radius_bottom_right = roundi(RADIUS)
	draw_style_box(low, Rect2(Vector2(0.0, SIZE.y - 40.0), Vector2(SIZE.x, 40.0)))
	var line := Color(INK, 0.045)
	for i: int in 9:
		var middle := Vector2(SIZE.x * 0.62 + float(i) * 34.0, SIZE.y * 1.9)
		draw_arc(middle, SIZE.y * 1.55 + float(i) * 6.0, PI * 1.18, PI * 1.82, 48, line, 1.0, true)
	var watermark := Color(INK, 0.05)
	for suit: int in 4:
		var at := Vector2(COLUMN + 40.0 + float(suit) * 80.0, 150.0)
		SuitArt.draw_into(self, Rect2(at, Vector2(60.0, 60.0)), suit, watermark)


## The band along the top: the agency over the title, with the class on the right.
func _draw_band() -> void:
	var band := StyleBoxFlat.new()
	band.bg_color = BAND
	band.corner_radius_top_left = roundi(RADIUS)
	band.corner_radius_top_right = roundi(RADIUS)
	draw_style_box(band, Rect2(Vector2.ZERO, Vector2(SIZE.x, BAND_HEIGHT)))
	draw_rect(Rect2(Vector2(0.0, BAND_HEIGHT), Vector2(SIZE.x, 3.0)), Palette.CHIP_GOLD)
	_text(Vector2(72.0, 12.0), AGENCY, Type.STRONG, 11, Color(0.86, 0.84, 0.78))
	_text(Vector2(72.0, 27.0), TITLE, Type.display_font(), 25, Palette.CHIP_GOLD)
	var chip := StyleBoxFlat.new()
	chip.bg_color = Palette.CHIP_GOLD
	chip.set_corner_radius_all(6)
	var chip_rect := Rect2(Vector2(SIZE.x - 98.0, 20.0), Vector2(80.0, 24.0))
	draw_style_box(chip, chip_rect)
	_text(
		chip_rect.position + Vector2(0.0, 5.0),
		CLASS_WORD,
		Type.display_font(),
		12,
		BAND,
		HORIZONTAL_ALIGNMENT_CENTER,
		chip_rect.size.x
	)


## The photo's dark back and its frame, drawn under the photo itself.
func _draw_photo_frame() -> void:
	var back := StyleBoxFlat.new()
	back.bg_color = PHOTO_BACK
	back.set_corner_radius_all(8)
	back.set_border_width_all(3)
	back.border_color = Palette.CHIP_GOLD
	draw_style_box(back, PHOTO.grow(3.0))
	_text(
		Vector2(PHOTO.position.x, PHOTO.end.y + 6.0),
		"PHOTO",
		Type.STRONG,
		9,
		FAINT,
		HORIZONTAL_ALIGNMENT_CENTER,
		PHOTO.size.x
	)


## The fields down the right of the photo: the name large, then the class, the dates and the
## number, each under a small label.
func _draw_fields() -> void:
	_field(Vector2(COLUMN, 80.0), "NAME", holder_name, 30, Type.display_font(), RIGHT - COLUMN)
	_field(Vector2(COLUMN, 134.0), "CLASS", CLASS_LINE, 19, Type.STRONG, 160.0)
	_field(
		Vector2(COLUMN + 168.0, 134.0), "LICENSE NO.", number, 19, Type.numbers_text_font(), 166.0
	)
	_field(Vector2(COLUMN, 180.0), "ISSUED", issued, 19, Type.numbers_text_font(), 160.0)
	_field(
		Vector2(COLUMN + 168.0, 180.0),
		"EXPIRES",
		expiry(issued),
		19,
		Type.numbers_text_font(),
		166.0
	)


## One field: a small gray label with its value under it, cut to [param width].
func _field(
	at: Vector2, label: String, value: String, value_size: int, font: Font, width: float
) -> void:
	_text(at, label, Type.STRONG, 10, FAINT)
	var shown := value
	while (
		shown.length() > 1
		and font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, value_size).x > width
	):
		shown = shown.substr(0, shown.length() - 1)
	_text(at + Vector2(0.0, 14.0), shown, font, value_size, INK)


## The endorsements along the foot: a chip a word, lit gold for the ones earned.
func _draw_endorsements() -> void:
	var top := 228.0
	_text(Vector2(COLUMN, top), "ENDORSEMENTS", Type.STRONG, 10, FAINT)
	var x := COLUMN
	var y := top + 16.0
	var font := Type.STRONG
	for word: String in endorsements:
		var wide := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 14.0
		if x + wide > RIGHT:
			x = COLUMN
			y += 24.0
		var chip := StyleBoxFlat.new()
		chip.set_corner_radius_all(5)
		var earned: bool = endorsements[word]
		if earned:
			chip.bg_color = Palette.CHIP_GOLD
		else:
			chip.bg_color = Color.TRANSPARENT
			chip.set_border_width_all(1)
			chip.border_color = Color(FAINT, 0.5)
		var rect := Rect2(Vector2(x, y), Vector2(wide, 19.0))
		draw_style_box(chip, rect)
		_text(
			rect.position + Vector2(0.0, 3.0),
			word,
			font,
			10,
			INK if earned else Color(FAINT, 0.7),
			HORIZONTAL_ALIGNMENT_CENTER,
			wide
		)
		x += wide + 6.0


## The holder's signature: their name slanted in blue ink over a line under the photo.
func _draw_signature() -> void:
	var line_y := 292.0
	draw_line(Vector2(26.0, line_y), Vector2(176.0, line_y), Color(INK, 0.5), 1.0)
	_text(Vector2(26.0, line_y + 3.0), "SIGNATURE", Type.STRONG, 8, FAINT)
	# In a hand, a size down for a long name, and leaning a little further than the hand does.
	var font := SIGNATURE_FONT
	var font_size := SIGNATURE_SIZE
	while (
		font_size > 10
		and font.get_string_size(holder_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > 146.0
	):
		font_size -= 1
	var slant := Transform2D(Vector2(1.0, 0.0), Vector2(-0.12, 1.0), Vector2(30.0, line_y - 8.0))
	draw_set_transform_matrix(slant)
	draw_string(
		font, Vector2.ZERO, holder_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, SIGNATURE_INK
	)
	draw_set_transform(Vector2.ZERO)


func _draw_micro() -> void:
	_text(
		Vector2(0.0, SIZE.y - 18.0),
		MICRO,
		Type.STRONG,
		8,
		FAINT,
		HORIZONTAL_ALIGNMENT_CENTER,
		SIZE.x
	)


## The stamp's mark: two red rings with PASSED between them, the agency over the word and the
## date under it, laid a little askew and short of solid, the way ink is.
func _draw_stamp() -> void:
	draw_set_transform(STAMP_AT, STAMP_TURN, Vector2.ONE)
	var ink := STAMP_INK
	draw_arc(Vector2.ZERO, STAMP_RADIUS, 0.15, 2.95, 40, ink, 4.0, true)
	draw_arc(Vector2.ZERO, STAMP_RADIUS, 3.25, 6.15, 40, ink, 4.0, true)
	draw_arc(Vector2.ZERO, STAMP_RADIUS - 8.0, 0.0, TAU, 48, Color(ink, 0.6), 1.5, true)
	var font := Type.display_font()
	var wide := STAMP_RADIUS * 2.0
	_text(
		Vector2(-STAMP_RADIUS, -14.0), STAMP_WORD, font, 24, ink, HORIZONTAL_ALIGNMENT_CENTER, wide
	)
	_text(
		Vector2(-STAMP_RADIUS, -32.0),
		"DEPT. OF KARTS",
		Type.STRONG,
		8,
		ink,
		HORIZONTAL_ALIGNMENT_CENTER,
		wide
	)
	_text(
		Vector2(-STAMP_RADIUS, 16.0),
		issued,
		Type.numbers_text_font(),
		10,
		ink,
		HORIZONTAL_ALIGNMENT_CENTER,
		wide
	)
	for side: float in [-1.0, 1.0]:
		IconShapes.star(
			self, Rect2(Vector2(side * 34.0 - 6.0, 24.0), Vector2(12.0, 12.0)), 0.5, 0.5, 0.9, ink
		)
	draw_set_transform(Vector2.ZERO)


## [param text] with its top left at [param at], or across [param width] from there when it is
## centered.
func _text(
	at: Vector2,
	text: String,
	font: Font,
	font_size: int,
	color: Color,
	align := HORIZONTAL_ALIGNMENT_LEFT,
	width := -1.0
) -> void:
	var baseline := at + Vector2(0.0, font.get_ascent(font_size))
	draw_string(font, baseline, text, align, width, font_size, color)
