class_name LobbyPad
extends Node
## The pad in the lobby as a room fills it, GAME.md 9.6. A room of eight has to get eight karts onto
## one pad and keep them there, so the pad makes room for them. Past four players it grows, so each
## kart has as much of it as in a room of four. A kart standing on it may roll a little past its
## edge and still be on it. And nothing on it can be knocked off: karts on or by the pad drive
## through each other, so nobody arriving shoves anybody off and nobody parked is in the way, and a
## shot at a kart there is spent on it harmlessly.
##
## Every machine works all of it out from the karts it can see, as it fills the ring, see
## [ReadyRoom]: how big the pad is from how many are in the room, and who stands on it from where
## their karts are.

## Up to this many players the pad keeps the size the map gives it; past it, the pad's area grows
## with each player so everybody keeps the floor they had in a room of four: 2.5 m across its radius
## with four, 3.5 m with eight.
const ROOMY := 4
## How quickly the pad comes to its new size, as a rate: most of the way in about half a second.
const GROW_RATE := 8.0
## How far past the pad's edge a kart already standing on it may roll and still be on it, in
## meters, and the reach of the pad's shelter, see [method sheltering].
const SLACK := 1.0
## How far apart two karts' middles have to be before they bump into each other again once neither
## is by the pad: further than the longest way across both, so two karts that drove through each
## other are never made solid while one is still inside the other, which would throw them apart.
const CLEAR := 2.0

var match_node: Match
var pad: JunctionPad
## The pad's radius as the map built it, as it stands now, and as it is growing toward.
var base := 2.5
var radius := 2.5
var target := 2.5
## Slot index to whether that player's kart stands on the pad, see [method _step_standing].
var standing: Dictionary[int, bool] = {}


## The lobby's pad of [param in_match], or null for a room without one.
static func add_to(in_match: Match) -> LobbyPad:
	var pad := in_match.arena.junction
	if pad == null:
		return null
	var made := LobbyPad.new()
	made.name = "LobbyPad"
	made.match_node = in_match
	made.pad = pad
	made.base = pad.radius
	made.radius = pad.radius
	made.target = pad.radius
	in_match.add_child(made)
	return made


## The radius a pad built at [param built] grows to for a room of [param players].
static func grown(built: float, players: int) -> float:
	return built * sqrt(float(maxi(players, ROOMY)) / float(ROOMY))


## Before the karts move, so a kart driving onto the pad meets the room as it stands this tick.
func _physics_process(delta: float) -> void:
	_grow(delta)
	var karts := _karts()
	var near: Dictionary[Kart, bool] = {}
	for kart: Kart in karts:
		near[kart] = sheltering(kart)
		kart.sheltered = near[kart]
	_step_standing()
	_let_through(karts, near)


## The pad toward its size for the room as it is now, the ring round it with it, see [ReadyRoom].
func _grow(delta: float) -> void:
	target = grown(base, _players())
	if is_equal_approx(radius, target):
		return
	radius = lerpf(radius, target, minf(delta * GROW_RATE, 1.0))
	if absf(radius - target) < 0.01:
		radius = target
	pad.resize(radius)
	match_node.arena.junction_radius = radius


## How far [param kart]'s body is from the pad's middle, in meters, 0 for over it.
func reach(kart: Kart) -> float:
	return KartCollisions.distance_to_body(kart, pad.global_position)


## Whether [param kart] is on the pad: any part of it over the pad, or for a kart already standing
## on it, within [constant SLACK] of it.
func stands(kart: Kart, already: bool) -> bool:
	if not _playing(kart):
		return false
	return reach(kart) <= radius + (SLACK if already else 0.0)


## Whether [param kart] is in the pad's shelter: on it or within [constant SLACK] of it, where
## other karts drive through it and no shot hurts it.
func sheltering(kart: Kart) -> bool:
	return _playing(kart) and reach(kart) <= radius + SLACK


## Who is standing on the pad this tick. Coming on takes the pad itself; staying on takes only the
## slack past its edge, so a kart that rolled a little too far, or that the pad shrank out from
## under as somebody left, has not left it.
func _step_standing() -> void:
	var now: Dictionary[int, bool] = {}
	for slot: PlayerSlot in match_node.slots:
		if slot.kart != null and stands(slot.kart, standing.get(slot.index, false)):
			now[slot.index] = true
	standing = now


## Every two karts, either of them by the pad, drive through each other rather than bumping, and
## go back to bumping once neither is by the pad and they are clear of each other.
func _let_through(karts: Array[Kart], near: Dictionary[Kart, bool]) -> void:
	for i: int in karts.size():
		for j: int in range(i + 1, karts.size()):
			var one := karts[i]
			var other := karts[j]
			var through := one.get_collision_exceptions().has(other)
			var apart := one.global_position.distance_to(other.global_position) > CLEAR
			var wanted := near[one] or near[other] or (through and not apart)
			if wanted == through:
				continue
			if wanted:
				one.add_collision_exception_with(other)
				other.add_collision_exception_with(one)
			else:
				one.remove_collision_exception_with(other)
				other.remove_collision_exception_with(one)


## Whether [param kart] is a kart of this room on the floor, not one gone down a hole or another
## room's sharing the tree in a test, see [method JunctionPad._ours].
func _playing(kart: Kart) -> bool:
	return kart != null and kart.alive and not kart.falling and kart.rules == match_node.rules


func _karts() -> Array[Kart]:
	var karts: Array[Kart] = []
	for slot: PlayerSlot in match_node.slots:
		if slot.kart != null and is_instance_valid(slot.kart):
			karts.append(slot.kart)
	return karts


## How many players are in the room. Bots never are: nobody waits on them.
func _players() -> int:
	var players := 0
	for slot: PlayerSlot in match_node.slots:
		if slot.is_human():
			players += 1
	return players
