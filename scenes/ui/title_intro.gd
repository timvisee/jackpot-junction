class_name TitleIntro
extends Control
## The title's opening, GAME.md 8.1a, the first time it comes up in a run: the mark large in the
## middle of the screen, then up into its place over the name while the backdrop comes up round
## it, the seal's rings round it, then the sunburst sweeping out from it, then the name and the
## buttons, dealt in one by one, and last whatever peeks in at the screen's edges. A couple of
## seconds, and any key, button, click or tap goes straight to the end of it, and is spent on that.
##
## Each part of the screen is laid by a callable the title hands over with its share of the time,
## see [method add], so this keeps the time and flies the mark, and the title knows its own parts.

## Over, played out or skipped, with every part laid as it stays.
signal finished

## How long the whole of it takes, in seconds.
const LENGTH := 2.5
## The mark: how big it starts, as a share of the screen's shorter side, and how much smaller still
## it grows from; when it comes up in the middle; and when it flies up into its place.
const BIG := 0.4
const BIG_FROM := 0.9
const LOGO_IN := Vector2(0.0, 0.4)
const LOGO_FLY := Vector2(0.6, 1.3)
## How long before it lands the mark in its place comes up under it and the one flying fades off
## the top of it: drawn at another size, the two differ by a hair, which would show as a jump.
const HAND_OVER := 0.16
## How far below its place a part rises from, see [method rise].
const RISE := 22.0

## Played once a run: the title come back to from a match or the settings is simply there.
static var played := false
## Plays wherever the title comes up, headless too, played or not, for the tests.
static var force := false

## The mark over the name, which the large one flies into and stands in for until it lands.
var mark: Control
## The column the words and the buttons are laid out in, laid out again every frame before any
## of them is moved off its place, see [method rise].
var column: Container

var _parts: Array[Array] = []
var _time := 0.0
var _logo: LogoArt
var _over := false


## Whether the title should open with it: once a run, never where nothing is drawn or a tool is
## running the game, and `--intro=1` or `--intro=0` on the command line says so either way.
static func wanted() -> bool:
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--intro=1":
			return true
		if arg == "--intro=0":
			return false
	return force or (not played and not Game.is_headless() and not Game.is_scripted())


## The opening over [param title], flying [param into] its place, the parts of [param laid_out]
## risen to theirs; its parts are added with [method add] before the first frame.
static func over(title: Control, into: Control, laid_out: Container) -> TitleIntro:
	var intro := TitleIntro.new()
	intro.name = "Intro"
	intro.mark = into
	intro.column = laid_out
	title.add_child(intro)
	return intro


## [param lay] laid every frame from [param from] to [param to] seconds in, given how far along it
## is from 0 to 1: 0 before it starts, which is how the screen begins, and 1 once it is done.
func add(from: float, to: float, lay: Callable) -> void:
	_parts.append([from, to, lay])
	lay.call(0.0)


## [param control] in a container, risen [param by], from 0 to 1, from a little below its place and
## out of nothing, the way a pane is dealt, see [method MenuTheme.deal]; a part to [method add] with
## the control bound.
func rise(by: float, control: Control) -> void:
	var up := ease(clampf(by, 0.0, 1.0), 0.4)
	control.modulate.a = up
	control.position.y += (1.0 - up) * RISE


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Nothing on the screen under it is hovered, clicked or has the cursor until it is over: every
	# press is the one that skips it, see [method _input].
	mouse_filter = Control.MOUSE_FILTER_STOP
	get_viewport().gui_release_focus()
	_logo = LogoArt.new()
	_logo.name = "Logo"
	_logo.plate = false
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art := mark as LogoArt
	if art != null:
		_logo.fine_print = art.fine_print
	add_child(_logo)
	_lay.call_deferred()


func _process(delta: float) -> void:
	if _over:
		return
	_time += delta
	if _time >= LENGTH:
		finish()
		return
	_lay()


## Straight to the end of it, with every part where it stays, and gone.
func finish() -> void:
	if _over:
		return
	_over = true
	played = true
	_time = LENGTH
	_lay()
	_logo.visible = false
	_let_go()
	finished.emit()
	queue_free()


## Every part as it is [member _time] seconds in.
func _lay() -> void:
	if not is_inside_tree():
		return
	if column != null:
		column.notification(Container.NOTIFICATION_SORT_CHILDREN)
	for part: Array in _parts:
		var from: float = part[0]
		var to: float = part[1]
		(part[2] as Callable).call(clampf((_time - from) / maxf(to - from, 0.001), 0.0, 1.0))
	_fly()


## The mark, large in the middle, then flown up into its place; on a screen too short for the mark
## over the name, it goes where it stands.
func _fly() -> void:
	var landed := _time >= LOGO_FLY.y
	var to_place := mark != null and is_instance_valid(mark) and mark.is_visible_in_tree()
	var handed := 0.0
	if to_place:
		handed = clampf((_time - LOGO_FLY.y + HAND_OVER) / HAND_OVER, 0.0, 1.0)
	if mark != null and is_instance_valid(mark):
		mark.modulate.a = 1.0 if landed else clampf(handed * 2.0, 0.0, 1.0)
	_logo.visible = not landed
	if landed:
		return
	var big := minf(size.x, size.y) * BIG
	_logo.size = Vector2.ONE * big
	_logo.pivot_offset = _logo.size * 0.5
	var shown := ease(clampf((_time - LOGO_IN.x) / (LOGO_IN.y - LOGO_IN.x), 0.0, 1.0), 0.4)
	var flown := clampf((_time - LOGO_FLY.x) / (LOGO_FLY.y - LOGO_FLY.x), 0.0, 1.0)
	flown = ease(flown, -2.4)
	var middle := size * 0.5
	var grown := lerpf(BIG_FROM, 1.0, shown)
	if to_place:
		var place := mark.get_global_rect()
		middle = middle.lerp(place.get_center() - global_position, flown)
		grown *= lerpf(1.0, place.size.x / big, flown)
	else:
		shown *= 1.0 - flown
		grown *= lerpf(1.0, 0.6, flown)
	_logo.position = middle - _logo.size * 0.5
	_logo.scale = Vector2.ONE * grown
	_logo.modulate.a = shown * clampf(2.0 - handed * 2.0, 0.0, 1.0)


## The mark, held back until it was over, handed back, and nothing under it held off the mouse.
func _let_go() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if mark != null and is_instance_valid(mark):
		mark.modulate.a = 1.0


## Any key, button, click or tap ends it, and that is all it does: heard before the screen's
## controls are, it is not also a press of whatever the cursor lands on as it ends. The game still
## hears which device it came from, see [method Game.heard].
func _input(event: InputEvent) -> void:
	if _over or not _skips(event):
		return
	Game.heard(event)
	get_viewport().set_input_as_handled()
	finish()


static func _skips(event: InputEvent) -> bool:
	var key := event as InputEventKey
	if key != null:
		return key.pressed and not key.echo
	if event is InputEventMouseButton or event is InputEventJoypadButton:
		return event.is_pressed()
	var touch := event as InputEventScreenTouch
	return touch != null and touch.pressed


## Gone before it was over, with its title, say: the mark is not left out of sight.
func _exit_tree() -> void:
	if not _over:
		_over = true
		played = true
		_let_go()
