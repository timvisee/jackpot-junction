class_name LoyaltyPane
extends PanelContainer
## The pane beside the loyalty program's map, GAME.md 8.9: a slip of the House's cream paper bound
## along its top by a wire coil, torn along its foot, see [AtlasSlipStyle], describing the
## landmark under the cursor in ink, its district's word in its district's color. Its name and its
## district, a dotted line, the bet and how far it has come, what it pays with the picture of each,
## the cards it adds and its part of the dress; and for a closed one, which shows what it pays but
## not what it asks, which roads would open it, on the plans: on blueprint paper, its words in
## white, stamped CONCEPT, a keystone's sealed, see [AtlasStamp]. On Kit's sheet, open or not, a
## scrap of his graph paper is taped over the slip and it is written in his hand, see
## [AtlasKitScrap].

## The roundabout's edition asked for, from its pane's button.
signal edition_asked
## The Pin button was pressed: what the pane says to be pinned, or unpinned.
signal pin_asked

const WIDTH := 380.0
## How tall the room for the dotted line under the header is.
const TEAR := 14.0
## The page turned over the coil as the details change, see [method _turn_page]: how long it
## takes; the way across the page the fold sweeps, from the foot's right corner toward the top's
## left; how round its roll is, as a share of the slip's height, at the start and the end and how
## much rounder halfway; how far off the eye is, as a share of the slip's height, so the roll comes
## a little nearer and wider as it rises; how many squares across and down the page is bent in; how
## far past the slip's sides and foot the page may be seen, folded over; the shade of its blank
## back; how dark the roll's shadow is; and the leaf's sound, quiet, as it starts.
const TURN := 0.55
const TURN_FOLD := Vector2(0.45, 1.0)
const TURN_ROLL := 0.05
const TURN_ROLL_GROW := 0.06
const TURN_EYE := 6.0
const TURN_ACROSS := 14
const TURN_DOWN := 18
const TURN_ROOM := 60.0
## How far down from the coil the page turning starts to fade as it comes up over it, clear of the
## page's name, and how far past it it is gone, under the coil.
const TURN_FADE := 30.0
const TURN_FADE_OVER := 10.0
const TURN_BACK := Color(0.95, 0.92, 0.84)
## A blueprint page's back as it turns, see [member AtlasSlipStyle.planned]: blue as its face, the
## grid on it in a picture of one square of the grid's heavier lines, tiled, the paper this much of
## white in it so the lines can be lighter than the paper, its lighter lines this much and its
## heavier ones white.
const TURN_PLAN_BACK := AtlasSlipStyle.PLAN_PAPER
const TURN_GRID_PAPER := 0.85
const TURN_GRID_LIGHT := 0.93
## How strongly what is printed on a turning page's face shows through its back, as through paper.
const TURN_THROUGH := 0.16
const TURN_SHADOW := 0.32
const TURN_SOUND := -14.0
const TURN_SOUND_GAP := 90
## Its ink on the paper, and the fainter ink of what is said about the rest; and the same on the
## blueprint paper of a page on the plans.
const INK := HouseTheme.INK
const HINT := HouseTheme.INK_FAINT
const PLAN_INK := Color("#f2f6ff")
const PLAN_HINT := Color(0.85, 0.9, 1.0, 0.75)
## Kit's pencil and its fainter strokes, and his hand, a little bigger than the print it stands in
## for, as it runs small.
const KIT_INK := Color(0.22, 0.22, 0.25, 0.92)
const KIT_HINT := Color(0.22, 0.22, 0.25, 0.6)
const KIT_HAND := NotePage.HAND
const KIT_HAND_SIZE := 1.3
## The words for each district, as the pane's header says them, and each one's color there, as
## the map has it; printed on the paper, see [method HouseTheme.on_paper].
const DISTRICTS := {
	LoyaltyLandmark.District.SLIP: ["", HouseTheme.INK],
	LoyaltyLandmark.District.STRIP: ["The Strip", HouseTheme.FOIL],
	LoyaltyLandmark.District.DEPARTMENT: ["Dept. of Karts", Color("#3f6fd0")],
	LoyaltyLandmark.District.OFF_THE_BOOKS: ["Off the books", Color(0.42, 0.42, 0.45)],
}
## How it stands, said over its bet.
const CLOSED := "Closed"
const OPEN := "Open"
const WON := "Won"
const KEYSTONE := "Keystone"
## What a closed one says in its bet's place, which is not said until a road into it is won.
const ASKS_LATER := "Objective hidden until unlocked."
## What a closed one needs: any road in, or for a keystone every one.
const OPENS_BY := "Opens with a road from %s."
const OPENS_BY_ALL := "Opens once every road in is won: %s."
const OR := " or "
const AND := " and "
const PAYS := "PAYS"
## The words for each kind of dress a landmark pays, by the name it gives it.
const PARTS := {
	&"paint": "Paint",
	&"hat": "Hat",
	&"flag": "Flag",
	&"trail": "Trail",
	&"frame": "Plate",
	&"marks": "Tire marks",
	&"card_back": "Card back",
}
const SHOWROOM := "The Showroom, a bay off the Garage"
const NOTE := "A loose note"
const ONTO_THE_MAP := "The roads onto the map"
const CARD := "Joker card: %s"
const ITEM := "Power-up: %s"
const PICTURE := 34.0
## The roundabout's pane: its name and place, how it opens, a lap's bets and what a lap pays.
const ROUNDABOUT := "The Roundabout"
const POT := "JACKPOT"
const LAP := "LAP %d"
const RING_OPENS := "Opens once %s are won."
const RING_ASKS := "Win all seven bets of the ring to go round."
const RING_COME := "%d of %d won"
const RING_PAYS := "An edition: a piece of your dress moves up a finish"
const EDITION := "Choose an edition (%d)"
## Pinning what the pane says, GAME.md 8.9: the button's words for it unpinned and pinned, and its
## bind for keys and pads.
const PIN := "Pin"
const PINNED := "Pinned"
const PIN_ACTION := &"ui_accept"

