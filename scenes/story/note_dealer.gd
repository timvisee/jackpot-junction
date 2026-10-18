class_name NoteDealer
extends Node
## Deals Kit's notes onto this machine's table, STORY.md 7.1: as the flag drops, whether the note
## due turns up in this map at all and when on its clock, see [StoryNotes]; at that moment a
## [StoryNote] on open floor; and whether a kart of this machine's humans drives over it, which
## files it for the profile playing there and then. Only in maps, never headless, never with the
## story off or before the license, and nothing of it goes over the wire, 5.3: a client's note is
## on the client's floor alone, outside the pickups the host keeps, and no bot ever sees it.

## The note's own rustle as it is taken, quiet: the House must not hear it.
const RUSTLE_DB := -9.0
## What a note is never put on or beside: anything a kart is sent to or falls down, and where karts
## come back to life. A pit is kept two cells off, everything else one.
const AVOID: Array[String] = [
	ArenaGrid.WALL,
	ArenaGrid.SPAWN,
	ArenaGrid.EXTRA_SPAWN,
	ArenaGrid.COIN_PAD,
	ArenaGrid.POWER_PAD,
	ArenaGrid.TURBO_PAD,
	ArenaGrid.TURBO_UP,
	ArenaGrid.TURBO_DOWN,
	ArenaGrid.TURBO_LEFT,
	ArenaGrid.TURBO_RIGHT,
	ArenaGrid.CRATE,
	ArenaGrid.JUNCTION,
	ArenaGrid.JACKPOT,
	ArenaGrid.FLUSH_PAD,
	ArenaGrid.TARGET,
	ArenaGrid.JOKER_PAD,
	ArenaGrid.PORTAL,
	ArenaGrid.GATE,
	ArenaGrid.SLOT_PAD,
]
const PIT_CLEARANCE := 2
## What the dealers of the maps under way are found by, see [method taken_here].
const GROUP := &"note_dealers"

## For a test: decides headless too, see [method _decide].
static var anywhere := false

var match_node: Match
## The note dealt for this match, 0 for none, and the moment on its clock it turns up.
var number := 0
var at := 0.0
## The note on the floor while it lies there.
var note: StoryNote
## Whether it was taken, and by which slot, for the folder after the map, STORY.md 7.2.
var taken := false
var taken_by := -1
## A note dealt whatever the schedule says, the Final Hand's, STORY.md 8.2.
var forced := 0
## The scrap beside the clock saying a note lies in the map, ticked once it is taken, until the map
## is over, see [NoteMark].
var mark: NoteMark

var _decided := false
var _laid := false
var _counted := false
var _elapsed := 0.0
var _rng := RandomNumberGenerator.new()


static func add_to(in_match: Match, forced_note := 0) -> NoteDealer:
	var dealer := NoteDealer.new()
	dealer.name = "NoteDealer"
	dealer.match_node = in_match
	dealer.forced = forced_note
	dealer.add_to_group(GROUP)
	in_match.add_child(dealer)
	return dealer


## Whether a note was taken in a map under way in [param tree], which the folder in the settings
## waits on until the map is over, STORY.md 7.2.
static func taken_here(tree: SceneTree) -> bool:
	for dealer: Node in tree.get_nodes_in_group(GROUP):
		if (dealer as NoteDealer).taken:
			return true
	return false


func _ready() -> void:
	_rng.randomize()
	Events.match_state_changed.connect(_on_state)


func _exit_tree() -> void:
	if Events.match_state_changed.is_connected(_on_state):
		Events.match_state_changed.disconnect(_on_state)
	_missed()
	_take_down()


func _process(delta: float) -> void:
	if match_node == null or match_node.arena == null:
		return
	if not _decided:
		if match_node.state != Match.State.PLAYING:
			return
		_decide()
	if number == 0:
		return
	# Overtime is the map still going, its clock stopped at the whistle's mark: a note lies there to
	# be taken as long as there is a kart to take it.
	var states := [Match.State.PLAYING, Match.State.LAST_CALL, Match.State.OVERTIME]
	var playing: bool = match_node.state in states
	if playing:
		_elapsed += delta
	if not _laid and playing and clock() >= at:
		_lay()
	if note != null and playing:
		_check_takers()


## How long the match has been going on its clock, regular time only.
func clock() -> float:
	if not match_node.rules.timed:
		return _elapsed
	return match_node.rules.duration - match_node.time_left


## The match's length on its clock, or five minutes for one without a clock.
func length() -> float:
	return match_node.rules.duration if match_node.rules.timed else 300.0


