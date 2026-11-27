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
## whoever reads that far, a cheat code that does nothing. A bot's card is another, see
## [method for_bot].

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
## The band's words, and the class, shown through tr().
const AGENCY := "JACKPOT JUNCTION  ·  DEPT. OF KARTS"
const TITLE := "DRIVER LICENSE"
const CLASS_WORD := "CLASS K"
const CLASS_LINE := "K  ·  Kart"
## How long a license is good for, in years: unreasonably.
const GOOD_FOR := 420
## The fine print along the foot of the front, shown through tr().
const MICRO := "VALID ON ALL TABLES  ·  NOT VALID AS ID  ·  KEEP OFF THE FELT  ·  NO CASH VALUE"
## The stamp's mark, where it lands and how it lies, lower right and askew; its word via tr().
const STAMP_AT := Vector2(474.0, 296.0)
const STAMP_TURN := -0.2
const STAMP_RADIUS := 52.0
const STAMP_WORD := "PASSED"
## The House's stamp after the ending, STORY.md 8.6: its gold rings askew over the lower left
## corner, the way the Department's PASSED is over the lower right.
const HOUSE_STAMP_AT := Vector2(104.0, 290.0)
const HOUSE_STAMP_TURN := 0.24
const HOUSE_STAMP_INK := Color(0.86, 0.66, 0.24, 0.86)
## Writing a field over as the Operator's, as shares of its own part of the writing: struck
## through by this far, the old value gone by this far, the new typed in by this far, and the rest
## drying; and how much of the whole the class and the expiry's parts each take.
const STRIKE := 0.22
const STRUCK := 0.36
const TYPED := 0.82
const REWRITE_OVERLAP := 0.62
## How long the photo takes to turn all the way round, in seconds.
const SPIN_SECONDS := 9.0
## The back: the stripe, the hologram, its shader and how big its mark is in it, the barcode.
const STRIPE := Rect2(Vector2(0.0, 30.0), Vector2(SIZE.x, 44.0))
const STRIPE_INK := Color(0.1, 0.1, 0.12)
## Kit's scratched line, STORY.md 6.7: its lip's shader, its hand, how big and how far off level it
## is and how many times the point went over it, and its groove's shadowed wall, the stock in it
## and the lip.
const SCRATCH_SHINE := preload("res://scenes/tutorial/school/license_scratch.gdshader")
## A hand thin and angular, as a point scratches rather than a pen writes.
const SCRATCH_HAND: Font = preload("res://assets/fonts/ReenieBeanie-Regular.ttf")
const SCRATCH_SIZE := 30
const SCRATCH_TURN := -0.009
const SCRATCH_PASSES := 5
const SCRATCH_GROOVE := Color(0.0, 0.0, 0.0, 0.7)
const SCRATCH_CUT := Color(0.72, 0.68, 0.6)
const SCRATCH_LIP := Color(1.0, 0.98, 0.92)
const HOLOGRAM_AT := Vector2(120.0, 194.0)
const HOLOGRAM_RADIUS := 78.0
const HOLOGRAM_MARK := 68.0
const HOLOGRAM_SHADER := preload("res://scenes/tutorial/school/hologram.gdshader")
const BARCODE := Rect2(Vector2(232.0, 240.0), Vector2(300.0, 56.0))
const BACK_COLUMN := 232.0
## Whose card it is, on the back, shown through tr().
const PROPERTY := "PROPERTY OF THE DEPT. OF KARTS"
## The small print under it, a line each, broken where too long for one, shown through tr().
# TRANSLATORS: The small print on the back of the driving license; a line break is where a line
# runs out of room on the card, about 50 characters a line.
const BACK_LINES: Array[String] = [
	"If found, return to the nearest Junction. Any Junction.",
	"""Valid for Class K karts only. Not transferable, not edible,\nnot a coaster. Keep away from \
pits, turrets and plumbers.""",
	"The holder agrees to drift responsibly, or at least often.",
]
## The cheat code's field, shown through tr().
const CODE := "CHEAT CODE"
## The supporter pack's endorsement, GAME.md 10.8, and the day beside it; what the cheat code does
## and who signs as the examiner, unless the holder does; all shown through tr().
const SUPPORTER := "SUPPORTER"
const SUPPORTER_SINCE := "since %s"
const CODE_LINE := "Does nothing. We checked."
const EXAMINER := "The Examiner"
## A bot's card, GAME.md 9.4a: gray stock, Class B, AUTOMATED where a hand signs, its own fine
## print and class on the back, the examiner waived as it never sat the test; words via tr().
const BOT_PAPER := Color(0.83, 0.85, 0.86)
const BOT_PAPER_LOW := Color(0.7, 0.73, 0.76)
const BOT_CLASS_WORD := "CLASS B"
const BOT_CLASS_LINE := "B  ·  Bot"
const BOT_SIGNED := "AUTOMATED"
const BOT_MICRO := "NOT A PERSON  ·  NOT VALID AS ID  ·  DO NOT FEED"
const BOT_EXAMINER := "WAIVED"
const BOT_BACK_LINE := """Valid for Class B karts only. Not transferable, not edible,\nnot a \
coaster. Keep away from pits, turrets and plumbers."""
## The examiner's red pen note of the cones knocked over, and the back's fine print, via tr().
const CONES := "cones %d"
const BACK_MICRO := """VOID WHERE PROHIBITED. ESPECIALLY THERE.  ·  ISSUED BY A BOT, REVIEWED BY \
NOBODY."""

