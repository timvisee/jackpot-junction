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
static var throttle := 0.0
static var brake := 0.0
static var handbrake := false
static var nitro := false
static var fire := false
static var use_item := false
## Which of the jokers is open, or -1: the one a finger is resting on, or the one tapped to keep
## it open, which [member joker_pinned] says.
static var joker_inspect := -1
static var joker_pinned := false
## A card of the respawn pick tapped, or -1, and whether its skip or back button was: each is
## answered once, by the first look at it, see [method take_tap] and [method take_back].
static var _tapped := -1
static var _back := false
## A joker in the hand dropped or destroyed from its pane, or -1: answered once, as [member _tapped]
## is, see [method take_drop] and [method take_destroy].
static var _drop_card := -1
static var _destroy_card := -1


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


## Every finger off the glass, for when the controls go.
static func release() -> void:
	steer = 0.0
	throttle = 0.0
	brake = 0.0
	handbrake = false
	nitro = false
	fire = false
	use_item = false
	joker_inspect = -1
	joker_pinned = false
	_tapped = -1
	_back = false
	_drop_card = -1
	_destroy_card = -1


static func tap(card: int) -> void:
	_tapped = card


static func press_back() -> void:
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
