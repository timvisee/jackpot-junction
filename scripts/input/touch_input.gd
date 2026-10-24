class_name TouchInput
extends RefCounted
## Playing on a touch screen, GAME.md 4.2. Whether this screen is one, decided once at startup:
## on by itself on a phone or a tablet, and turned on anywhere with `++ --touch=1` for trying it
## out on a desktop, where the mouse stands in for a finger. `++ --touch=0` turns it off.

## Whether this screen is played by touch.
static var enabled := false
## What the fingers are holding down, put here by [TouchControls] as they move and read by the
## player's controls alongside the keyboard and the pads, see [method PlayerInput.poll]. There is
## one screen and one player at it, so there is one of each.
static var steer := 0.0
## The whole of the stick's push, x right and y down, for simple driving, GAME.md 4.2, where the
## stick says which way on the screen to go rather than only how far to turn.
static var stick := Vector2.ZERO
static var throttle := 0.0
static var brake := 0.0
static var handbrake := false
static var nitro := false
static var fire := false
static var use_item := false
## What the item button wears, GAME.md 8.3: the item in hand's own id and color, or an empty id
## with nothing in hand, so a hint naming the button can draw it as it looks, see
## [method InputGlyph.of_touch].
static var item_id := &""
static var item_color := Color.WHITE
## Where on the floor a finger last pointed a freely aimed cannon, GAME.md 4.2, not finite while
## none has since the cannon came to hand, see [method KartAim.floor_point].
static var aim_point := Vector3.INF
## Which of the jokers is open, or -1: the one a finger is resting on, or the one tapped to keep
## it open, which [member joker_pinned] says.
static var joker_inspect := -1
static var joker_pinned := false
## Which card of the respawn pick a finger is resting on, or -1: the pick's own, apart from the
## hand's, so reading one leaves the other alone.
static var pick_inspect := -1
## A card of the respawn pick tapped, or -1, and whether its skip or back button was, or its reroll
## button, GAME.md 3.7: each is answered once, by the first look at it, see [method take_tap],
## [method take_back] and [method take_reroll].
static var _tapped := -1
static var _back := false
static var _reroll := false
## A joker in the hand dropped or destroyed from its pane, or -1: answered once, as [member _tapped]
## is, see [method take_drop] and [method take_destroy].
static var _drop_card := -1
static var _destroy_card := -1
## An emote tapped on the emote button's menu, GAME.md 3.8, or -1, answered once, see [method
## take_emote].
static var _emote := -1
## The dialogs up that keep the screen's touches from what is under them, see
## [method keep_touches].
static var _keepers: Array[Node] = []


## Decides from the platform and [param args], the command line after `++`.
static func detect(args: PackedStringArray) -> void:
	enabled = OS.has_feature("mobile")
	for arg: String in args:
		if arg == "--touch" or arg == "--touch=1":
			enabled = true
		elif arg == "--touch=0":
			enabled = false
	# A desktop has no fingers to try it with. The mouse is one, which is enough to press
	# everything, if not two things at once; the keyboard still drives alongside it.
	if enabled and not OS.has_feature("mobile"):
		Input.emulate_touch_from_mouse = true


## [param dialog] keeps the screen's touches from whatever is drawn under it while it is up, as a
## full-screen dialog does: the finger-scrolled lists, the touch controls and anything else that
## hears a finger before the dialog can leave it be, see [method kept_from], rather than taking a
## finger on the dialog first, scrolling or pressing what is under it.
static func keep_touches(dialog: Node) -> void:
	_keepers.append(dialog)
	dialog.tree_exiting.connect(func() -> void: _keepers.erase(dialog), CONNECT_ONE_SHOT)


## Whether a dialog up over [param node] keeps the touches from it: one drawn over it, on a higher
## canvas layer, or on the same one and later, that [param node] is not in. A pause menu opened over
## a dialog on a lower layer, the host's match settings say, is over it, and keeps its own.
static func kept_from(node: Node) -> bool:
	var under := _layer_of(node)
	for keeper: Node in _keepers:
		if not is_instance_valid(keeper) or not keeper.is_inside_tree() or not _shown(keeper):
			continue
		if keeper == node or keeper.is_ancestor_of(node):
			continue
		var over := _layer_of(keeper)
		if over > under or (over == under and keeper.is_greater_than(node)):
			return true
	return false


## The canvas layer [param node] is drawn on: its own, or the nearest one it is in, or 0.
static func _layer_of(node: Node) -> int:
	var at := node
	while at != null:
		if at is CanvasLayer:
			return (at as CanvasLayer).layer
		at = at.get_parent()
	return 0


static func _shown(keeper: Node) -> bool:
	if keeper is CanvasLayer:
		return (keeper as CanvasLayer).visible
	if keeper is CanvasItem:
		return (keeper as CanvasItem).is_visible_in_tree()
	return true


## Every finger off the glass, for when the controls go.
static func release() -> void:
	steer = 0.0
	stick = Vector2.ZERO
	throttle = 0.0
	brake = 0.0
	handbrake = false
	nitro = false
	fire = false
	use_item = false
	item_id = &""
	item_color = Color.WHITE
	aim_point = Vector3.INF
	joker_inspect = -1
	joker_pinned = false
	pick_inspect = -1
	_tapped = -1
	_back = false
	_reroll = false
	_drop_card = -1
	_destroy_card = -1
	_emote = -1


static func tap(card: int) -> void:
	_tapped = card


## The pick's skip or back button pressed, or with [param reroll] its reroll button.
static func press_back(reroll := false) -> void:
	if reroll:
		_reroll = true
	else:
		_back = true


## The card tapped since the last look, or -1, and forgotten once looked at.
static func take_tap() -> int:
	var tapped := _tapped
	_tapped = -1
	return tapped


## Whether the skip or back button was pressed since the last look, forgotten once looked at.
static func take_back() -> bool:
	var back := _back
	_back = false
	return back


## Whether the pick's reroll button was pressed since the last look, forgotten once looked at.
static func take_reroll() -> bool:
	var reroll := _reroll
	_reroll = false
	return reroll


static func drop(card: int) -> void:
	_drop_card = card


static func destroy(card: int) -> void:
	_destroy_card = card


## The joker dropped since the last look, or -1, forgotten once looked at.
static func take_drop() -> int:
	var card := _drop_card
	_drop_card = -1
	return card


## The joker destroyed since the last look, or -1, forgotten once looked at.
static func take_destroy() -> int:
	var card := _destroy_card
	_destroy_card = -1
	return card


static func emote(index: int) -> void:
	_emote = index


## The emote tapped since the last look, or -1, forgotten once looked at.
static func take_emote() -> int:
	var tapped := _emote
	_emote = -1
	return tapped