var holder_name := ""
var number := ""
var issued := ""
var color_index := 0
var style: KartStyle
## The endorsements along the foot, each word to whether it was earned, in order.
var endorsements: Dictionary[String, bool] = {}
## The day the Steam supporter pack was first seen owned here, GAME.md 10.8, for its endorsement
## after the rest; empty where it is not owned.
var supporter_since := ""
## The loyalty program's endorsements, GAME.md 8.9: small rubber stamps in a row under the stripe on
## the back, the exam's being on the front already.
var program_stamps := PackedStringArray()
## Whether the stamp has come down on it.
var stamped := false
## Whether the back is up, see [method other_side].
var flipped := false
## Who signs the back as examiner: the examiner, or after the ending the holder, STORY.md 6.7.
var examiner := EXAMINER
## How many cones the exam it was issued on knocked over, noted on the back in the examiner's red
## pen, GAME.md 9.4a; nothing for none.
var cones := 0
## After the ending, the day the House's stamp came down on it, STORY.md 8.6, and empty before: the
## card is then the Operator's, its class, its expiry and its back the House's.
var approved := ""
## Whether the House's stamp shows on it and its fields read the Operator's, and how far the
## Operator's class and expiry have been written over the old, 0 to 1: all shown and written but
## while the House makes it the Operator's after the ending, see [OperatorStamping].
var house_shown := true:
	set = _set_house_shown
var operator_shown := true:
	set = _set_operator_shown
var rewritten := 1.0:
	set = _set_rewritten
## Whether the story marks it, STORY.md 6.7: a line scratched into its stripe by somebody signing
## K., and its fine print ending HUMAN OVERSIGHT: 0, see [method Story.told_here].
var scratched := false
## Whether it is a bot's, see [method for_bot].
var bot := false
## Where the card is turned toward, -1 to 1 either way, which the hologram's colors run with: set
## by whoever holds the card up, see [TiltedCard].
var tilt := Vector2.ZERO:
	set = _set_tilt

var _photo: SubViewportContainer
var _kart: Node3D
var _mark: LogoArt
var _hologram: ColorRect
## The lip of the scratched line, catching the light as the card turns, see [method _draw_lip].
var _lip: Control


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
	card.scratched = Story.told_here()
	card.cones = Game.settings.profile.license_cones
	if Story.stage_here() == Story.Stage.OPERATOR:
		card.examiner = of
		card.approved = Game.settings.profile.story.final_hand
	return card


