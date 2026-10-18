class_name SlipFolder
extends Control
## Kit's folder beside the payout slip, STORY.md 7.2: after a map in which a note was taken on this
## machine, the folder peeks in from the left edge while the slip is up, its pencil mark on it,
## coming out and opening its cover a little a few times to draw the eye, and opens over the slip on
## a click or a tap or on the button that opens the hand of jokers, drawn beside it for the device
## in hand, the way the title opens the license. Put away, the slip is as it was and the cursor
## where it was. Between the maps of a Grand Prix too, and online, where the room moves on at the
## host's word and takes the folder with the slip, every note read in it kept read as it is read; at
## the Final Hand the room waits for everybody, and the folder is there beside the House's page
## whether or not a note was taken, Kit's last note in it for reading before the page is answered,
## 8.4.

const GLYPH_SIZE := 24
## Where the hand's button is drawn, over the folder's top right as it peeks in.
const GLYPH_AT := Vector2(18.0, 60.0)

var match_node: Match
var peek: FolderPeek
var notes: NotesFolder

var _glyph: Control
var _keyboard := true
var _from: Control


## The folder for the slip of [param in_match], or null for a match with no slip to put it beside.
static func add_to(in_match: Match) -> SlipFolder:
	if in_match.hud == null:
		return null
	var existing := in_match.hud.get_node_or_null("SlipFolder") as SlipFolder
	if existing != null:
		return existing
	var folder := SlipFolder.new()
	folder.name = "SlipFolder"
	folder.match_node = in_match
	in_match.hud.add_child(folder)
	return folder


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_keyboard = Game.last_input_keyboard
	visible = false


## Up with the slip, and away with it.
func _process(_delta: float) -> void:
	var slip := match_node.hud.get_node_or_null("Results") as Control
	var showing := slip != null and slip.visible
	if showing and peek == null:
		_put_up()
	visible = showing


func _put_up() -> void:
	var none: Array[Control] = []
	peek = FolderPeek.add_to(self, Game.settings.profile, none)
	# The slip's buttons keep the cursor: the folder is a click, a tap or the hand's button away.
	peek.focus_mode = Control.FOCUS_NONE
	peek.opened.connect(open)
	_show_glyph()
	# Hard to spot beside the slip otherwise: it comes out and opens its cover a little, a few times.
	peek.beckon()


## The button that opens it, beside it, for the device in hand; a finger on a touch screen.
func _show_glyph() -> void:
	if _glyph != null:
		_glyph.queue_free()
		_glyph = null
	var glyph := (
		InputGlyph.of_finger(Palette.CHIP_WHITE, GLYPH_SIZE)
		if TouchInput.enabled
		else InputGlyph.of_action(
			InputActions.JOKER_MENU, _keyboard, Palette.CHIP_WHITE, GLYPH_SIZE
		)
	)
	if glyph == null:
		return
	glyph.name = "FolderGlyph"
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	peek.add_child(glyph)
	glyph.position = Vector2(FolderPeek.SIZE.x - GLYPH_AT.x - GLYPH_SIZE, GLYPH_AT.y)
	glyph.rotation = -FolderPeek.TILT
	_glyph = glyph


func _input(event: InputEvent) -> void:
	if not visible or peek == null or notes != null:
		return
	var was := _keyboard
	_keyboard = LicenseView.keyboard_after(event, _keyboard)
	if was != _keyboard:
		_show_glyph()
	if event.is_action_pressed(InputActions.JOKER_MENU):
		get_viewport().set_input_as_handled()
		open()


## The folder open over the slip.
func open() -> void:
	if notes != null:
		return
	_from = get_viewport().gui_get_focus_owner()
	notes = NotesFolder.open(self, Game.settings.profile, _keyboard, peek)
	notes.put_away.connect(_on_put_away)


func _on_put_away() -> void:
	notes = null
	peek.corner = FolderPeek.first_new(Game.settings.profile.story)
	peek.queue_redraw()
	if _from != null and is_instance_valid(_from):
		_from.grab_focus()
