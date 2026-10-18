class_name TornPage
extends Control
## The strip torn off the foot of the Final Hand's payout slip, STORY.md 8.4: torn straight across
## the House's page over STATUS from the tab at its edge. The tear runs across from the tab, the
## part already torn curling away and down while the rest still holds, the foot it leaves on the
## slip torn by hand to fit it, see [method PayoutBill.cut_short]; once it is through the strip
## falls, turning as paper does, off the screen, with the tab, as the invitation's stub fell, 6.1a.
## Then it is gone, and what was on it with it. Drawn from a picture of the strip as it was the
## moment before, bent and moved, see [method picture_of]; the tab is the tab itself.

## Told once it has fallen off the screen.
signal fallen

const PAPER := HouseTheme.PAPER
## How long the tear takes to run across, and how far the torn end has turned by when it is through.
const RIP := 0.55
const CURL := 0.32
## Falling: how fast it gathers speed, in pixels a second each second, how fast it turns, how far
## it drifts off the tab's way, and how much it sways as it goes, and how fast.
const GRAVITY := 2600.0
const SPIN := 0.55
const DRIFT := 50.0
const SWAY := 9.0
const SWAY_RATE := 7.0
## How long it may take at most, whatever has happened.
const LONGEST := 3.0
## How ragged the torn top is drawn in the folder, see [method shape_of].
const RAGGED := 5.0

var _picture: Texture2D
var _whole := Vector2.ZERO
## The slip's paper, whose foot it hangs from until the tear is through.
var _from: Control
var _tab: Control
## The tab's pivot as it was on the strip, from the strip's top left.
var _tab_on := Vector2.ZERO
var _age := 0.0
var _let_go_at := Vector2.ZERO
var _columns := PackedFloat32Array()


## The strip of [param region], on the screen in [param over]'s coordinates, torn off and falling,
## drawn from [param picture] of it; hanging from the foot of [param from], the slip's paper, until
## the tear is through, and [param tab] going with it.
static func tear(
	over: Control, region: Rect2, picture: Texture2D, from: Control, tab: Control = null
) -> TornPage:
	var torn := TornPage.new()
	torn.name = "TornPage"
	torn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	over.add_child(torn)
	torn.global_position = region.position
	torn.size = region.size
	torn._whole = region.size
	torn._picture = picture
	torn._from = from
	torn._columns = TicketStyle.hand_steps(region.size.x)
	if tab != null:
		torn._tab = tab
		torn._tab_on = tab.global_position + tab.pivot_offset - region.position
		tab.reparent(torn)
	Audio.play_sfx(&"tear", -3.0, 0.08)
	torn._place()
	return torn


## A picture of [param region] of the screen as it was last drawn, in [param over]'s coordinates:
## what the strip looked like the moment before it was torn. Plain paper where nothing was drawn,
## as on a machine with no screen.
static func picture_of(over: Control, region: Rect2) -> Texture2D:
	var shot: Image = null
	var screen := over.get_viewport().get_texture()
	if screen != null and not Game.is_headless():
		shot = screen.get_image()
	if shot != null and not shot.is_empty():
		var to_screen := over.get_viewport().get_final_transform() * over.get_canvas_transform()
		var corner := Vector2i((to_screen * region.position).round())
		var span := Vector2i(to_screen.basis_xform(region.size).round())
		var inside := Rect2i(corner, span).intersection(Rect2i(Vector2i.ZERO, shot.get_size()))
		if inside.size.x > 1 and inside.size.y > 1:
			return ImageTexture.create_from_image(shot.get_region(inside))
	var plain := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	plain.fill(PAPER)
	return ImageTexture.create_from_image(plain)


## Whether the tear is through and it is falling.
func is_falling() -> bool:
	return _age >= RIP


func _process(delta: float) -> void:
	_age += delta
	_place()
	queue_redraw()
	if _age >= LONGEST or (is_falling() and _off_the_screen()):
		fallen.emit()
		queue_free()


## Where it is: hanging from the slip's foot while the tear runs, falling from there after.
func _place() -> void:
	if not is_falling():
		if _from != null and is_instance_valid(_from):
			var paper := _from.get_global_rect()
			global_position = Vector2(paper.position.x, paper.end.y - TicketStyle.TOOTH)
		_let_go_at = position
	else:
		position = _let_go_at
	if _tab != null and is_instance_valid(_tab):
		var fall := _falling()
		_tab.position = fall * _bent(_tab_on) - _tab.pivot_offset
		_tab.rotation = _turn_at(_whole.x) + fall.get_rotation()