## Somebody else's card, from [param said], their license as it came over the wire, see
## [LicenseWire], cleaned here again whoever sent it: as their own card shows it but the story's
## marks, which are theirs to know, GAME.md 10.8. Stamped, as every card issued is.
static func from_wire(said: Dictionary) -> LicenseCard:
	var given := LicenseWire.clean(said)
	var earned: Dictionary[String, bool] = {}
	var words: PackedStringArray = given.get("earned", PackedStringArray())
	for word: String in TutorialFight.ENDORSEMENTS:
		earned[word] = word in words
	var card := create(
		str(given.get("name", "")),
		str(given.get("number", "")),
		str(given.get("issued", "")),
		int(given.get("color", 0)),
		KartStyle.from_array(given.get("style", [])),
		earned
	)
	card.stamped = true
	card.supporter_since = str(given.get("supporter", ""))
	card.program_stamps = LicenseWire.stamps_said(given.get("stamps", PackedStringArray()))
	card.cones = int(given.get("cones", 0))
	card.scratched = false
	card.examiner = EXAMINER
	card.approved = ""
	return card


## A bot's card, GAME.md 9.4a, from [param holder] as [BotLicense] makes it up at this screen:
## its name, serial number and day of issue, its kart in its color and dress, its trait its one
## endorsement, and the stamps on its back. Never the test's PASSED, nor any of the story's marks.
static func for_bot(holder: Dictionary) -> LicenseCard:
	var earned: Dictionary[String, bool] = {}
	for word: Variant in holder.get("earned", []):
		earned[str(word)] = true
	var card := create(
		str(holder.get("name", "")),
		str(holder.get("number", "")),
		str(holder.get("issued", "")),
		int(holder.get("color", 0)),
		KartStyle.from_array(holder.get("style", [])),
		earned
	)
	card.bot = true
	card.program_stamps = PackedStringArray(holder.get("stamps", []))
	card.cones = 0
	card.scratched = false
	card.examiner = BOT_EXAMINER
	card.approved = ""
	return card


func _set_house_shown(value: bool) -> void:
	house_shown = value
	queue_redraw()


func _set_operator_shown(value: bool) -> void:
	operator_shown = value
	queue_redraw()


func _set_rewritten(value: float) -> void:
	rewritten = value
	queue_redraw()


## How many letters of the Operator's class and expiry are written in so far.
func letters_written() -> int:
	var count := 0
	for part: Array in _rewrites():
		var typed := _typed(_rewrite_share(part[2], part[3]))
		count += ceili(String(part[1]).length() * typed)
	return count


## Whether its fields read the Operator's: approved by the House, and shown so.
func reads_operator() -> bool:
	return not approved.is_empty() and operator_shown


## A number for a new license: JJ and six digits, drawn with [param rng].
static func new_number(rng: RandomNumberGenerator) -> String:
	return "JJ-%06d" % rng.randi_range(100000, 999999)  # NO_TRANSLATE


## Today, the way the card writes a date.
static func today() -> String:
	return Time.get_date_string_from_system()


## When a license issued on [param issued] expires: the same day, [constant GOOD_FOR] years on.
static func expiry(issued: String) -> String:
	if issued.length() < 4 or not issued.substr(0, 4).is_valid_int():
		return Lang.t("NEVER")
	return "%04d%s" % [issued.substr(0, 4).to_int() + GOOD_FOR, issued.substr(4)]


## The license this machine holds, as the settings keep it, GAME.md 9.4a, stamped as it was:
## for the title and the settings to show. The kart in the photo is the first seat's.
static func from_settings() -> LicenseCard:
	var settings := Game.settings
	var holder := settings.license_holder
	if holder.is_empty():
		holder = settings.player_names[0]
	if holder.is_empty():
		holder = Lang.t("Player %d") % 1
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
	if Supporter.owned():
		if settings.supporter_since.is_empty():
			settings.supporter_since = today()
			settings.save_to_disk()
		card.supporter_since = settings.supporter_since
	card.program_stamps = Loyalty.endorsements_of(settings.profile)
	# And the laps of the roundabout, GAME.md 8.9.
	if settings.profile.loyalty.laps > 0:
		card.program_stamps.append(Lang.t(LoyaltyCard.LAP) % settings.profile.loyalty.laps)
	return card