const CATALOG: JokerCatalog = preload("res://data/jokers/catalog.tres")
const FIRST: PowerUpTable = preload("res://data/powerups/first_set.tres")
const LATER: PowerUpTable = preload("res://data/powerups/later_set.tres")


## The wire coil binding the slip along its top, over what is printed on it: one picture of it
## for the slip's width, see [method AtlasCover.piece], so it costs a draw.
class Coil:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_to_group(AtlasCover.PICTURES)
		resized.connect(queue_redraw)

	func _draw() -> void:
		var wide := roundf(get_parent_control().size.x)
		AtlasCover.piece(self, AtlasCover.Kind.COIL, -position, 0.0, wide)


## The page turning over the coil, see [method LoyaltyPane._turn_page], as a pad's page is turned
## by its foot's right corner: the page bent round a roll along a slanting fold that sweeps from
## that corner up past the coil, its face flat on the near side of the fold, curving away round the
## roll and its blank back coming round and lying flat over what is left of its face, the next page
## showing from under it; and gone over the coil, fading out as it comes up to it, under the coil
## by the time it is gone, rather than cut off at an edge: drawn by [Sheet] through a gradient
## this draws, clear over the coil and solid a little way under it. Drawn from the picture of the
## slip as it was, as a mesh across it bent round the roll and seen from an eye over it, the higher
## the nearer: its face in one draw and its back in another, shaded as they face the light, and the
## roll's shadow on the page under it.
class Turning:
	extends Control

	static var _grid: Texture2D

	## How far through its turn the page is, none while none turns; where the slip is in this, the
	## picture of the page, and how many of its pixels are one of the slip's.
	var by := -1.0
	var page: Rect2
	var picture: Texture2D
	var scale_by := 1.0
	## Whether the page turning is a blueprint, see [member AtlasSlipStyle.planned], its back
	## blueprint too.
	var planned := false

	var _sheet: Sheet

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Only what the sheet draws is seen, through this one's gradient.
		clip_children = CanvasItem.CLIP_CHILDREN_ONLY
		_sheet = Sheet.new()
		_sheet.name = "Sheet"
		add_child(_sheet)
		_sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		# Hidden while no page turns: drawing through the gradient costs a pass of its own every
		# frame, whether or not anything is drawn through it.
		visible = false

	## Drawn again, the gradient and the page through it, and shown only while a page turns.
	func refresh() -> void:
		visible = by >= 0.0
		queue_redraw()
		_sheet.queue_redraw()

	## The gradient the page is seen through: clear over the coil, solid from a little way under it,
	## a smooth fade between.
	func _draw() -> void:
		if by < 0.0:
			return
		var gone := page.position.y - LoyaltyPane.TURN_FADE_OVER
		var full := page.position.y + LoyaltyPane.TURN_FADE
		var clear := Color(1.0, 1.0, 1.0, 0.0)
		var band := PackedVector2Array(
			[Vector2(0.0, gone), Vector2(size.x, gone), Vector2(size.x, full), Vector2(0.0, full)]
		)
		draw_polygon(band, PackedColorArray([clear, clear, Color.WHITE, Color.WHITE]))
		draw_rect(Rect2(0.0, full, size.x, size.y - full), Color.WHITE)

	## The page on [param on] as far through its turn as it is.
	func draw_page(on: CanvasItem) -> void:
		if by < 0.0 or picture == null:
			return
		var wide := page.size.x
		var tall := page.size.y
		var toward := LoyaltyPane.TURN_FOLD.normalized()
		var roll := tall * (LoyaltyPane.TURN_ROLL + LoyaltyPane.TURN_ROLL_GROW * sin(by * PI))
		# The fold sweeps from past the foot's right corner to past the coil, all of it gone over.
		var start := Vector2(wide, tall).dot(toward)
		var fold := lerpf(start, -PI * roll - 2.0, by)
		_shadow(on, toward, fold + roll, roll)
		var across := LoyaltyPane.TURN_ACROSS
		var down := LoyaltyPane.TURN_DOWN
		var points := PackedVector2Array()
		var face := PackedColorArray()
		var back := PackedColorArray()
		var uvs := PackedVector2Array()
		var uv_scale := Vector2(wide, tall) * scale_by / picture.get_size()
		var grid_uvs := PackedVector2Array()
		var grid_span := AtlasSlipStyle.PLAN_GRID_STEP * AtlasSlipStyle.PLAN_GRID_EVERY
		var through_uvs := PackedVector2Array()
		var through := PackedColorArray()
		for row: int in down + 1:
			for column: int in across + 1:
				var flat := Vector2(wide * column / across, tall * row / down)
				var along := flat.dot(toward)
				var past := along - fold
				var bent := along
				var high := 0.0
				var turn := 0.0
				if past > PI * roll:
					turn = PI
					bent = fold - (past - PI * roll)
					high = roll * 2.0
				elif past > 0.0:
					turn = past / roll
					bent = fold + roll * sin(turn)
					high = roll * (1.0 - cos(turn))
				points.append(_seen(flat + toward * (bent - along), high))
				var lit := 0.62 + 0.38 * maxf(cos(turn), 0.0)
				face.append(Color(lit, lit, lit))
				var shade := _back_paper() * (0.62 + 0.38 * maxf(-cos(turn), 0.0))
				shade.a = 1.0
				back.append(shade)
				uvs.append(Vector2(column / float(across), row / float(down)) * uv_scale)
				through_uvs.append(
					Vector2(1.0 - column / float(across), row / float(down)) * uv_scale
				)
				through.append(Color(1.0, 1.0, 1.0, LoyaltyPane.TURN_THROUGH))
				grid_uvs.append(flat / grid_span)
		# Each triangle its face or its back by which way round the eye sees it.
		var faces := PackedInt32Array()
		var backs := PackedInt32Array()
		for row: int in down:
			for column: int in across:
				var a := row * (across + 1) + column
				for triangle: Array in [
					[a, a + 1, a + across + 2], [a, a + across + 2, a + across + 1]
				]:
					var one: Vector2 = points[triangle[0]]
					var turned := (points[triangle[1]] - one).cross(points[triangle[2]] - one)
					var into := faces if turned > 0.0 else backs
					into.append_array(PackedInt32Array(triangle))
		var item := on.get_canvas_item()
		if not faces.is_empty():
			RenderingServer.canvas_item_add_triangle_array(
				item,
				faces,
				points,
				face,
				uvs,
				PackedInt32Array(),
				PackedFloat32Array(),
				picture.get_rid()
			)
		if not backs.is_empty() and planned:
			RenderingServer.canvas_item_add_triangle_array(
				item,
				backs,
				points,
				back,
				grid_uvs,
				PackedInt32Array(),
				PackedFloat32Array(),
				grid().get_rid()
			)
		elif not backs.is_empty():
			RenderingServer.canvas_item_add_triangle_array(item, backs, points, back)
		# What is printed on its face showing through its back, the wrong way round.
		if not backs.is_empty():
			RenderingServer.canvas_item_add_triangle_array(
				item,
				backs,
				points,
				through,
				through_uvs,
				PackedInt32Array(),
				PackedFloat32Array(),
				picture.get_rid()
			)

	## The paper of the page's back: the House's, or a blueprint's blue, made lighter by as much as
	## the grid's picture darkens it, see [method grid].
	func _back_paper() -> Color:
		if not planned:
			return LoyaltyPane.TURN_BACK
		var blue := LoyaltyPane.TURN_PLAN_BACK / LoyaltyPane.TURN_GRID_PAPER
		blue.a = 1.0
		return blue

	## One square of the blueprint's grid as a picture to tile, its heavier lines along its top and
	## its left and the lighter ones between, the paper a little gray, see
	## [constant LoyaltyPane.TURN_GRID_PAPER].
	static func grid() -> Texture2D:
		if _grid == null:
			var step := int(AtlasSlipStyle.PLAN_GRID_STEP)
			var side := step * AtlasSlipStyle.PLAN_GRID_EVERY
			var image := Image.create(side, side, false, Image.FORMAT_L8)
			image.fill(Color.WHITE * LoyaltyPane.TURN_GRID_PAPER)
			for at: int in side:
				for line: int in range(0, side, step):
					var level := 1.0 if line == 0 else LoyaltyPane.TURN_GRID_LIGHT
					var ink := Color(level, level, level)
					image.set_pixel(line, at, ink)
					image.set_pixel(at, line, ink)
			_grid = ImageTexture.create_from_image(image)
		return _grid

	## Where the eye sees a point of the page at [param at] across it, [param high] over it: drawn
	## out from under the eye the further, the higher it is.
	func _seen(at: Vector2, high: float) -> Vector2:
		var eye := page.size * 0.5
		var far := page.size.y * LoyaltyPane.TURN_EYE
		return page.position + eye + (at - eye) * far / maxf(far - high, 1.0)

	## The shadow the roll throws on the page under it beyond the fold, from [param edge] along
	## [param toward], a soft band as deep as the roll is round, cut to the slip.
	func _shadow(on: CanvasItem, toward: Vector2, edge: float, roll: float) -> void:
		var side := Vector2(toward.y, -toward.x) * (page.size.length() + roll)
		var line := toward * edge
		var deep := toward * roll * 1.6
		var band := PackedVector2Array(
			[line - side, line + side, line + side + deep, line - side + deep]
		)
		var dark := Color(0.0, 0.0, 0.0, LoyaltyPane.TURN_SHADOW)
		var clear := Color(0.0, 0.0, 0.0, 0.0)
		var slip := PackedVector2Array(
			[Vector2.ZERO, Vector2(page.size.x, 0.0), page.size, Vector2(0.0, page.size.y)]
		)
		for piece: PackedVector2Array in Geometry2D.intersect_polygons(band, slip):
			var colors := PackedColorArray()
			for point: Vector2 in piece:
				var into := clampf((point.dot(toward) - edge) / maxf(roll * 1.6, 1.0), 0.0, 1.0)
				colors.append(dark.lerp(clear, into))
			var moved := PackedVector2Array()
			for point: Vector2 in piece:
				moved.append(point + page.position)
			on.draw_polygon(moved, colors)


