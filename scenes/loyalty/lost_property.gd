class_name LostProperty
extends Node
## Lost Property, GAME.md 8.9 and STORY.md 6.6b: the Department's landmark for each room somebody
## lost something in, the driving school's traffic cone, the Workbench's tape measure, After Hours'
## fuzzy dice and the Yard's hard hat. Once its landmark is open on the profile playing's map, the
## thing may lie on the floor of its room, in a spot of its own on each map, see [method spot_on]:
## something lost rather than something put out, by a wall, in a corner, never on a pad or the
## Junction. It is there for the whole of a map on an even chance, and for certain in one once it
## has missed two, the way a note turns up; and while it lies there a manila tag hangs beside the
## clock, see [LostTag], so a player knows it is in this map, though not where.
##
## It lies on this machine's floor only, as a note does: only this machine's karts take it, by
## driving over it, no bot goes for it, nothing in the match moves it, and nothing of it goes over
## the wire. Taken, it is found for every profile at this machine whose map has it open, and the bet
## is met, which the program settles as the room is written down, see [LoyaltyRecord].

## The chance it is there in a map, and how many maps it may miss before it is there for certain.
const CHANCE := 0.5
const CERTAIN_AFTER := 2
## How much bigger it lies than it is worn, so it is seen on the floor, and how close a kart comes
## to take it.
const SCALE := 1.6
const REACH := 0.9
## The driving school's place, which is no room of its own: the Garage's, set for the test.
const SCHOOL := &"driving_school"

## For a test: decides headless too.
static var anywhere := false

var match_node: Match
## Where it is: a room's id, or the driving school.
var place := &""
## The chance it is there in this map, for a test to settle.
var chance := CHANCE
## The landmark it is lost for, the thing on the floor, and the tag beside the clock.
var landmark: LoyaltyLandmark
var thing: Node3D
var tag: LostTag
var taken := false

var _decided := false
var _rng := RandomNumberGenerator.new()


## Lost Property for [param in_match], in [param at]: a room's id, or none for the room the arena is
## in.
static func add_to(in_match: Match, at := &"") -> LostProperty:
	var lost := LostProperty.new()
	lost.name = "LostProperty"
	lost.match_node = in_match
	lost.place = at
	in_match.add_child(lost)
	return lost


## The landmark of the Department's Lost Property for [param at], a room's id or the driving
## school, or null for a place nothing was lost in.
static func landmark_for(at: StringName) -> LoyaltyLandmark:
	for each: LoyaltyLandmark in Loyalty.map().landmarks:
		if each.kind == LoyaltyLandmark.Kind.FIND and each.stat == at:
			return each
	return null


## Whether [param landmark]'s thing is lost for [param profile]: welcomed, its landmark open on its
## map and not found yet.
static func due(profile: Profile, landmark: LoyaltyLandmark) -> bool:
	if landmark == null or not profile.loyalty.welcomed:
		return false
	if profile.loyalty.has_found(landmark.id):
		return false
	return Loyalty.standing(profile, landmark) == Loyalty.Standing.OPEN


## Whether [param landmark]'s thing turns up in this map for [param profile]: an even chance, or
## [param odds], or for certain once it has missed [constant CERTAIN_AFTER] maps.
static func turns_up(
	profile: Profile, landmark: LoyaltyLandmark, rng: RandomNumberGenerator, odds := CHANCE
) -> bool:
	if int(profile.loyalty.lost_waits.get(String(landmark.id), 0)) >= CERTAIN_AFTER:
		return true
	return rng.randf() < odds


func _ready() -> void:
	_rng.randomize()


func _exit_tree() -> void:
	if tag != null and is_instance_valid(tag):
		tag.queue_free()


func _process(_delta: float) -> void:
	if match_node == null or match_node.arena == null:
		return
	if not _decided:
		if place != SCHOOL and match_node.state != Match.State.PLAYING:
			return
		_decide()
	if thing != null and not taken:
		_check_takers()


