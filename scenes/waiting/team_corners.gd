class_name TeamCorners
extends Node3D
## The waiting room's corners in team play, GAME.md 3.14 and 9.6: a mat painted on the concrete in
## each team's corner, in the team's color with its suit large on it. A player who drives onto
## another team's mat and stops there is moved to that team, the ring a kart wears cashing out
## filling round them over [constant CHARGE] seconds, so a kart drifting across a corner on its way
## somewhere else is not moved by it. A seat sitting down, or a kart back from a crash, is put down
## in its team's corner.
##
## The host decides, as it decides who is ready, since the host is the machine that sees every kart
## where it is; a client draws the mats for the number of teams the snapshot says, and each move
## arrives with the seat's team, and the puff of it as [signal Events.team_joined].

## Each team's corner, as a share of the room's half size: Hearts front left, nearest the camera,
## Spades front right, Diamonds back right and Clubs back left, the back two clear of the stalls
## along the back wall.
const CORNERS: Array[Vector2] = [
	Vector2(-0.82, 0.75), Vector2(0.82, 0.75), Vector2(0.82, -0.75), Vector2(-0.82, -0.75)
]
## How big a mat is across, how much of it its suit fills, and how far its paint is darkened so the
## suit stands out on it.
const MAT := 2.3
const SUIT := 0.72
const SHADE := 0.25
const PAPER := Color(0.97, 0.95, 0.9)
## How long a kart stands on a mat before it is moved, and how slow it has to be going, as a share
## of its top speed, for that to count as standing there.
const CHARGE := 0.67
const SLOW := 0.35
## Where a team's karts are put down: beside its mat toward the middle of the room, [constant
## CLEAR] off its edge so the suit is not hidden under a kart, and [constant STEP] apart.
const CLEAR := 1.0
const STEP := 1.7

var match_node: Match

## How many teams the mats are built for, and in which palette, see [member Palette.vision].
var _built := -1
var _vision := ""
## Seat to how long its kart has stood on another team's mat.
var _charge: Dictionary[int, float] = {}
## Whether the karts here have been put in their corners since there were teams to put them in.
var _placed := false


## The corners of [param in_match], the waiting room's.
static func add_to(in_match: Match) -> TeamCorners:
	var corners := TeamCorners.new()
	corners.name = "TeamCorners"
	corners.match_node = in_match
	# Where the players pick their teams, and the only room a client may ask to change one in.
	in_match.add_to_group(SeatIdentity.PICKING_TEAMS)
	in_match.add_child(corners)
	return corners


## Everybody in [param match_node] on a team of the number it now has, GAME.md 9.6: the one they
## were on if it is still there, and otherwise the smallest; on none without teams.
static func reseat(match_node: Match) -> void:
	var count := match_node.rules.teams
	var moving: Array[PlayerSlot] = []
	for slot: PlayerSlot in match_node.slots:
		if count <= 0 or slot.input is VacantSeat:
			SeatIdentity.join_team(slot, -1)
		elif slot.team < 0 or slot.team >= count:
			slot.team = -1
			moving.append(slot)
	for slot: PlayerSlot in moving:
		SeatIdentity.join_team(slot, Teams.smallest(match_node.slots, count))


func _ready() -> void:
	Events.team_joined.connect(_on_team_joined)
	Events.player_joined.connect(_on_arrived)
	Events.kart_respawned.connect(_on_respawned)


func _exit_tree() -> void:
	Events.team_joined.disconnect(_on_team_joined)
	Events.player_joined.disconnect(_on_arrived)
	Events.kart_respawned.disconnect(_on_respawned)


## Where [param team]'s corner is in the room.
func corner(team: int) -> Vector3:
	var half := match_node.arena.world_size() * 0.5
	var share := CORNERS[posmod(team, CORNERS.size())]
	return Vector3(share.x * half.x, 0.0, share.y * half.y)


## Whose mat [param at] is on, or -1.
func mat_under(at: Vector3) -> int:
	for team: int in maxi(_built, 0):
		var off := at - corner(team)
		if absf(off.x) <= MAT * 0.5 and absf(off.z) <= MAT * 0.5:
			return team
	return -1


