class_name DemoLine
extends PanelContainer
## The line of the demo for a booth, GAME.md 9.8: Press any button to play, on a ticket of the
## house print, 8.1a, stood on the foot of the screen and breathing slowly, for as long as a seat
## is still a bot's. In a match it is the HUD's, which tells the camera to keep the karts clear of
## it, see [HudCovers]. It is on a layer of its own over everything else on the screen, a joker
## pick, a toast or a menu, since it is the one thing a visitor walking past has to read; only the
## dark between the demo and the full game and the loading screen go over it.

const WORDS := "Press any button to play"
## How long a breath takes, in seconds, and how faint it is at its faintest.
const BREATH := 3.2
const FAINTEST := 0.6
## How far above the foot of the screen it stands.
const FOOT := 22.0
## The layer it is drawn on, over everything but the loading screen, see [constant
## LoadingScreen.LAYER], and the dark of [DemoHost].
const LAYER := 90
## The name of the layer it stands on, in the HUD or the title.
const HOLDER := "DemoLineLayer"

## Whether there is anybody left to say it to, see [DemoHost]. It is put away over the payout slip
## besides, whose ways on stand where it would.
var wanted := true

var _clock := 0.0


## A line called "DemoLine" in [param parent], the HUD or the title, on a layer of its own called
## [constant HOLDER].
static func add_to(parent: Node) -> DemoLine:
	var holder := CanvasLayer.new()
	holder.name = HOLDER
	holder.layer = LAYER
	parent.add_child(holder)
	var line := DemoLine.new()
	line.name = "DemoLine"
	holder.add_child(line)
	return line


## The line in [param parent], the HUD or the title, or null.
static func of(parent: Node) -> DemoLine:
	return parent.get_node_or_null(NodePath(HOLDER + "/DemoLine")) as DemoLine


## The HUD or the title it stands in.
func home() -> Node:
	return get_parent().get_parent()


func _ready() -> void:
	# After the rest of the room's frame, so a slip that came up in it is seen at once.
	process_priority = 100
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_bottom = -FOOT
	var look := TicketStyle.cut(Color(HouseTheme.STOCK, 0.92), 11.0, 36.0, 14.0)
	look.frame = Color(HouseTheme.FOIL, 0.5)
	look.frame_inset = 5.0
	look.shadow = 8.0
	add_theme_stylebox_override("panel", look)
	var words := Label.new()
	words.name = "Words"
	words.text = WORDS
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Type.strong(words, Type.HEADING, HouseTheme.FOIL)
	add_child(words)


func _process(delta: float) -> void:
	var slip := home().get_node_or_null("Results") as Control
	visible = wanted and (slip == null or not slip.visible)
	_clock = fmod(_clock + delta, BREATH)
	var breath := 0.5 + 0.5 * cos(TAU * _clock / BREATH)
	modulate.a = lerpf(FAINTEST, 1.0, breath)