## What draws the page turning, see [Turning], through its gradient.
class Sheet:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		# The blueprint's grid tiled over its back.
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

	func _draw() -> void:
		(get_parent() as Turning).draw_page(self)


## The coil drawn over the page turning, which is drawn away from the slip, see
## [method LoyaltyPane.turn_on]: at the slip's top left corner, as wide as the slip.
class TurnCoil:
	extends Control

	var wide := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_to_group(AtlasCover.PICTURES)

	func _draw() -> void:
		AtlasCover.piece(self, AtlasCover.Kind.COIL, Vector2.ZERO, 0.0, wide)


## A picture of one thing a landmark pays, square in its room: [member draw_with] is called with
## the canvas and the box, the rest of what it needs bound to it.
class Picture:
	extends Control

	var draw_with: Callable

	func _draw() -> void:
		var side := minf(size.x, size.y)
		draw_with.call(self, Rect2((size - Vector2.ONE * side) * 0.5, Vector2.ONE * side))


## The landmark the pane says, by id.
var shown: StringName
## Whether its page turns over the coil as what it says changes; the dialog's does.
var turns := false
## The button that pins what the pane says, see [signal pin_asked].
var pin: Button

var _style: AtlasSlipStyle
var _name: Label
var _district: Label
var _standing: Label
var _bet: Label
var _bar: ProgressBar
var _come: Label
var _opens: Label
var _pays: VBoxContainer
var _ring: VBoxContainer
var _edition: Button
var _box: VBoxContainer
var _tear: Control
var _pays_heading: Label
## Whether what it says is on the plans, not open yet, and what is stamped on it then; whether it
## is Kit's, and his scrap over it then; and each of its lines' own font and size, to go back to
## from his hand.
var _planned := false
var _stamp: AtlasStamp
var _kit := false
var _scrap: AtlasKitScrap
var _later: AtlasKitScrap.Later
var _fonts: Dictionary[Label, Array] = {}
var _wide := WIDTH
## The page turning over the coil, made the first time one turns, the picture it is drawn into
## while it turns, and what draws it, between what is printed and the coil, so the coil stays over
## it; when the leaf's sound last played.
var _page: LoyaltyPane
var _page_view: SubViewport
var _page_size := Vector2.ZERO
var _turning: Turning
var _turn_coil: TurnCoil
var _turn: Tween
var _sounded_at := -TURN_SOUND_GAP


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Plain paper, without the waves and the arcs a slip has engraved: a hundred draws a frame more
	# as it goes from landmark to landmark, GAME.md 10.7, and the cover is busy enough round it.
	_style = AtlasSlipStyle.new()
	add_theme_stylebox_override("panel", _style)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 10)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)
	# Kit's scrap under what is written, over the slip.
	_scrap = AtlasKitScrap.new()
	_scrap.name = "Scrap"
	add_child(_scrap)
	move_child(_scrap, 0)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 14)
	_box.add_child(heading)
	_name = _line(28, INK)
	_name.name = "Name"
	Type.set_font(_name, Type.display_font(), 28)
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_child(_name)
	_district = _line(16, INK)
	_district.name = "District"
	Type.set_font(_district, Type.STRONG, 16)
	_district.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.add_child(_district)
	# The room the slip's dotted line runs across, which it is told of wherever it goes.
	_tear = Control.new()
	_tear.name = "Tear"
	_tear.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tear.custom_minimum_size = Vector2(WIDTH, TEAR)
	_tear.item_rect_changed.connect(_tell_tear)
	_box.add_child(_tear)
	_standing = _line(15, HINT)
	_standing.name = "Standing"
	Type.set_font(_standing, Type.STRONG, 15)
	_box.add_child(_standing)
	_bet = _line(20, INK)
	_bet.name = "Bet"
	_bet.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bet.custom_minimum_size.x = WIDTH
	_box.add_child(_bet)
	_bar = ProgressBar.new()
	_bar.name = "Bar"
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(WIDTH, 10.0)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ink_bar(_bar)
	_box.add_child(_bar)
	_come = _line(16, HINT)
	_come.name = "Come"
	_box.add_child(_come)
	var pays := _line(14, HINT)
	_pays_heading = pays
	pays.text = PAYS
	Type.set_font(pays, Type.STRONG, 14)
	_box.add_child(pays)
	_pays = VBoxContainer.new()
	_pays.name = "Pays"
	_pays.add_theme_constant_override("separation", 8)
	_pays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(_pays)
	_opens = _line(16, HINT)
	_opens.name = "Opens"
	_opens.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_opens.custom_minimum_size.x = WIDTH
	_box.add_child(_opens)
	_ring = VBoxContainer.new()
	_ring.name = "Ring"
	_ring.add_theme_constant_override("separation", 4)
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(_ring)
	_edition = MenuTheme.button("", Type.BODY)
	_edition.theme_type_variation = HouseTheme.PAPER_PRIMARY
	_edition.name = "Edition"
	_edition.focus_mode = Control.FOCUS_NONE
	_edition.pressed.connect(func() -> void: edition_asked.emit())
	ButtonBinds.mark(_edition, PIN_ACTION)
	_edition.visible = false
	_box.add_child(_edition)
	pin = MenuTheme.button(PIN, Type.LABEL)
	AtlasTicketStyle.dress(pin)
	pin.custom_minimum_size.y = 0.0 if not TouchInput.enabled else pin.custom_minimum_size.y
	pin.name = "Pin"
	pin.icon = HouseArt.pin()
	pin.toggle_mode = true
	pin.focus_mode = Control.FOCUS_NONE
	pin.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	pin.custom_minimum_size.x = 160.0
	pin.pressed.connect(func() -> void: pin_asked.emit())
	ButtonBinds.mark(pin, PIN_ACTION)
	pin.visible = false
	_box.add_child(pin)
	_turning = Turning.new()
	_turning.name = "Turning"
	add_child(_turning)
	_later = AtlasKitScrap.Later.new()
	_later.name = "Later"
	_later.over = _bet
	_later.beside = _pays_heading
	add_child(_later)
	_stamp = AtlasStamp.new()
	_stamp.name = "Stamp"
	_stamp.over = _bet
	_stamp.paper = AtlasSlipStyle.PLAN_PAPER
	add_child(_stamp)
	var coil := Coil.new()
	coil.name = "Coil"
	add_child(coil)
	for line: Label in [_name, _district, _standing, _bet, _come, _opens, _pays_heading]:
		var font: Font = (
			line.get_theme_font(&"font") if line.has_theme_font_override(&"font") else null
		)
		_fonts[line] = [font, line.get_theme_font_size(&"font_size")]