## As the flag drops: the debug build's note at once, the forced note somewhere in the match, or
## the note due, if it turns up. A map it was due for and did not turn up in counts toward its
## being certain.
func _decide() -> void:
	_decided = true
	if Game.is_headless() and not anywhere:
		return
	if Story.note_now > 0:
		number = Story.note_now
		Story.note_now = 0
		at = minf(1.0, length() * 0.5)
		return
	if forced > 0:
		number = forced
		at = StoryNotes.moment(length(), _rng)
		return
	var profile := Game.settings.profile
	# The story's note due, or a loose one in a map with none due, STORY.md 7.3.
	var due := StoryNotes.to_deal(profile)
	if due == 0:
		return
	if not StoryNotes.turns_up(profile.story, _rng):
		profile.story.note_waits += 1
		return
	number = due
	at = StoryNotes.moment(length(), _rng, due == 1)


## The note on open floor somewhere a kart can drive to, or nothing on a map with none.
func _lay() -> void:
	_laid = true
	var grid := match_node.arena.grid
	var cell := spot_on(grid, _rng)
	if cell.x < 0:
		number = 0
		return
	var room_id: StringName = match_node.arena.room.id if match_node.arena.room != null else &""
	note = StoryNote.make(number, room_id, match_node.arena.surfaces)
	match_node.arena.add_child(note)
	var off := Vector3(_rng.randf_range(-0.2, 0.2), 0.0, _rng.randf_range(-0.2, 0.2))
	note.position = grid.cell_center(cell) + off * grid.cell_size
	note.rotation.y = _rng.randf_range(0.0, TAU)
	var hud := match_node.hud
	var clock := hud.get_node_or_null("Clock") as Control if hud != null else null
	if clock != null:
		mark = NoteMark.hang_on(clock)


## The first of this machine's human karts within reach of the note takes it, at the radius a chip
## is taken at and nothing more: no magnet, joker or hubcap reaches a note.
func _check_takers() -> void:
	var reach := match_node.rules.pickup_radius + Pickup.RADIUS
	for slot: PlayerSlot in match_node.slots:
		if not slot.is_local_human() or slot.kart == null or not slot.kart.alive:
			continue
		var apart := slot.kart.global_position - note.global_position
		if Vector2(apart.x, apart.z).length() <= reach:
			_take(slot)
			return


func _take(slot: PlayerSlot) -> void:
	taken = true
	taken_by = slot.index
	StoryNotes.file(Game.settings.profile, number)
	# There and then, so a game closed straight after keeps it.
	if not Game.is_headless():
		Game.settings.save_to_disk()
	Audio.play_sfx(&"note", RUSTLE_DB, 0.05, 1.25)
	var hud := match_node.hud
	if hud != null:
		NoteCollected.show_beside(hud, hud.get_node_or_null("Block%d" % slot.index) as Control)
	# To read after the map, beside the slip, online too, and at the Final Hand before its page is
	# answered, STORY.md 8.4.
	SlipFolder.add_to(match_node)
	note.queue_free()
	note = null
	if mark != null and is_instance_valid(mark):
		mark.collect()


func _on_state(state: int) -> void:
	if state == Match.State.RESULTS:
		_missed()
		_take_down()


## The scrap beside the clock gone, the map over.
func _take_down() -> void:
	if mark != null and is_instance_valid(mark):
		mark.queue_free()
	mark = null


## A note dealt that never turned up, the match over before its moment, counts as a map it was due
## for and did not turn up in. One that turned up and was not taken is due again, and certain to
## turn up in the next map as well, whatever the odds after the ending, until it is taken.
func _missed() -> void:
	if _counted or number == 0 or forced > 0 or taken:
		return
	_counted = true
	var story := Game.settings.profile.story
	if _laid:
		story.note_waits = maxi(story.note_waits, Story.NOTE_CERTAIN_AFTER)
	else:
		story.note_waits += 1


## A floor cell for a note on [param grid], drawn with [param rng]: bare floor in the room the
## karts start in, nothing to avoid beside it and no pit within two cells. (-1, -1) for none.
static func spot_on(grid: ArenaGrid, rng: RandomNumberGenerator) -> Vector2i:
	var home := grid.region_of(grid.spawns[0]) if not grid.spawns.is_empty() else -1
	var open: Array[Vector2i] = []
	for y: int in range(1, grid.height - 1):
		for x: int in range(1, grid.width - 1):
			var cell := Vector2i(x, y)
			if grid.glyph(cell) != ArenaGrid.FLOOR or grid.region_of(cell) != home:
				continue
			if _clear(grid, cell):
				open.append(cell)
	if open.is_empty():
		return Vector2i(-1, -1)
	return open[rng.randi_range(0, open.size() - 1)]


static func _clear(grid: ArenaGrid, cell: Vector2i) -> bool:
	for dy: int in range(-PIT_CLEARANCE, PIT_CLEARANCE + 1):
		for dx: int in range(-PIT_CLEARANCE, PIT_CLEARANCE + 1):
			var near := cell + Vector2i(dx, dy)
			if near.x < 0 or near.y < 0 or near.x >= grid.width or near.y >= grid.height:
				continue
			var glyph := grid.glyph(near)
			if glyph == ArenaGrid.PIT:
				return false
			if absi(dx) <= 1 and absi(dy) <= 1 and glyph in AVOID:
				return false
	return true
