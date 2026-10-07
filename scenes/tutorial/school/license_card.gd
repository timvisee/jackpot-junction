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
## which whoever holds it up turns over to show, see [TiltedCard] and [method other_side]: a
## magnetic stripe, a hologram with the game's mark in it, a shader whose colors run with the
## card's [member tilt], the number as a barcode, the small print of whose card it is, and, for
## whoever reads that far, a cheat code that does nothing.

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
## The back: the stripe, the hologram, its shader and how big its mark is in it, the barcode.
const STRIPE := Rect2(Vector2(0.0, 30.0), Vector2(SIZE.x, 44.0))
const STRIPE_INK := Color(0.1, 0.1, 0.12)
const HOLOGRAM_AT := Vector2(120.0, 194.0)
const HOLOGRAM_RADIUS := 78.0
const HOLOGRAM_MARK := 68.0
const HOLOGRAM_SHADER := preload("res://scenes/tutorial/school/hologram.gdshader")
const BARCODE := Rect2(Vector2(232.0, 240.0), Vector2(300.0, 56.0))
const BACK_COLUMN := 232.0
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
## Whether the back is up, see [method other_side].
var flipped := false
## Who signs the back as examiner: the examiner, or after the ending the holder, STORY.md 6.7.
var examiner := EXAMINER
## Where the card is turned toward, -1 to 1 either way, which the hologram's colors run with: set
## by whoever holds the card up, see [TiltedCard].
var tilt := Vector2.ZERO:
	set = _set_tilt

var _photo: SubViewportContainer
var _kart: Node3D
var _mark: LogoArt
var _hologram: ColorRect


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
	if Story.stage_here() == Story.Stage.OPERATOR:
		card.examiner = of
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
		# The holder's favorite color, GAME.md 3.8, or the first seat's.
		maxi(settings.seat_color(0), 0),
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
	# The hologram on the back: a shader over the disc, with the mark drawn once into a picture
	# for it to raise in foil.
	_hologram = ColorRect.new()
	_hologram.name = "Hologram"
	_hologram.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hologram.position = HOLOGRAM_AT - Vector2.ONE * (HOLOGRAM_RADIUS + 3.0)
	_hologram.size = Vector2.ONE * (HOLOGRAM_RADIUS + 3.0) * 2.0
	_hologram.visible = false
	var foil := ShaderMaterial.new()
	foil.shader = HOLOGRAM_SHADER
	var emblem := LogoArt.new()
	emblem.plate = false
	foil.set_shader_parameter("mark", DrawnTexture.of(self, emblem, Vector2i(128, 128)))
	foil.set_shader_parameter("mark_share", HOLOGRAM_MARK / _hologram.size.x)
	# The game's name round the ring, over the top and along the foot, at about the size the disc
	# is drawn at on the title, so its thin rings stay sharp.
	var seal := SealWords.new()
	seal.name = "Seal"
	foil.set_shader_parameter("words", DrawnTexture.of(self, seal, Vector2i(320, 320)))
	_hologram.material = foil
	add_child(_hologram)


## The stamp has come down: its mark is on the card from here on.
func stamp() -> void:
	stamped = true
	queue_redraw()


## The kart in the photo turns only while it can be seen, so it comes round to the camera when
## it is first looked at, on a page of the settings opened later as much as anywhere.
func _process(delta: float) -> void:
	if _kart != null and not flipped and is_visible_in_tree():
		_kart.rotate_y(TAU * delta / SPIN_SECONDS)


## The other side up, on the spot: the photo and the front's mark go with the front, the
## hologram comes with the back. Whoever holds the card up does the turning, see [TiltedCard].
func other_side() -> void:
	flipped = not flipped
	_photo.visible = not flipped
	_mark.visible = not flipped
	_hologram.visible = flipped
	queue_redraw()


func _set_tilt(toward: Vector2) -> void:
	tilt = toward
	if _hologram != null:
		(_hologram.material as ShaderMaterial).set_shader_parameter("tilt", toward)


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
	_kart.rotation.y = KartVisuals.facing_soon(SPIN_SECONDS)
	# Low in the frame, so the hat has the room.
	_kart.position.y = -0.27
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


## The back: the magnetic stripe along the top, the hologram with the mark in it on the left, and
## a column of fields beside it, whose card it is in small print, the examiner's own signature,
## the cheat code and the number as a barcode under them all, with the fine print along the foot.
func _draw_back() -> void:
	draw_rect(STRIPE, STRIPE_INK)
	draw_rect(
		Rect2(STRIPE.position + Vector2(0.0, 6.0), Vector2(STRIPE.size.x, 1.0)),
		Color(1.0, 1.0, 1.0, 0.08)
	)
	_text(Vector2(BACK_COLUMN, 94.0), PROPERTY, Type.STRONG, 11, INK)
	for i: int in BACK_LINES.size():
		_text(Vector2(BACK_COLUMN, 110.0 + float(i) * 14.0), BACK_LINES[i], Type.TEXT, 10, FAINT)
	_text(Vector2(BACK_COLUMN, 168.0), "EXAMINER", Type.STRONG, 8, FAINT)
	var hand := SIGNATURE_FONT
	draw_string(
		hand,
		Vector2(BACK_COLUMN + 60.0, 184.0),
		examiner,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		14,
		SIGNATURE_INK
	)
	draw_line(
		Vector2(BACK_COLUMN, 190.0), Vector2(BACK_COLUMN + 200.0, 190.0), Color(INK, 0.4), 1.0
	)
	# The cheat code, a field like the others, for whoever turns the card over and reads the back.
	_text(Vector2(BACK_COLUMN, 200.0), CODE, Type.STRONG, 8, FAINT)
	var at := Vector2(BACK_COLUMN, 212.0)
	for way: float in [0.0, 0.0, 180.0, 180.0, 270.0, 90.0, 270.0, 90.0]:
		IconShapes.tri(self, Rect2(at, Vector2(12.0, 12.0)), 0.5, 0.5, 0.95, way, INK)
		at.x += 15.0
	_text(at + Vector2(2.0, -1.0), "B  A", Type.STRONG, 10, INK)
	_text(at + Vector2(36.0, 1.0), CODE_LINE, Type.TEXT, 8, FAINT)
	_draw_barcode()
	_text(
		Vector2(0.0, SIZE.y - 14.0),
		BACK_MICRO,
		Type.STRONG,
		7,
		FAINT,
		HORIZONTAL_ALIGNMENT_CENTER,
		SIZE.x
	)


## The number as a barcode, see [Barcode].
func _draw_barcode() -> void:
	Barcode.draw(self, BARCODE, number, INK)


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
	# The license's arcs, which every paper of the house's carries since, GAME.md 8.1a.
	var arcs := Engraving.arcs(
		Vector2(SIZE.x * 0.62, SIZE.y * 1.9),
		SIZE.y * 1.55,
		9,
		Vector2(34.0, 6.0),
		PI * 1.18,
		PI * 1.82
	)
	Engraving.draw_on(self, arcs, Color(INK, 0.045))
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


## The stamp's mark: PASSED between two red rings, the agency over it and the date under it, see
## [StampArt].
func _draw_stamp() -> void:
	StampArt.stamp(
		self, STAMP_AT, STAMP_RADIUS, STAMP_WORD, "DEPT. OF KARTS", issued, STAMP_TURN, STAMP_INK
	)


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