func _ready() -> void:
	custom_minimum_size = SIZE
	size = SIZE
	pivot_offset = SIZE * 0.5
	_mark = LogoArt.new()
	_mark.plate = false
	_mark.kept = true
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
	_lip = Control.new()
	_lip.name = "ScratchLip"
	_lip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lip.position = STRIPE.position
	_lip.size = STRIPE.size
	_lip.visible = flipped
	var shine := ShaderMaterial.new()
	shine.shader = SCRATCH_SHINE
	shine.set_shader_parameter("width", STRIPE.size.x)
	_lip.material = shine
	_lip.draw.connect(_draw_lip)
	add_child(_lip)
	ScreenReader.name(self, ScreenReader.spoken(tr(TITLE)), words())


## A picture to a screen reader, or a button where whoever shows it has it take the cursor, as the
## title does, see [ScreenReader].
func _notification(what: int) -> void:
	ScreenReader.drawn(self, what)


## What its face says, as a screen reader is told it: the fields down it under their labels, and
## the endorsements earned.
func words() -> String:
	var held := tr(_class_line())
	var expires := tr(StoryLines.EXPIRES_AFTER) if reads_operator() else expiry(issued)
	var earned := PackedStringArray()
	for word: String in endorsements:
		if endorsements[word]:
			earned.append(tr(word))
	var said := PackedStringArray(
		[
			holder_name,
			tr("Class %s") % held,
			tr("License no. %s") % number,
			tr("Issued %s") % issued,
			tr("Expires %s") % expires,
			tr("Endorsements %s") % ScreenReader.line(earned) if not earned.is_empty() else "",
		]
	)
	return ScreenReader.line(said)


## The class it reads: a bot's, the Operator's after the ending, or the Kart's.
func _class_line() -> String:
	if bot:
		return BOT_CLASS_LINE
	return StoryLines.CLASS_AFTER if reads_operator() else CLASS_LINE


## The kart in the photo dressed as the settings now have it, after the kart dialog has changed
## it, turned as far as it was.
func dress_from_settings() -> void:
	color_index = maxi(Game.settings.seat_color(0), 0)
	style = KartStyle.from_array(Game.settings.kart_styles[0])
	if _kart == null:
		return
	var turned := _kart.rotation.y
	var holder := _kart.get_parent()
	_kart.name = "KartGone"
	_kart.queue_free()
	_kart = KartVisuals.display_model(color_index, style)
	_kart.rotation.y = turned
	_kart.position.y = -0.27
	holder.add_child(_kart)


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
	_lip.visible = flipped
	_lip.queue_redraw()
	queue_redraw()


func _set_tilt(toward: Vector2) -> void:
	tilt = toward
	if _hologram != null:
		(_hologram.material as ShaderMaterial).set_shader_parameter("tilt", toward)
	if _lip != null:
		(_lip.material as ShaderMaterial).set_shader_parameter("tilt", toward)


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
	if not approved.is_empty() and house_shown:
		StampArt.stamp(
			self,
			HOUSE_STAMP_AT,
			STAMP_RADIUS,
			tr(StoryLines.STAMP_WORD),
			tr(StoryLines.STAMP_OVER),
			approved,
			HOUSE_STAMP_TURN,
			HOUSE_STAMP_INK
		)