func _process(_delta: float) -> void:
	if match_node.arena == null:
		return
	var count := match_node.rules.teams
	if count != _built or Palette.vision != _vision:
		_build(count)
	if count <= 0:
		_placed = false
	elif not _placed and not match_node.puppet:
		_placed = true
		for slot: PlayerSlot in match_node.slots:
			_put_in_corner(slot)


func _physics_process(delta: float) -> void:
	if match_node.puppet or _built <= 0:
		_charge.clear()
		return
	for slot: PlayerSlot in match_node.slots:
		var kart := slot.kart
		if not slot.is_human() or kart == null or not kart.is_active():
			_stop(slot)
			continue
		var team := mat_under(kart.global_position)
		var slow := kart.motor.velocity.length() < kart.stats.top_speed * SLOW
		if team < 0 or team == slot.team or not slow:
			_stop(slot)
			continue
		var held: float = _charge.get(slot.index, 0.0) + delta
		_charge[slot.index] = held
		kart.channel_progress = clampf(held / CHARGE, 0.0, 1.0)
		if held >= CHARGE:
			_stop(slot)
			SeatIdentity.move_to_team(match_node, slot, team)


func _stop(slot: PlayerSlot) -> void:
	if not _charge.has(slot.index):
		return
	_charge.erase(slot.index)
	if slot.kart != null:
		slot.kart.channel_progress = -1.0


func _build(count: int) -> void:
	for child: Node in get_children():
		child.queue_free()
	_built = count
	_vision = Palette.vision
	for team: int in count:
		add_child(_mat(team))


## [param team]'s mat: a plate of its color with its suit painted on in cream, its top toward the
## back wall, so it reads the right way up from the camera at the front of the room.
func _mat(team: int) -> Node3D:
	var mat := Node3D.new()
	mat.name = "Mat%d" % team
	mat.position = corner(team)
	var plate := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(MAT, 0.02, MAT)
	plate.mesh = box
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Teams.color(team).darkened(SHADE)
	paint.roughness = 0.9
	plate.material_override = paint
	plate.position.y = 0.01
	plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mat.add_child(plate)
	var suit := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * MAT * SUIT
	suit.mesh = quad
	var ink := StandardMaterial3D.new()
	ink.albedo_color = PAPER
	ink.albedo_texture = TeamPennant.mask(TeamArt.suit_of(team))
	ink.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	ink.alpha_scissor_threshold = 0.5
	ink.roughness = 0.9
	suit.material_override = ink
	suit.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	suit.position.y = 0.025
	suit.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mat.add_child(suit)
	return mat


## [param slot]'s kart put down in its team's corner, facing the pad: beside the mat, toward the
## middle of the room, each of the team a little further along.
func _put_in_corner(slot: PlayerSlot) -> void:
	var kart := slot.kart
	if slot.team < 0 or kart == null or not kart.alive or not slot.is_human():
		return
	var mates := Teams.members(match_node.slots, slot.team)
	var at := corner(slot.team)
	var along := MAT * 0.5 + CLEAR + STEP * mates.find(slot)
	var spot := at + Vector3(0.0, 0.0, -signf(at.z)) * along
	kart.global_position = spot
	kart.face(match_node.arena.junction_position - spot)
	kart.motor.velocity = Vector3.ZERO
	kart.velocity = Vector3.ZERO


## A move to [param team], on every screen: a puff of the team's color off the kart.
func _on_team_joined(slot: int, team: int) -> void:
	if slot < 0 or slot >= match_node.slots.size():
		return
	var kart := match_node.slots[slot].kart
	if kart != null and kart.alive:
		Burst.spawn(match_node, kart.global_position, Teams.color(team), 1.0, 20)


## Somebody sat down, here or at another machine: into their team's corner.
func _on_arrived(slot: int) -> void:
	if not match_node.puppet and _built > 0 and slot < match_node.slots.size():
		_put_in_corner(match_node.slots[slot])


## Back from a crash, GAME.md 9.6: in the team's corner rather than wherever the room put it.
func _on_respawned(slot: int, _at: Vector3) -> void:
	_on_arrived(slot)
