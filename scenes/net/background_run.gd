class_name BackgroundRun
extends RefCounted
## Keeps the match running while somebody has alt-tabbed away from it, GAME.md 9.3.
##
## A window the desktop has stopped putting on screen can block the frame it is waiting to
## present for a long time, and everything else waits behind it: physics, the wire, the lot. On
## the host that stops the whole room, and every client sits looking at a frozen arena until
## somebody clicks back. So a window in the background stops waiting for the desktop and runs
## free at a fixed rate instead, and is given back whatever it had the moment it returns.

## What an unfocused window runs at while this machine is in an online room. Fast enough that
## nobody can tell, slow enough that a game nobody is looking at is not spinning a graphics card
## flat out.
const FPS := 60

## Whether the window is in the background and has been taken over.
var on := false

## What the window was set to before it went into the background, so it can be put back. -1
## while the window has the focus and nothing has been taken over.
var _vsync := -1
var _max_fps := 0


## Takes the window over as it goes into the background, [param background], or gives it back.
## Only on a change: told twice is still once.
func run(background: bool) -> void:
	if background == on:
		return
	on = background
	if DisplayServer.get_name() == "headless":
		return
	if background:
		_vsync = DisplayServer.window_get_vsync_mode()
		_max_fps = Engine.max_fps
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = FPS
		return
	if _vsync >= 0:
		DisplayServer.window_set_vsync_mode(_vsync)
		Engine.max_fps = _max_fps
		_vsync = -1