## Fills the pane for the roundabout on [param profile]'s map, GAME.md 8.9: shut, which keystones
## open it; open, its lap, the ring's seven bets with how far each has come, what a lap pays, and
## the button to choose an edition while one is owed.
func show_roundabout(profile: Profile) -> void:
	_turn_page(profile, Loyalty.ROUNDABOUT)
	shown = Loyalty.ROUNDABOUT
	_name.text = ROUNDABOUT
	_district.text = POT
	var open := Loyalty.ring_open(profile)
	_plan(not open, false)
	_wear(HouseTheme.FOIL)
	_clear_rows()
	var state := profile.loyalty
	var standing := CLOSED
	if open:
		standing = LAP % state.laps if state.laps > 0 else OPEN
	_standing.text = standing.to_upper()
	_opens.visible = not open
	if not open:
		var keystones := PackedStringArray()
		for each: LoyaltyLandmark in Loyalty.map().landmarks:
			if each.keystone and Loyalty.map().reaches_roundabout(each.id):
				keystones.append(each.title)
		_opens.text = RING_OPENS % _listed(keystones, AND)
	_bet.text = RING_ASKS if open else ASKS_LATER
	_bet.add_theme_color_override("font_color", _ink() if open else _hint())
	var met := 0
	for bet: Dictionary in state.ring:
		var come := Loyalty.ring_progress(profile, bet)
		met += 1 if come.x >= come.y else 0
		if open:
			var line := _line(16, INK if come.x < come.y else HINT)
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			line.text = "%s  ·  %s" % [Loyalty.ring_bet_of(bet), _so_far(profile, bet)]
			_ring.add_child(line)
	_bar.visible = open and not state.ring.is_empty()
	_bar.max_value = maxf(float(state.ring.size()), 1.0)
	_bar.value = met
	_come.visible = _bar.visible
	_come.text = RING_COME % [met, state.ring.size()]
	var star := HouseTheme.FOIL if _planned else HouseTheme.on_paper(HouseTheme.FOIL)
	_pays.add_child(_paid_row(RING_PAYS, IconShapes.star.bind(0.5, 0.5, 0.6, star)))
	_edition.visible = state.owed > 0
	_edition.text = EDITION % state.owed
	_show_pin(profile)