## The back: the magnetic stripe along the top, the hologram with the mark in it on the left, and
## a column of fields beside it, whose card it is in small print, the examiner's own signature,
## the cheat code and the number as a barcode under them all, with the fine print along the foot.
func _draw_back() -> void:
	draw_rect(STRIPE, STRIPE_INK)
	draw_rect(
		Rect2(STRIPE.position + Vector2(0.0, 6.0), Vector2(STRIPE.size.x, 1.0)),
		Color(1.0, 1.0, 1.0, 0.08)
	)
	var owner := tr(PROPERTY if approved.is_empty() else StoryLines.PROPERTY_AFTER)
	_text(Vector2(BACK_COLUMN, 94.0), owner, Type.STRONG, 11, INK)
	var small: Array[String] = []
	for i: int in BACK_LINES.size():
		var line := BOT_BACK_LINE if bot and i == 1 else BACK_LINES[i]
		small.append_array(tr(line).split("\n"))
	for i: int in small.size():
		_text(Vector2(BACK_COLUMN, 110.0 + float(i) * 14.0), small[i], Type.TEXT, 10, FAINT)
	_text(Vector2(BACK_COLUMN, 168.0), tr("EXAMINER"), Type.STRONG, 8, FAINT)
	var hand := SIGNATURE_FONT
	# A bot's examiner is typed, not signed: nobody examined it. The examiner signs in the language
	# spoken; a holder signing after the ending, by name.
	var signer := tr(examiner) if examiner in [EXAMINER, BOT_EXAMINER] else examiner
	draw_string(
		Type.STRONG if bot else hand,
		Vector2(BACK_COLUMN + 60.0, 184.0),
		signer,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		12 if bot else 14,
		INK if bot else SIGNATURE_INK
	)
	draw_line(
		Vector2(BACK_COLUMN, 190.0), Vector2(BACK_COLUMN + 200.0, 190.0), Color(INK, 0.4), 1.0
	)
	# The cones knocked over, in the examiner's red pen beside the signature.
	if cones > 0:
		draw_string(
			hand,
			Vector2(BACK_COLUMN + 208.0, 186.0),
			tr(CONES) % cones,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			11,
			Color(STAMP_INK, 0.95)
		)
	# The cheat code, a field like the others, for whoever turns the card over and reads the back.
	_text(Vector2(BACK_COLUMN, 200.0), tr(CODE), Type.STRONG, 8, FAINT)
	var at := Vector2(BACK_COLUMN, 212.0)
	for way: float in [0.0, 0.0, 180.0, 180.0, 270.0, 90.0, 270.0, 90.0]:
		IconShapes.tri(self, Rect2(at, Vector2(12.0, 12.0)), 0.5, 0.5, 0.95, way, INK)
		at.x += 15.0
	_text(at + Vector2(2.0, -1.0), "B  A", Type.STRONG, 10, INK)
	_text(at + Vector2(36.0, 1.0), tr(CODE_LINE), Type.TEXT, 8, FAINT)
	_draw_barcode()
	_draw_program_stamps()
	var fine := tr(BACK_MICRO)
	if not approved.is_empty():
		fine = StoryFill.fill(tr(StoryLines.BACK_MICRO_AFTER), Game.settings.profile)
	elif scratched:
		fine += tr(StoryLines.BACK_MICRO_OVERSIGHT)
	if scratched:
		_draw_scratch()
	if _lip != null:
		_lip.queue_redraw()
	_text(
		Vector2(0.0, SIZE.y - 14.0),
		fine,
		Type.STRONG,
		7,
		FAINT,
		HORIZONTAL_ALIGNMENT_CENTER,
		SIZE.x
	)


## Kit's line scratched into the stripe, STORY.md 6.7, as a compass point leaves it in a dark
## finish: each cut a groove with its far wall in shadow and the pale stock showing through it,
## gone over several times a hair apart as a point drags and skips, rough along its edges; and a few
## stray scratches either side where the point slipped. Its lip, catching the light as the card is
## turned, is drawn over it, see [method _draw_lip].
func _draw_scratch() -> void:
	for stroke: Array in _strays():
		var from: Vector2 = stroke[0]
		var to: Vector2 = stroke[1]
		draw_line(from + Vector2(0.6, 0.8), to + Vector2(0.6, 0.8), SCRATCH_GROOVE, 1.4, true)
		draw_line(from, to, Color(SCRATCH_CUT, 0.55), 0.9, true)
	var said := tr(StoryLines.LICENSE_SCRATCH)
	var hand := SCRATCH_HAND
	draw_set_transform(_scratch_start() + Vector2(0.8, 1.1), SCRATCH_TURN, Vector2.ONE)
	draw_string(hand, Vector2.ZERO, said, 0, -1, SCRATCH_SIZE, SCRATCH_GROOVE)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(number) + 3
	for i: int in SCRATCH_PASSES:
		var off := Vector2(rng.randf_range(-0.7, 0.7), rng.randf_range(-0.6, 0.6))
		var turn := SCRATCH_TURN + rng.randf_range(-0.006, 0.006)
		draw_set_transform(_scratch_start() + off, turn, Vector2.ONE)
		var ink := Color(SCRATCH_CUT, 0.6 if i == 0 else 0.3)
		draw_string(hand, Vector2.ZERO, said, 0, -1, SCRATCH_SIZE, ink)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The near lip of every cut on the scratch's own layer, drawn white for its shader to light as the
