class_name LastLines
extends CanvasLayer
## The last lines, STORY.md 8.5: the slip put away for the House's dark stock, the music under as at
## a death. The oversight desk plays itself over it, see [OversightDesk], in a world of its own so
## the match it stands over is left be, and says [signal OversightDesk.settled] once it has struck
## over and gone dark. Then the stock is drawn back over it and the line stands alone in the middle,
## in the condensed capitals and the House's foil, until a press; it fades; a breath; and the
## House's approval record feeds up off its roll, the decisions approved in the player's name
## counting from the stamp, see [ApprovalRecord], until a press. Nothing says to press. A press
## counts once what is up has stood a second, and only a press made since. Then the license in full
## over the stock, as after the driving test, and put away, the title; or online, back to the slip,
## through, while the others finish theirs, 8.6, see [FinalHandRoll].

## Online, the license put away: this screen through, see [member back_to_the_room].
signal finished

## Over everything: the slip, the HUD, the pause menu.
const LAYER := 40
## How long a thing takes to fade, and the breath between the line and the record.
const FADE := 0.45
const BREATH := 0.7
## How long a line stands before a press counts.
const STEADY := 1.0
## How long the House's last frame takes to fade down into the dark stock before the desk comes up.
const DARKEN := 1.0
## How long the House's last frame holds black and still, once it has faded down, before the desk.
const BLACKOUT := 1.2
## How long the stock takes to lift off the desk to show it.
const REVEAL := 1.3
## How long the screen holds black and silent after the lamp is pulled, before the line comes up.
const HUSH := 3.0
## What the toasts of GAME.md 8.10 hold back for: the ending's lines have the screen to themselves.
const GROUP := &"last_lines"

var line: Label
var record: ApprovalRecord
## What is up: the line, 0, the record, 1, and -1 between.
var showing := -1
## Whether it has gone on to the license.
var done := false
## Online: the license put away goes back to the slip, the room going back to its lobby once
## everybody in it is through, rather than to the title, STORY.md 8.6.
var back_to_the_room := false

## How long the line up has stood, in the game's own time.
var _stood := 0.0
var _stock: ColorRect
var _holder: Control
## The desk and the world of its own it plays in, shown full screen behind the stock and the lines.
var _desk: OversightDesk
var _view: SubViewport
## The desk's view, held transparent so the House shows through until it has faded to black.
var _container: SubViewportContainer


## The last lines over [param parent], the match's scene, and [param online] back to the slip
## after them, see [member back_to_the_room].
static func begin(parent: Node, online := false) -> LastLines:
	var lines := LastLines.new()
	lines.name = "LastLines"
	lines.back_to_the_room = online
	parent.add_child(lines)
	return lines


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(GROUP)
	Audio.hush_music(true)
	# The room plays in its own silence: the match's karts under it are muted for the whole ending,
	# put back as they were on the way home, see [method Audio.hush_karts] and [method _home].
	Audio.hush_karts(true)
	_holder = Control.new()
	_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_holder.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_holder)
	# The desk plays in a world of its own, shown full screen, so the match it stands over is left be,
	# the way the flat board was only ever drawn over it. It is held transparent at first so the
	# House's own last frame shows through, until the stock has drawn down over it into black.
	_container = SubViewportContainer.new()
	_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_container.stretch = true
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.modulate.a = 0.0
	_holder.add_child(_container)
	_view = SubViewport.new()
	_view.own_world_3d = true
	_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_container.add_child(_view)
	_desk = OversightDesk.add_to(_view)
	_desk.settled.connect(_lines_on)
	# The dark stock over the desk: drawn down over the House to black, lifted to show the desk, and
	# dropped back over it for the lines to stand on. It starts clear, on the House's last frame.
	_stock = ColorRect.new()
	_stock.color = HouseTheme.STOCK
	_stock.color.a = 0.0
	_stock.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_holder.add_child(_stock)
	line = _words("", Type.display_font(), Type.TITLE, HouseTheme.FOIL)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.modulate.a = 0.0
	_holder.add_child(line)
	_holder.resized.connect(_place)
	_place()
	_play()