func _off_the_screen() -> bool:
	var top := (_falling() * _bent(Vector2(_whole.x * 0.5, 0.0))).y + global_position.y
	return top > get_viewport_rect().size.y + _whole.x * 0.2


func _draw() -> void:
	if _picture == null:
		return
	draw_set_transform_matrix(_falling())
	var shade := Color(0.0, 0.0, 0.0, 0.22)
	var foot := _whole.y - TicketStyle.TOOTH
	var teeth := maxi(roundi(_whole.x / (TicketStyle.TOOTH * 2.0)), 1)
	var step := _whole.x / float(teeth)
	for shadow: bool in [true, false]:
		for i: int in _columns.size() - 1:
			var a := _columns[i]
			var b := _columns[i + 1]
			var corners := PackedVector2Array(
				[
					Vector2(a, TicketStyle.TOOTH * TicketStyle.hand_bite(a)),
					Vector2(b, TicketStyle.TOOTH * TicketStyle.hand_bite(b)),
					Vector2(b, foot),
					Vector2(a, foot),
				]
			)
			_piece(corners, shadow, shade)
		# The printer's teeth along its foot, as the slip had them.
		for t: int in teeth:
			var tooth := PackedVector2Array(
				[
					Vector2(float(t) * step, foot),
					Vector2(float(t + 1) * step, foot),
					Vector2(float(t) * step + step * 0.5, _whole.y),
				]
			)
			_piece(tooth, shadow, shade)
	draw_set_transform_matrix(Transform2D.IDENTITY)


## One piece of the strip, its [param corners] where they were on it: bent as it is now, and drawn
## from the picture, or as its shadow.
func _piece(corners: PackedVector2Array, shadow: bool, shade: Color) -> void:
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	for corner: Vector2 in corners:
		points.append(_bent(corner) + (Vector2(6.0, 10.0) if shadow else Vector2.ZERO))
		uvs.append(corner / _whole)
	if shadow:
		draw_colored_polygon(points, shade)
	else:
		draw_polygon(points, PackedColorArray([Color.WHITE]), uvs, _picture)


## How far through the tear is, 0 to 1, eased as a tear goes: slow to start, then quick.
func _ripped() -> float:
	return ease(clampf(_age / RIP, 0.0, 1.0), 1.6)


## Where the tear has run to from the right edge, from the left.
func _front() -> float:
	return _whole.x * (1.0 - _ripped())


## How far the strip is turned at [param x] along it: none where it still holds, more the further
## past the tear's front.
func _turn_at(x: float) -> float:
	var past := maxf(x - _front(), 0.0)
	return CURL * _ripped() * past / maxf(_whole.x, 1.0)


## Where [param point] of the strip, from its top left as it was, is now that the part past the
## tear's front has curled away, before it falls: the curl a circle's arc, each upright of the
## strip turned with it.
func _bent(point: Vector2) -> Vector2:
	var front := _front()
	if point.x <= front:
		return point
	var past := point.x - front
	var bend := CURL * _ripped() / maxf(_whole.x, 1.0)
	var turn := bend * past
	var along := Vector2(past, 0.0)
	if bend > 1e-6:
		along = Vector2(sin(turn), 1.0 - cos(turn)) / bend
	return Vector2(front, 0.0) + along + Vector2(-sin(turn), cos(turn)) * point.y


## How it has moved since the tear went through: falling, turning and swaying.
func _falling() -> Transform2D:
	var since := maxf(_age - RIP, 0.0)
	if since <= 0.0:
		return Transform2D.IDENTITY
	var middle := _bent(_whole * 0.5)
	var drop := Vector2(
		DRIFT * since + SWAY * sin(since * SWAY_RATE), 0.5 * GRAVITY * since * since
	)
	var spin := Transform2D(SPIN * since, Vector2.ZERO)
	return Transform2D(0.0, middle + drop) * spin * Transform2D(0.0, -middle)


## The paper of [param paper], torn across its top by hand and off the printer along its foot, as
## the strip was torn off and is kept, see [FolderBack].
static func shape_of(paper: Rect2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for x: float in TicketStyle.hand_steps(paper.size.x):
		points.append(paper.position + Vector2(x, RAGGED * TicketStyle.hand_bite(x)))
	var foot := NotePaper.torn(paper, RAGGED, false, true)
	# The torn shape's foot, right to left, after the ragged top left to right.
	for i: int in range(floori(foot.size() * 0.5), foot.size()):
		points.append(foot[i])
	return points
