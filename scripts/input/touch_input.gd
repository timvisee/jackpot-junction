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
