class_name BayNew
extends Node
## The NEW tags of the kart dialog, GAME.md 4.4a, as the catalog's are, 8.8: a piece of dress won in
## the loyalty program, 8.9, or moved up a finish there, that the dialog has not shown yet wears one
## on its place on the rack until the cursor, the mouse or a finger has been on it, see
## [method PartTray.TrayCell.set_fresh]; the hook of its part wears one while its rack holds such a
## piece, and the key of whose kart it is while that kart has one, see [method
## KartOwner.new_pieces]. Next new, a plate of the Department of Karts' left of Back and of its
## make, takes the cursor to the next of them, see [NextNew]. The tags taken off are kept in each
## profile's file as the dialog goes. Kept out of [KartDialog] the way [LoyaltyNextNew] is out of
## [LoyaltyDialog].

## How far left of Back Next new stands; how far round its plate the plate's kept picture reaches,
## for its shadow and its coming up and going down, and the group told when one is ready.
const GAP := 14.0
const AROUND := 8.0
const PLATES := &"next_new_plates"

var dialog: KartDialog
var next_new: NextNew
## The tab the hooks were last tagged for, and how Next new's bind was last drawn.
var _tab := -1
var _binds := -1
## A tab for each profile whose tags came off, for the profile to be kept as the dialog goes.
var _looked: Array[KartOwner] = []


## The NEW tags of [param on], and Next new on [param stage], the stage its bay is laid out on,
## left of Back and as tall.
static func add_to(on: KartDialog, stage: Control) -> BayNew:
	var made := BayNew.new()
	made.name = "BayNew"
	made.dialog = on
	made.next_new = NextNew.around(made._plate())
	made.next_new.asked.connect(made.jump)
	stage.add_child(made.next_new)
	var place := func() -> void:
		var back := BayArt.BACK.position
		made.next_new.position = Vector2(back.x - GAP - made.next_new.size.x, back.y)
	made.next_new.resized.connect(place)
	place.call()
	on.tray.tried.connect(made.look)
	on.add_child(made)
	return made


## The NEW tag hung on [param on] by its top corner at [param corner], in [param on]'s space,
## standing out past it as a card's does past the card's: its top right corner there, or its top
## left for [param left], growing away from it. A picture of itself, see [CatalogCell].
static func new_tag_at(on: Control, corner: Vector2, left := false) -> Control:
	var tag := CatalogCell.new_tag()
	tag.set_anchors_preset(Control.PRESET_TOP_LEFT)
	tag.grow_horizontal = Control.GROW_DIRECTION_END if left else Control.GROW_DIRECTION_BEGIN
	var at := corner + CatalogCell.NEW_OUT * Vector2(-1.0 if left else 1.0, 1.0)
	tag.offset_left = at.x
	tag.offset_right = at.x
	tag.offset_top = at.y
	tag.offset_bottom = at.y
	on.add_child(tag)
	return tag


## Whether [param profile] has a piece of dress the kart dialog has not shown it yet, GAME.md 4.4a,
## so the ways to it wear the NEW tag: Customize kart in the Clubhouse and on the Me tab, the
## title's bay, and the Clubhouse itself.
static func has_new(profile: Profile) -> bool:
	return not KartOwner.for_profile(profile).new_pieces().is_empty()


func _ready() -> void:
	_tab = dialog.current
	tag()


## Next new's plate, as Back's is, see [method BayArt.draw_back]: the Department's plate with its
## face pressed into it in the plate's ink, rather than words, see [method NextNew.face]; coming up
## a little under the mouse and going down as it is pressed, its face with it. Drawn once each way
## it looks and kept, see [BayArt], one draw.
func _plate() -> Button:
	var plate := Button.new()
	plate.add_to_group(PLATES)
	plate.flat = true
	plate.custom_minimum_size.y = BayArt.BACK.size.y
	for look: StringName in [
		&"normal", &"hover", &"pressed", &"disabled", &"focus", &"hover_pressed"
	]:
		plate.add_theme_stylebox_override(look, StyleBoxEmpty.new())
	for ink: StringName in [
		&"font_color", &"font_hover_color", &"font_pressed_color", &"font_hover_pressed_color"
	]:
		plate.add_theme_color_override(ink, LicensePlate.INK)
	var down := func() -> bool:
		return plate.get_draw_mode() in [Button.DRAW_PRESSED, Button.DRAW_HOVER_PRESSED]
	plate.draw.connect(
		func() -> void:
			var whole := Rect2(Vector2.ZERO, plate.size.round())
			var lit := plate.is_hovered()
			var pushed: bool = down.call()
			var room := whole.grow(AROUND)
			var art := BayArt.kept(
				plate,
				"next_new:%s:%s:%s" % [whole.size, lit, pushed],
				room.size,
				func(on: CanvasItem) -> void:
					BayArt.draw_back(on, Rect2(Vector2.ONE * AROUND, whole.size), "", lit, pushed),
				PLATES
			)
			if art != null:
				plate.draw_texture_rect(art, room, false)
			else:
				BayArt.draw_back(plate, whole, "", lit, pushed)
	)
	var follow := func() -> void:
		var face := plate.get_node_or_null("Face") as Control
		if face != null:
			face.position.y = 2.0 if down.call() else (-2.0 if plate.is_hovered() else 0.0)
		plate.queue_redraw()
	for told: Signal in [
		plate.mouse_entered, plate.mouse_exited, plate.button_down, plate.button_up
	]:
		told.connect(follow)
	return plate