## card turns: a glint running along the line, and a faint gleam everywhere else.
func _draw_lip() -> void:
	if not scratched or not flipped:
		return
	var at := _scratch_start() - STRIPE.position + Vector2(-0.6, -0.7)
	_lip.draw_set_transform(at, SCRATCH_TURN, Vector2.ONE)
	var said := tr(StoryLines.LICENSE_SCRATCH)
	_lip.draw_string(SCRATCH_HAND, Vector2.ZERO, said, 0, -1, SCRATCH_SIZE, SCRATCH_LIP)
	_lip.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for stroke: Array in _strays():
		var from: Vector2 = stroke[0] - STRIPE.position - Vector2(0.4, 0.5)
		var to: Vector2 = stroke[1] - STRIPE.position - Vector2(0.4, 0.5)
		_lip.draw_line(from, to, Color(SCRATCH_LIP, 0.6), 0.7, true)


## Where the scratched line starts on the card.
func _scratch_start() -> Vector2:
	return STRIPE.position + Vector2(24.0, STRIPE.size.y * 0.66)


## Where the point slipped: stray scratches either side of the line, the same every time.
func _strays() -> Array[Array]:
	var strokes: Array[Array] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(number) + 7
	for i: int in 9:
		var from := (
			STRIPE.position + Vector2(rng.randf_range(16.0, 470.0), rng.randf_range(8.0, 36.0))
		)
		var to := from + Vector2.from_angle(rng.randf_range(-0.5, 0.5)) * rng.randf_range(6.0, 22.0)
		strokes.append([from, to])
	return strokes


## The loyalty program's endorsements in a row under the stripe, each a small rubber stamp in the
## driving test's red, laid a little askew as the PASSED mark is, GAME.md 8.9.
func _draw_program_stamps() -> void:
	# Left of the back's column, between the stripe and the hologram.
	var x := 10.0
	for i: int in program_stamps.size():
		var word := program_stamps[i]
		var wide := Type.STRONG.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x + 10.0
		var box := Rect2(Vector2(-wide * 0.5, -8.0), Vector2(wide, 16.0))
		var turn := -0.07 if i % 2 == 0 else 0.05
		draw_set_transform(Vector2(x + wide * 0.5, 92.0), turn, Vector2.ONE)
		draw_rect(box, STAMP_INK, false, 1.5)
		draw_rect(box.grow(-2.0), Color(STAMP_INK, 0.5), false, 0.7)
		draw_string(
			Type.STRONG,
			Vector2(-wide * 0.5, 2.6),
			word,
			HORIZONTAL_ALIGNMENT_CENTER,
			wide,
			7,
			STAMP_INK
		)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		x += wide + 4.0


## The number as a barcode, see [Barcode].
func _draw_barcode() -> void:
	Barcode.draw(self, BARCODE, number, INK)


## The paper: cream, darker toward the foot, with the fine curves a banknote wears and the four
## suits as a watermark.
func _draw_paper() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = BOT_PAPER if bot else PAPER
	style.set_corner_radius_all(roundi(RADIUS))
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	style.shadow_size = 16
	draw_style_box(style, Rect2(Vector2.ZERO, SIZE))
	var low := StyleBoxFlat.new()
	low.bg_color = Color(BOT_PAPER_LOW if bot else PAPER_LOW, 0.5)
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
		JokerSuits.draw_filled(self, Rect2(at, Vector2(60.0, 60.0)), suit, watermark)