## How far a ring's bet has come in words, done once it is: so its count is not said twice.
static func _so_far(profile: Profile, bet: Dictionary) -> String:
	var come := Loyalty.ring_progress(profile, bet)
	if come.x >= come.y:
		return WON.to_lower()
	return Loyalty.ring_progress_text(profile, bet).get_slice(" / ", 0) + " so far"


func _clear_rows() -> void:
	for container: Container in [_pays, _ring]:
		for row: Node in container.get_children():
			(row as Control).hide()
			row.queue_free()


## The Pin button for what the pane says, where it may be pinned, pressed while it is.
func _show_pin(profile: Profile) -> void:
	pin.visible = Loyalty.can_pin(profile, shown)
	var pinned := profile.loyalty.pinned == shown
	pin.set_pressed_no_signal(pinned)
	pin.text = PINNED if pinned else PIN
	# The same key chooses an edition while one is owed, so it pins nothing then.
	if _edition.visible:
		pin.remove_meta(&"bind_action")
	else:
		ButtonBinds.mark(pin, PIN_ACTION)


## The pane's buttons that have a bind, for [method ButtonBinds.show]: pinning, and choosing an
## edition, whichever the key does now.
func bound() -> Array[Button]:
	return [pin, _edition]


## Fills the pane for [param landmark] on [param profile]'s map.
func show_landmark(profile: Profile, landmark: LoyaltyLandmark) -> void:
	_turn_page(profile, landmark.id)
	shown = landmark.id
	_edition.visible = false
	for row: Node in _ring.get_children():
		(row as Control).hide()
		row.queue_free()
	var stands := Loyalty.standing(profile, landmark)
	var closed := stands == Loyalty.Standing.CLOSED
	# Kit's sheet is not the House's, nor on its plans.
	var kit := landmark.district == LoyaltyLandmark.District.OFF_THE_BOOKS
	_plan(closed and not kit, landmark.keystone, kit)
	_later.showing = kit and closed
	_name.text = landmark.title
	var district: Array = DISTRICTS.get(landmark.district, DISTRICTS[LoyaltyLandmark.District.SLIP])
	_district.text = str(district[0]).to_upper()
	_wear(district[1])
	var said: String = [CLOSED, OPEN, WON][stands]
	_standing.text = (said + "  ·  " + KEYSTONE if landmark.keystone else said).to_upper()
	_bet.text = ASKS_LATER if closed else Loyalty.bet_of(landmark)
	_bet.add_theme_color_override("font_color", _hint() if closed else _ink())
	var come := Loyalty.progress(profile, landmark)
	_bar.visible = not closed and come.y > 0.0
	_bar.max_value = maxf(come.y, 1.0)
	_bar.value = come.y if stands == Loyalty.Standing.WON else come.x
	_come.text = Loyalty.progress_text(profile, landmark)
	_show_pin(profile)
	_come.visible = _bar.visible
	_opens.text = opens_by(profile, landmark) if closed else ""
	_opens.visible = closed and not _opens.text.is_empty()
	# Left in the tree to go with it, hidden, so nothing is left belonging to nothing.
	for row: Node in _pays.get_children():
		(row as Control).hide()
		row.queue_free()
	for paid: Array in pays_of(landmark, _ink()):
		_pays.add_child(_paid_row(paid[0], paid[1]))