func _process(_delta: float) -> void:
	if dialog.current != _tab:
		_tab = dialog.current
		tag()
	# Its bind as the dialog's other buttons have theirs, see [method KartDialog._show_button_binds].
	var shown := not dialog._pointer and not PlayerInput.typing
	var binds := int(dialog._keyboard) + 2 * int(shown)
	if binds != _binds:
		_binds = binds
		next_new.show_bind(dialog._keyboard, shown)


## Next new's bind, N or a pad's View, presses it from anywhere in the dialog, but while a box is
## typed into, where it is a letter.
func _unhandled_input(event: InputEvent) -> void:
	if dialog.is_closing() or PlayerInput.typing or event.is_echo():
		return
	if next_new.heard(event):
		get_viewport().set_input_as_handled()


## Each hook wears NEW while its rack holds a piece the tab up has not been shown, each key while
## whose kart it is has one, and Next new says how many there are on all the tabs together, each
## profile's once.
func tag() -> void:
	var left := {}
	for tab: int in dialog.owners.size():
		var owner := dialog.owners[tab]
		var unseen := owner.new_pieces()
		dialog.keys[tab].set_fresh(not unseen.is_empty())
		for at: Vector2i in unseen:
			left[[owner.profile, at]] = true
		if tab != dialog.current:
			continue
		for hook: PartHook in dialog.hooks:
			hook.set_fresh(unseen.any(func(at: Vector2i) -> bool: return at.x == hook.part))
	next_new.show_left(left.size())


## The cursor, the mouse or a finger come to [param index] on the rack out: no longer new, its tag
## off and kept off, and the hooks, the keys and Next new saying so.
func look(index: int) -> void:
	var cell := dialog.tray.cell_at(index)
	if cell == null or not cell.fresh:
		return
	cell.set_fresh(false)
	var owner := dialog.kart_owner()
	owner.profile.loyalty.look_at_dress(KartOwner.piece_name(dialog.tray.part, index))
	if _looked.all(func(each: KartOwner) -> bool: return each.profile != owner.profile):
		_looked.append(owner)
	tag()


## Next new, GAME.md 8.8: the cursor at once on the next piece wearing NEW after where it is, the
## tab up's first and then the tabs after it, round past the last; on a tab, a hook at a time down
## the left board and then the right, each rack in its own order. Turned to its tab and its rack
## hung out, scrolled to and landed on, see [LandingCue]; the cursor coming to it takes its tag
## off, see [method look].
func jump() -> void:
	if dialog.is_closing():
		return
	var news: Array = []
	for owner: KartOwner in dialog.owners:
		news.append(owner.new_pieces())
	var fresh := func(place: Array) -> bool: return Vector2i(place[1], place[2]) in news[place[0]]
	var next: Variant = NextNew.after(_order(news), _at(), fresh)
	if next == null:
		return
	var part: int = next[1]
	var index: int = next[2]
	if next[0] != dialog.current:
		dialog.show_owner(next[0])
	# Its rack hung out with the cursor on it rather than on the piece worn, or on it at once.
	if dialog.open_part != part:
		dialog.open_tray(part, index)
	else:
		dialog.tray.cell_at(index).grab_focus()
	get_tree().process_frame.connect(_land.bind(dialog.tray.cell_at(index)), CONNECT_ONE_SHOT)


## Every place Next new goes by on its way, [param news] each tab's new pieces, the tab up's first
## and round from there, [tab, part, index] each: on a tab, each hook down the left board and then
## the right, the hook itself, an index of -1, and then its pieces in its rack's order, only the new
## ones but on the rack out. Won, the new ones keep the part's own order on a rack too.
func _order(news: Array) -> Array:
	var order: Array = []
	var count := dialog.owners.size()
	for step: int in count:
		var tab := (dialog.current + step) % count
		for part: int in KartDialog.LEFT_HOOKS + KartDialog.RIGHT_HOOKS:
			if part == KartDialog.SHUFFLE:
				continue
			order.append([tab, part, -1])
			if tab == dialog.current and part == dialog.open_part:
				for cell: PartTray.TrayCell in dialog.tray.cells:
					order.append([tab, part, cell.index])
				continue
			for index: int in KartDialog.choices_of(part).size():
				if Vector2i(part, index) in news[tab]:
					order.append([tab, part, index])
	return order


## Where the cursor is, as [method _order] has it: on a piece of the rack out, or on a hook; null
## anywhere else, Next new going to the tab up's first.
func _at() -> Variant:
	var on := dialog.get_viewport().gui_get_focus_owner()
	if on is PartTray.TrayCell and dialog.open_part >= 0:
		return [dialog.current, dialog.open_part, (on as PartTray.TrayCell).index]
	if on is PartHook and (on as PartHook).part <= KartDialog.CARD_BACK:
		return [dialog.current, (on as PartHook).part, -1]
	return null


## The eye drawn to [param cell], come to from afar, perhaps from another tab or rack, once the
## rack has scrolled to it: it comes up only a little, packed on its rack as it is, and its rings
## go out from its outline over the rack rather than cut off where its pieces scroll.
func _land(cell: PartTray.TrayCell) -> void:
	if not is_instance_valid(cell) or not cell.is_inside_tree():
		return
	var cue := LandingCue.on(cell, LandingCue.GENTLE, cell.focus_frame())
	var on_rack := dialog.tray.get_global_transform().affine_inverse() * cell.get_global_transform()
	cue.reparent(dialog.tray, false)
	cue.frame = on_rack * cell.focus_frame()


## The tags taken off kept in each profile's file as the dialog goes, see [method KartOwner.keep].
func _exit_tree() -> void:
	for owner: KartOwner in _looked:
		owner.keep()
	_looked.clear()