## The band along the top: the agency over the title, with the class on the right.
func _draw_band() -> void:
	var band := StyleBoxFlat.new()
	band.bg_color = BAND
	band.corner_radius_top_left = roundi(RADIUS)
	band.corner_radius_top_right = roundi(RADIUS)
	draw_style_box(band, Rect2(Vector2.ZERO, Vector2(SIZE.x, BAND_HEIGHT)))
	draw_rect(Rect2(Vector2(0.0, BAND_HEIGHT), Vector2(SIZE.x, 3.0)), Palette.CHIP_GOLD)
	_text(Vector2(72.0, 12.0), tr(AGENCY), Type.STRONG, 11, Color(0.86, 0.84, 0.78))
	_text(Vector2(72.0, 27.0), tr(TITLE), Type.display_font(), 25, Palette.CHIP_GOLD)
	var chip := StyleBoxFlat.new()
	chip.bg_color = Palette.CHIP_GOLD
	chip.set_corner_radius_all(6)
	var chip_rect := Rect2(Vector2(SIZE.x - 98.0, 20.0), Vector2(80.0, 24.0))
	draw_style_box(chip, chip_rect)
	_text(
		chip_rect.position + Vector2(0.0, 5.0),
		tr(BOT_CLASS_WORD if bot else CLASS_WORD),
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
		tr("PHOTO"),
		Type.STRONG,
		9,
		FAINT,
		HORIZONTAL_ALIGNMENT_CENTER,
		PHOTO.size.x
	)


## The fields down the right of the photo: the name large, then the class, the dates and the
## number, each under a small label.
func _draw_fields() -> void:
	var name_word := tr("NAME")
	_field(Vector2(COLUMN, 80.0), name_word, holder_name, 30, Type.display_font(), RIGHT - COLUMN)
	var held := tr(_class_line())
	var class_word := tr("CLASS")
	if reads_operator() and rewritten < 1.0:
		_rewrite(Vector2(COLUMN, 134.0), class_word, Type.STRONG, _rewrites()[0])
	else:
		_field(Vector2(COLUMN, 134.0), class_word, held, 19, Type.STRONG, 160.0)
	var numbered := tr("LICENSE NO.")
	_field(Vector2(COLUMN + 168.0, 134.0), numbered, number, 19, Type.numbers_text_font(), 166.0)
	_field(Vector2(COLUMN, 180.0), tr("ISSUED"), issued, 19, Type.numbers_text_font(), 160.0)
	var expires_at := Vector2(COLUMN + 168.0, 180.0)
	if reads_operator() and rewritten < 1.0:
		_rewrite(expires_at, tr("EXPIRES"), Type.numbers_text_font(), _rewrites()[1])
	else:
		_field(
			expires_at,
			tr("EXPIRES"),
			tr(StoryLines.EXPIRES_AFTER) if reads_operator() else expiry(issued),
			19,
			Type.numbers_text_font(),
			166.0
		)


## The Operator's class and expiry as they are written over the old: each its old value, its new
## one, and the part of [member rewritten] it is written over in.
func _rewrites() -> Array[Array]:
	return [
		[tr(CLASS_LINE), tr(StoryLines.CLASS_AFTER), 0.0, REWRITE_OVERLAP],
		[expiry(issued), tr(StoryLines.EXPIRES_AFTER), 1.0 - REWRITE_OVERLAP, 1.0],
	]


## How far through its own writing over a field is, 0 to 1, between [param from] and [param to] of
## [member rewritten].
func _rewrite_share(from: float, to: float) -> float:
	return clampf((rewritten - from) / maxf(to - from, 0.01), 0.0, 1.0)


## How much of the new value is typed in, at [param share] of the way through a field's writing.
static func _typed(share: float) -> float:
	return clampf((share - STRUCK) / (TYPED - STRUCK), 0.0, 1.0)