## Which roads would open [param landmark], closed on [param profile]'s map, in words: any road in
## from the landmarks it is joined to, or for a keystone every one of them. A keystone it is joined
## to is left out, as that opens only once this is won.
static func opens_by(profile: Profile, landmark: LoyaltyLandmark) -> String:
	var map := Loyalty.map()
	var names := PackedStringArray()
	for id: StringName in map.roads_of(landmark.id):
		var other := map.landmark(id)
		if other != null and Loyalty.is_drawn(profile, other) and not other.keystone:
			if not (landmark.keystone and profile.loyalty.has_won(id)):
				names.append(other.title)
	if names.is_empty():
		return ""
	if landmark.keystone:
		return OPENS_BY_ALL % _listed(names, AND)
	return OPENS_BY % _listed(names, OR)


## What [param landmark] pays, a line each with the way to draw its picture: the cards it adds and
## the items, its part of the dress and any more, the Showroom, a loose note.
static func pays_of(landmark: LoyaltyLandmark, ink := Color.WHITE) -> Array[Array]:
	var paid: Array[Array] = []
	for id: StringName in landmark.jokers:
		var joker := CATALOG.by_id(id)
		var named := joker.display_name if joker != null else String(id)
		paid.append([CARD % named, JokerArt.draw_into.bind(id, ink)])
	for id: StringName in landmark.items:
		paid.append([ITEM % _item_name(id), PowerUpArt.draw_into.bind(id, ink)])
	var dress: Array[String] = []
	if landmark.dress_part != &"":
		dress.append("%s:%s" % [landmark.dress_part, landmark.dress])
	dress.append_array(landmark.also)
	for piece: String in dress:
		var part := StringName(piece.get_slice(":", 0))
		var words := "%s: %s" % [PARTS.get(part, String(part)), piece.get_slice(":", 1)]
		paid.append([words, DressArt.draw_into.bind(LoyaltyArt.PARTS.get(part, 0), ink)])
	if landmark.showroom:
		paid.append([SHOWROOM, LoyaltyArt.roller_door.bind(ink)])
	if landmark.note != &"":
		paid.append([NOTE, LoyaltyArt.scrap.bind(ink)])
	if landmark.kind == LoyaltyLandmark.Kind.CARD:
		paid.append([ONTO_THE_MAP, DressArt.draw_into.bind(LoyaltyArt.PARTS[&"card_back"], ink)])
	return paid


