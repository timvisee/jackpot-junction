class_name KillFeed
extends VBoxContainer
## The last few kills in the top right, GAME.md 8.3, newest at the top: who took out whom and
## how. Lines hold for a few seconds and fade away, and only the newest handful are kept, so the
## feed never grows into the arena. It hears the kills of [member match_node] itself, and the other
## news it carries: a decoy destroyed, a bounty called or collected, a player shown out. A kill a
## decoy made says so, "Ann's decoy shot Bo", and so does a decoy's end, "Bo shot Ann's decoy":
## the kill is the owner's either way, but a player taken out by the copy of somebody across the
## room wants to know it was the copy. A kill by a bullet that came off a wall first has the mark
## of a ricochet at its end, see [BounceIcon], and how many walls it came off beside it if more
## than one: no words for it, the line says enough already.

const MAX_ROWS := 5
const HOLD := 6.0
const FADE := 1.2
const FONT_SIZE := 18
## Color for the verb between the two names, and for a death nobody gets credit for.
const NEUTRAL := Color(0.78, 0.78, 0.82)

## How a death reads, by the cause the match reports.
const VERBS: Dictionary[StringName, String] = {
	&"bullet": "shot",
	&"ram": "rammed",
	&"bomb": "bombed",
	&"pit": "shoved",
}

## The match whose kills it says, by its players' names and colors; none for a feed that is only
## told, as in a test.
var match_node: Match
## How tall the feed may grow, or 0 for as tall as its rows make it. On a touch screen it hangs over
## the corner the driving buttons are in and stops short of them, GAME.md 4.2, dropping its oldest
## lines first.
var room := 0.0

## Row labels newest first, each with the seconds it has been up.
var _rows: Array[RichTextLabel] = []
var _ages: PackedFloat32Array = []
## The victims of the next kills that came about some way their cause does not say, see
## [signal Events.kill_detailed]: slot to whether the killer's decoy did it and how many walls the
## bullet came off.
var _details: Dictionary[int, Array] = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	offset_right = -16.0
	offset_top = 16.0
	alignment = BoxContainer.ALIGNMENT_BEGIN
	add_theme_constant_override("separation", 2)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Events.kill_detailed.connect(_on_kill_detailed)
	Events.kart_killed.connect(_on_kart_killed)
	Events.decoy_destroyed.connect(_on_decoy_destroyed)
	Events.bounty_called.connect(_on_bounty_called)
	Events.bounty_claimed.connect(_on_bounty_claimed)
	Events.player_kicked.connect(_on_player_kicked)


func _exit_tree() -> void:
	for connected: Array in [
		[Events.kill_detailed, _on_kill_detailed],
		[Events.kart_killed, _on_kart_killed],
		[Events.decoy_destroyed, _on_decoy_destroyed],
		[Events.bounty_called, _on_bounty_called],
		[Events.bounty_claimed, _on_bounty_claimed],
		[Events.player_kicked, _on_player_kicked],
	]:
		var event: Signal = connected[0]
		if event.is_connected(connected[1]):
			event.disconnect(connected[1])


func _on_kill_detailed(victim_slot: int, by_decoy: bool, bounces: int) -> void:
	_details[victim_slot] = [by_decoy, bounces]


func _on_kart_killed(victim_slot: int, killer_slot: int, cause: StringName) -> void:
	var detail: Array = _details.get(victim_slot, [false, 0])
	_details.erase(victim_slot)
	var victim := _name(victim_slot)
	if victim.is_empty():
		return
	var bounces := int(detail[1])
	if bool(detail[0]) and killer_slot >= 0 and killer_slot != victim_slot:
		var decoy := _decoys(_tag(_name(killer_slot), _color(killer_slot)))
		_push(_label(), _by(decoy, _tag(victim, _color(victim_slot)), cause), bounces)
		return
	var killer := _name(killer_slot)
	add_kill(victim, _color(victim_slot), killer, _color(killer_slot), cause, bounces)


func _on_decoy_destroyed(owner_slot: int, by_slot: int, cause: StringName) -> void:
	var owner := _name(owner_slot)
	if owner.is_empty():
		return
	var decoy := _decoys(_tag(owner, _color(owner_slot)))
	var line := "%s %s" % [decoy, "fell in" if cause == &"pit" else "was wrecked"]
	if by_slot == owner_slot:
		line = "%s took out their own decoy" % _tag(owner, _color(owner_slot))
	elif by_slot >= 0 and not _name(by_slot).is_empty():
		line = _by(_tag(_name(by_slot), _color(by_slot)), decoy, cause)
	_push(_label(), line)


## [param tagged], a name as the feed writes it, with "'s decoy" after it in the feed's own gray.
static func _decoys(tagged: String) -> String:
	return "%s's decoy" % tagged