## As the flag drops, or as the school opens: whether the thing lost here lies on the floor in
## this map. A map it could have and did not counts toward its being certain.
func _decide() -> void:
	_decided = true
	if Game.is_headless() and not anywhere:
		return
	var at := place
	if at == &"" and match_node.arena.room != null:
		at = match_node.arena.room.id
	landmark = landmark_for(at)
	var profile := Game.settings.profile
	if not due(profile, landmark):
		return
	var waits := profile.loyalty.lost_waits
	if not turns_up(profile, landmark, _rng, chance):
		waits[String(landmark.id)] = int(waits.get(String(landmark.id), 0)) + 1
		return
	waits.erase(String(landmark.id))
	_lay()


## The thing on the floor in its spot, and the tag beside the clock.
func _lay() -> void:
	var grid := match_node.arena.grid
	var cell := spot_on(grid, String(landmark.id) + String(match_node.rules.map))
	if cell.x < 0:
		return
	thing = KartDress.lost(landmark.dress)
	thing.name = "LostThing"
	thing.scale = Vector3.ONE * SCALE
	match_node.arena.add_child(thing)
	thing.position = grid.cell_center(cell)
	thing.rotation.y = LoyaltyMapLayout.wobble(String(landmark.id)) * PI
	var hud := match_node.hud
	var clock := hud.get_node_or_null("Clock") as Control if hud != null else null
	if clock != null:
		tag = LostTag.hang_on(clock, landmark)


## The first of this machine's human karts over the thing takes it.
func _check_takers() -> void:
	var reach := match_node.rules.pickup_radius + REACH
	for slot: PlayerSlot in match_node.slots:
		if not slot.is_local_human() or slot.kart == null or not slot.kart.alive:
			continue
		var apart := slot.kart.global_position - thing.global_position
		if Vector2(apart.x, apart.z).length() <= reach:
			take(slot)
			return


## Taken by the kart of [param slot]: found for every profile at this machine whose map has it
## open, kept there and then, and gone from the floor; the tag stamped claimed.
func take(slot: PlayerSlot) -> void:
	if taken:
		return
	taken = true
	var finders: Array[Profile] = [Game.settings.profile]
	var own := MatchRecord.profile_of(slot)
	if own != null and own not in finders:
		finders.append(own)
	for profile: Profile in finders:
		if due(profile, landmark):
			profile.loyalty.find(landmark.id)
	if not Game.is_headless():
		Game.settings.save_to_disk()
	Audio.play_sfx(&"page", -6.0, 0.05)
	if thing != null:
		thing.queue_free()
		thing = null
	if tag != null and is_instance_valid(tag):
		tag.claim()


## Where the thing lost on [param grid] lies, the same every time for [param seed]: bare floor in
## the room the karts start in, clear of everything a kart is sent to, see [NoteDealer], as far from
## the Junction as it can be and up against a wall, the way a thing lost ends up. (-1, -1) for none.
static func spot_on(grid: ArenaGrid, seed: String) -> Vector2i:
	var home := grid.region_of(grid.spawns[0]) if not grid.spawns.is_empty() else -1
	var middles: Array[Vector2i] = []
	for y: int in grid.height:
		for x: int in grid.width:
			if grid.glyph(Vector2i(x, y)) in [ArenaGrid.JUNCTION, ArenaGrid.JACKPOT]:
				middles.append(Vector2i(x, y))
	var best := Vector2i(-1, -1)
	var best_score := -INF
	for y: int in range(1, grid.height - 1):
		for x: int in range(1, grid.width - 1):
			var cell := Vector2i(x, y)
			if grid.glyph(cell) != ArenaGrid.FLOOR or grid.region_of(cell) != home:
				continue
			if not NoteDealer._clear(grid, cell):
				continue
			var far := 0.0
			if not middles.is_empty():
				far = INF
				for middle: Vector2i in middles:
					far = minf(far, Vector2(cell - middle).length())
			var walls := 0
			for dy: int in range(-2, 3):
				for dx: int in range(-2, 3):
					if grid.glyph(cell + Vector2i(dx, dy)) in [ArenaGrid.WALL, ArenaGrid.CRATE]:
						walls += 1
			var score := far + walls * 1.5 + LoyaltyMapLayout.wobble(seed + str(cell)) * 2.0
			if score > best_score:
				best_score = score
				best = cell
	return best