static func _item_name(id: StringName) -> String:
	for item: PowerUp in FIRST.entries + LATER.entries:
		if item.id == id:
			return item.display_name
	return String(id)


## [param names] as a list in words, the last two joined by [param last].
static func _listed(names: PackedStringArray, last: String) -> String:
	if names.size() <= 1:
		return "".join(names)
	return ", ".join(names.slice(0, names.size() - 1)) + last + names[-1]


func _paid_row(words: String, draw_with: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var picture := Picture.new()
	picture.draw_with = draw_with
	picture.custom_minimum_size = Vector2.ONE * PICTURE
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(picture)
	var line := _line(18, _ink())
	if _kit:
		line.add_theme_font_override(&"font", KIT_HAND)
		line.add_theme_font_size_override(&"font_size", roundi(18 * KIT_HAND_SIZE))
	line.text = words
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(line)
	return row


## Its words laid [param wide] across, [constant WIDTH] or less on a narrow screen, see
## [method LoyaltyDialog.side_wide].
func set_wide(wide: float) -> void:
	_wide = wide
	for each: Control in [_tear, _bet, _bar, _opens]:
		each.custom_minimum_size.x = wide


## The page saying [member shown] turned up over the coil on [param profile]'s map, as a pad's page
## is, before it says [param next] under it: a copy of the slip saying what this did, drawn into a
## picture of its own for as long as it turns and laid over the slip as big as it was, curling up
## toward the coil and over it, see [Turning], to the leaf's sound. A page still turning is turned
## again from the start with what this said last. Not in a run nobody watches, nor where the page
## would say what it says already.
func _turn_page(profile: Profile, next: StringName) -> void:
	if not turns or shown == &"" or shown == next or Game.is_headless():
		return
	if not is_visible_in_tree() or size.y <= 0.0:
		return
	if _page == null:
		_page_view = SubViewport.new()
		_page_view.name = "PageView"
		_page_view.transparent_bg = true
		_page_view.disable_3d = true
		_page_view.gui_disable_input = true
		_page_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
		_turning.add_child(_page_view)
		_page = LoyaltyPane.new()
		_page.name = "Page"
		_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_page_view.add_child(_page)
		_page.get_node("Coil").hide()
		for button: Button in [_page.pin, _page._edition]:
			button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_page.set_wide(_wide)
	if shown == Loyalty.ROUNDABOUT:
		_page.show_roundabout(profile)
	else:
		_page.show_landmark(profile, Loyalty.map().landmark(shown))
	_turning.planned = _page._planned
	_page.pin.visible = pin.visible
	_page.pin.set_pressed_no_signal(pin.button_pressed)
	_page.pin.text = pin.text
	_page_size = size
	_page.position = Vector2.ZERO
	# Its words drawn at the screen's own pixels, as sharp as the slip's, rather than drawn at
	# the slip's and blown up.
	_page_view.canvas_transform = Transform2D.IDENTITY.scaled(Vector2.ONE * _scale_by())
	_page_view.oversampling_override = _scale_by()
	_page_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_turning.picture = _page_view.get_texture()
	_turning.scale_by = _scale_by()
	_place_page()
	if _turn_coil != null:
		_turn_coil.wide = roundf(size.x)
		_turn_coil.show()
		_turn_coil.queue_redraw()
	var now := Time.get_ticks_msec()
	if now - _sounded_at >= TURN_SOUND_GAP:
		_sounded_at = now
		Audio.play_sfx(&"leaf", TURN_SOUND, 0.12)
	if _turn != null and _turn.is_valid():
		_turn.kill()
	_turn = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_turn.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_turn.tween_method(_lift_page, 0.0, 1.0, TURN)
	_turn.tween_callback(_put_page_down)


## The page [param by] of the way through its turn, see [Turning].
func _lift_page(by: float) -> void:
	_place_page()
	_turning.by = by
	_turning.refresh()


## The page turning as big as the bigger of it and the page under it, as a pad's pages are all of
## a size, whatever its words made of it laid out before they had their width; its picture as big,
## at the screen's own pixels, with room past it for its shadow; and where it is drawn, over the
## slip on what it is drawn on, seen in room all round it, as it fades away over the coil, its
## corner on a whole pixel of the screen so that, lying flat as it starts, it is as sharp as the
## slip was.
func _place_page() -> void:
	var whole := Vector2(size.x, maxf(_page_size.y, size.y))
	_page.size = whole
	var pixels := Vector2i(((whole + Vector2(4.0, 8.0)) * _scale_by()).ceil())
	if _page_view.size != pixels:
		_page_view.size = pixels
	var host := _turning.get_parent_control()
	var slip := Rect2(global_position - host.global_position, whole)
	_turning.position = slip.position - Vector2.ONE * TURN_ROOM
	_turning.size = slip.size + Vector2.ONE * TURN_ROOM * 2.0
	# Laid on the screen's whole pixels, its picture's pixels on the screen's, not blurred between.
	var scale_by := _scale_by()
	var on_screen := global_position * scale_by
	var nudge := (on_screen.round() - on_screen) / scale_by
	_turning.page = Rect2(Vector2.ONE * TURN_ROOM + nudge, slip.size)
	if _turn_coil != null:
		_turn_coil.position = slip.position


## How many of the screen's pixels one of the slip's is, for the turning page's picture.
func _scale_by() -> float:
	return maxf(KeptPictures.scale_of(self), 0.5)


## The turn done: the page no longer drawn, nor its picture.
func _put_page_down() -> void:
	_turning.by = -1.0
	_turning.refresh()
	if _turn_coil != null:
		_turn_coil.hide()
	_page_view.render_target_update_mode = SubViewport.UPDATE_DISABLED


## Its district's word in [param color], printed on the paper.
func _wear(color: Color) -> void:
	var printed := PLAN_INK if _planned else HouseTheme.on_paper(color)
	if _kit:
		printed = KIT_HINT
	_district.add_theme_color_override("font_color", printed)


## The page on the plans or not, see [member AtlasSlipStyle.planned]: its paper, its words' inks,
## and the stamp on it, with the seal for a keystone, [param sealed]; or with [param kit] Kit's,
## his scrap over it and its lines in his hand.
func _plan(planned: bool, sealed: bool, kit := false) -> void:
	_planned = planned
	_kit = kit
	_style.planned = planned
	_scrap.showing = kit
	_later.showing = false
	for line: Label in _fonts:
		var own: Array = _fonts[line]
		var size_of: int = own[1]
		if kit:
			line.add_theme_font_override(&"font", KIT_HAND)
			size_of = roundi(size_of * KIT_HAND_SIZE)
		elif own[0] == null:
			line.remove_theme_font_override(&"font")
		else:
			line.add_theme_font_override(&"font", own[0])
		line.add_theme_font_size_override(&"font_size", size_of)
	for line: Label in [_standing, _come, _opens, _pays_heading]:
		line.add_theme_color_override("font_color", _hint())
	_name.add_theme_color_override("font_color", _ink())
	_stamp.show_as(planned, sealed)
	update_minimum_size()
	queue_redraw()


## The ink of its words, and the fainter ink, on the paper it is on now.
func _ink() -> Color:
	if _kit:
		return KIT_INK
	return PLAN_INK if _planned else INK


func _hint() -> Color:
	if _kit:
		return KIT_HINT
	return PLAN_HINT if _planned else HINT


## The slip told where its dotted line runs, across the middle of the room left for it.
func _tell_tear() -> void:
	_style.tear_at = _box.position.y + _tear.position.y + _tear.size.y * 0.5
	_scrap.rule_at(_style.tear_at)
	queue_redraw()


## The page turns drawn on [param host] rather than on the slip, over all of the slip and clear of
## whatever clips it, the side column's scroll, so that the page curling at the slip's edges is not
## cut off by it; the coil drawn over it again there.
func turn_on(host: Control) -> void:
	_turning.reparent(host, false)
	_turn_coil = TurnCoil.new()
	_turn_coil.name = "TurnCoil"
	_turn_coil.visible = false
	host.add_child(_turn_coil)


## How far the bet has come, as a bar across the paper filling in gold.
static func _ink_bar(bar: ProgressBar) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = HouseTheme.PAPER_LOW.darkened(0.12)
	track.set_corner_radius_all(4)
	var road := StyleBoxFlat.new()
	road.bg_color = HouseTheme.FOIL
	road.set_corner_radius_all(4)
	bar.add_theme_stylebox_override(&"background", track)
	bar.add_theme_stylebox_override(&"fill", road)


func _line(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