func _words(text: String, font: Font, font_size: int, ink: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.set_font(label, font, font_size)
	label.add_theme_color_override("font_color", ink)
	return label


func _place() -> void:
	var room := _holder.size
	line.size = Vector2(room.x * 0.8, room.y * 0.5)
	line.position = Vector2(room.x * 0.1, room.y * 0.25)


## The House's last frame fades down into the dark stock, holds black a moment, then the desk comes
## up out of it and plays. Its [signal OversightDesk.settled] brings the lines on once it has gone.
func _play() -> void:
	var fade := create_tween()
	fade.tween_property(_stock, "color:a", 1.0, DARKEN).set_ease(Tween.EASE_IN)
	fade.tween_interval(BLACKOUT)
	fade.tween_callback(_reveal_desk)


## Under the black stock the desk's view is brought up, then the stock lifts off as the desk plays.
func _reveal_desk() -> void:
	_container.modulate.a = 1.0
	create_tween().tween_property(_stock, "color:a", 0.0, REVEAL).set_ease(Tween.EASE_OUT)
	_desk.play()


## The desk gone dark and still, see [method OversightDesk._go_dark]: the room is already black, so
## the stock is set opaque over it at once, with no fade, and the screen holds black and silent for
## [constant HUSH] before the line comes up.
func _lines_on() -> void:
	_stock.color.a = 1.0
	var hush := create_tween()
	hush.tween_interval(HUSH)
	hush.tween_callback(_show_line)


func _show_line() -> void:
	# The black-out reverb has rung out through the hush; the line comes up to dry sound again.
	Audio.lift_sfx()
	showing = 0
	line.text = StoryLines.LAST_LINE
	_stood = 0.0
	create_tween().tween_property(line, "modulate:a", 1.0, FADE)


## The House's approval record, fed up off its roll, counting from when the stamp came down here,
## or from now for a stamp that kept nothing.
func _show_record() -> void:
	showing = 1
	_stood = 0.0
	var story := Game.settings.profile.story
	var since := story.stamped_at if story.ended() and story.stamped_at > 0.0 else 0.0
	if since <= 0.0:
		since = Time.get_unix_time_from_system()
	record = ApprovalRecord.feed(_holder, Game.settings.profile, since)


func _process(delta: float) -> void:
	# The record stands from when its last line is up.
	if showing == 0 or (showing == 1 and record != null and record.is_fed()):
		_stood += delta


## A press, any press, made since the line came up and once it has stood a second, takes it down.
func _input(event: InputEvent) -> void:
	if showing < 0 or done:
		return
	var pressed := (
		(event is InputEventKey and event.is_pressed() and not event.is_echo())
		or (event is InputEventMouseButton and event.is_pressed())
		or (event is InputEventJoypadButton and event.is_pressed())
		or (event is InputEventScreenTouch and event.is_pressed())
	)
	if not pressed:
		return
	get_viewport().set_input_as_handled()
	if _stood < STEADY:
		return
	var was := showing
	showing = -1
	var away := create_tween()
	if was == 0:
		away.tween_property(line, "modulate:a", 0.0, FADE)
		away.tween_interval(BREATH)
		away.tween_callback(_show_record)
	else:
		away.tween_property(record, "modulate:a", 0.0, FADE)
		away.tween_callback(_the_license)


## The license in full over the stock, as after the driving test, made the Operator's as it is
## looked at, see [OperatorStamping]; put away, the title.
func _the_license() -> void:
	done = true
	var view := LicenseView.open(_holder, Game.last_input_keyboard)
	OperatorStamping.on(view)
	view.put_away.connect(_home)


func _home() -> void:
	Audio.hush_music(false)
	# The match's sound and dry effects come back as the Operator leaves the room.
	Audio.hush_karts(false)
	Audio.lift_sfx()
	if back_to_the_room:
		finished.emit()
		queue_free()
		return
	# The title the Operator comes home to opens as it did when the game started, STORY.md 8.6.
	TitleIntro.played = false
	Game.go_to_title()