## A field being written over as the Operator's, STORY.md 8.6, [param part] of [method _rewrites]:
## the old value struck through in the House's gold and faded out, then the new one typed in, a
## letter at a time, in gold that dries to ink.
func _rewrite(at: Vector2, label: String, font: Font, part: Array) -> void:
	var share := _rewrite_share(part[2], part[3])
	var old_value: String = part[0]
	var new_value: String = part[1]
	_text(at, label, Type.STRONG, 10, FAINT)
	var value_at := at + Vector2(0.0, 14.0)
	var strike := clampf(share / STRIKE, 0.0, 1.0)
	var gone := clampf((share - STRIKE) / (STRUCK - STRIKE), 0.0, 1.0)
	if gone < 1.0:
		_text(value_at, old_value, font, 19, Color(INK, 1.0 - gone))
		var wide := font.get_string_size(old_value, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x + 6.0
		var y := value_at.y + font.get_ascent(19) * 0.6
		var ink := Color(HOUSE_STAMP_INK, HOUSE_STAMP_INK.a * (1.0 - gone))
		draw_line(
			Vector2(value_at.x - 3.0, y), Vector2(value_at.x - 3.0 + wide * strike, y), ink, 2.0
		)
	var typed := _typed(share)
	if typed <= 0.0:
		return
	var letters := new_value.substr(0, ceili(new_value.length() * typed))
	var dry := clampf((share - TYPED) / (1.0 - TYPED), 0.0, 1.0)
	_text(value_at, letters, font, 19, HOUSE_STAMP_INK.lerp(INK, dry))


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
	_text(Vector2(COLUMN, top), tr("ENDORSEMENTS"), Type.STRONG, 10, FAINT)
	var x := COLUMN
	var y := top + 16.0
	var font := Type.STRONG
	for id: String in endorsements:
		var word := tr(id)
		var wide := font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 14.0
		if x + wide > RIGHT:
			x = COLUMN
			y += 24.0
		var chip := StyleBoxFlat.new()
		chip.set_corner_radius_all(5)
		var earned: bool = endorsements[id]
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
	if not supporter_since.is_empty():
		_draw_supporter(Vector2(x, y), font)


## The supporter pack's endorsement, GAME.md 10.8, from [param at] on: a night-blue chip with the
## pack's star and SUPPORTER in cream, the day it was first seen beside it, on the next row where
## this one has no room.
func _draw_supporter(at: Vector2, font: Font) -> void:
	var supporter := tr(SUPPORTER)
	var wide := font.get_string_size(supporter, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 30.0
	var since := tr(SUPPORTER_SINCE) % supporter_since
	var dated := font.get_string_size(since, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 6.0
	if at.x + wide + dated > RIGHT:
		at = Vector2(COLUMN, at.y + 24.0)
	var chip := StyleBoxFlat.new()
	chip.set_corner_radius_all(5)
	chip.bg_color = PartTray.SUPPORTER_TAPE
	var rect := Rect2(at, Vector2(wide, 19.0))
	draw_style_box(chip, rect)
	var star := PackedVector2Array()
	for i: int in 8:
		var reach := 6.0 if i % 2 == 0 else 1.8
		star.append(rect.position + Vector2(11.0, 9.5) + Vector2.UP.rotated(TAU * i / 8.0) * reach)
	draw_colored_polygon(star, PartTray.SUPPORTER_STAR)
	_text(rect.position + Vector2(20.0, 3.0), supporter, font, 10, PartTray.SUPPORTER_WORDS)
	_text(rect.position + Vector2(wide + 6.0, 5.0), since, font, 8, FAINT)


## The holder's signature: their name slanted in blue ink over a line under the photo.
func _draw_signature() -> void:
	var line_y := 292.0
	draw_line(Vector2(26.0, line_y), Vector2(176.0, line_y), Color(INK, 0.5), 1.0)
	_text(Vector2(26.0, line_y + 3.0), tr("SIGNATURE"), Type.STRONG, 8, FAINT)
	if bot:
		_draw_automated(Vector2(101.0, line_y - 14.0))
		return
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


## A bot's signature: AUTOMATED printed in a ruled box centered on [param at], a little askew,
## where a hand would sign.
func _draw_automated(at: Vector2) -> void:
	var box := Rect2(Vector2(-62.0, -11.0), Vector2(124.0, 22.0))
	draw_set_transform(at, -0.05, Vector2.ONE)
	draw_rect(box, Color(SIGNATURE_INK, 0.85), false, 1.5)
	draw_rect(box.grow(-2.5), Color(SIGNATURE_INK, 0.4), false, 0.8)
	var at_line := Vector2(box.position.x, Type.STRONG.get_ascent(12) * 0.5 - 1.0)
	var word := tr(BOT_SIGNED)
	draw_string(
		Type.STRONG, at_line, word, HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 12, SIGNATURE_INK
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_micro() -> void:
	_text(
		Vector2(0.0, SIZE.y - 18.0),
		tr(BOT_MICRO if bot else MICRO),
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
		self,
		STAMP_AT,
		STAMP_RADIUS,
		tr(STAMP_WORD),
		tr("DEPT. OF KARTS"),
		issued,
		STAMP_TURN,
		STAMP_INK
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