func _on_bounty_called(slot: int) -> void:
	if match_node != null:
		add_line("a bounty on %s" % _name(slot), Palette.CHIP_GOLD)


func _on_bounty_claimed(killer_slot: int, victim_slot: int, amount: int) -> void:
	if match_node != null:
		var said := "%s collected %d on %s" % [_name(killer_slot), amount, _name(victim_slot)]
		add_line(said, Palette.CHIP_GOLD)


## Said quietly, in the feed rather than over the middle of the screen, GAME.md 10.3.
func _on_player_kicked(named: String) -> void:
	if match_node != null:
		add_line(NetConduct.TOLD % named, NEUTRAL)


func _name(slot: int) -> String:
	if match_node == null or slot < 0 or slot >= match_node.slots.size():
		return ""
	return match_node.slots[slot].display_name()


func _color(slot: int) -> Color:
	if match_node == null or slot < 0 or slot >= match_node.slots.size():
		return NEUTRAL
	return match_node.slots[slot].color()


func row_count() -> int:
	return _rows.size()


## The newest line's plain text, for tests.
func newest_text() -> String:
	return _rows[0].get_parsed_text() if not _rows.is_empty() else ""


## Adds a kill. [param killer] is empty when nobody gets the credit, for example a kart that
## drove into a pit by itself. [param bounces] is how many walls the bullet that did it came off.
func add_kill(
	victim: String,
	victim_color: Color,
	killer: String,
	killer_color: Color,
	cause: StringName,
	bounces := 0
) -> void:
	_push(_label(), _line(victim, victim_color, killer, killer_color, cause), bounces)


## One line of the feed, before it is given its words.
static func _label() -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("normal_font", Type.TEXT)
	label.add_theme_font_override("bold_font", Type.STRONG)
	label.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	label.add_theme_font_size_override("bold_font_size", FONT_SIZE)
	label.add_theme_color_override("default_color", NEUTRAL)
	# A line of colored names over a bright table is a line nobody can read, GAME.md 8.3, so
	# every one of them carries its own scrim rather than trusting the felt to be dark.
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.75))
	return label


## Adds a line of its own, for news that is not a kill: a bounty called or collected.
func add_line(text: String, color: Color) -> void:
	add_kill(text, color, "", color, &"line")


## Puts up [param line], with the mark of a ricochet at its end for [param bounces] walls, and how
## many beside it past one.
func _push(label: RichTextLabel, line: String, bounces := 0) -> void:
	if bounces <= 0:
		label.text = "[right]%s[/right]" % line
	else:
		label.append_text("[right]%s " % line)
		label.add_image(BounceIcon.texture(NEUTRAL), FONT_SIZE, FONT_SIZE)
		label.append_text(("\u00d7%d" % bounces if bounces > 1 else "") + "[/right]")
	add_child(label)
	move_child(label, 0)
	_rows.push_front(label)
	_ages.insert(0, 0.0)
	while _rows.size() > MAX_ROWS:
		_drop(_rows.size() - 1)


func _process(delta: float) -> void:
	while room > 0.0 and _rows.size() > 1 and get_combined_minimum_size().y > room:
		_drop(_rows.size() - 1)
	for i: int in range(_rows.size() - 1, -1, -1):
		_ages[i] += delta
		var over := _ages[i] - HOLD
		if over >= FADE:
			_drop(i)
		elif over > 0.0:
			_rows[i].modulate.a = 1.0 - over / FADE


func _drop(index: int) -> void:
	_rows[index].queue_free()
	_rows.remove_at(index)
	_ages.remove_at(index)


## The wording. Without a killer the kart wrecked itself, and a pit is a fall unless someone
## bumped the victim into it. A turret's kill is its owner's, and says whose turret it was: a
## player who was shot by somebody on the far side of the room wants to know it was the turret
## that got them, not the kart they can see nowhere near.
func _line(
	victim: String, victim_color: Color, killer: String, killer_color: Color, cause: StringName
) -> String:
	var red := _tag(victim, victim_color)
	if cause == &"line":
		return red
	if killer.is_empty():
		return "%s %s" % [red, "fell in" if cause == &"pit" else "wrecked itself"]
	if killer == victim:
		var own := "was shot by their own turret" if cause == &"turret" else "wrecked itself"
		return "%s %s" % [red, own]
	return _by(_tag(killer, killer_color), red, cause)


## A kill somebody else made, by [param cause]: [param blue] did it to [param red].
static func _by(blue: String, red: String, cause: StringName) -> String:
	match cause:
		&"pit":
			return "%s shoved %s in" % [blue, red]
		&"turret":
			return "%s's turret shot %s" % [blue, red]
	return "%s %s %s" % [blue, VERBS.get(cause, "took out"), red]


func _tag(text: String, color: Color) -> String:
	return "[b][color=#%s]%s[/color][/b]" % [color.to_html(false), text]
