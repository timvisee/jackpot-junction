class_name SeatWire
extends Node
## What a client says of its seats on the wire, GAME.md 4.4 and 10.3: each player's name, how their
## kart is dressed, its plate, and their color or team. Each is the client's own to say and the
## host's to put on, and it reaches the other screens in the snapshot like the rest of the roster.
## Each is a message a person sends by hand, and one longer than any copy of the game sends is heard
## as such, see [method NetConduct.said_within].
##
## Under the session at both ends, as a call from one to the other has to be.

var session: NetSession


func _init(of: NetSession) -> void:
	session = of
	name = "Seats"


## At a client: the player at its seat [param number] is called [param claimed], cleaned.
func say_name(claimed: String, number: int) -> void:
	_named.rpc_id(1, claimed, number)


## At a client: the player at its seat [param number] dressed their kart as [param style].
func say_style(style: PackedInt32Array, number: int) -> void:
	_dressed.rpc_id(1, style, number)


## At a client: the kart of the player at its seat [param number] wears [param plate].
func say_plate(plate: String, number: int) -> void:
	_plated.rpc_id(1, plate, number)


## At a client: the player at its seat [param number] asks for [param color], or past the colors a
## team, see [constant SeatIdentity.TEAM_CLAIM].
func say_color(color: int, number: int) -> void:
	_colored.rpc_id(1, color, number)


@rpc("any_peer", "call_remote", "reliable")
func _named(claimed: String, number := 0) -> void:
	var slot := _claimed_by(claimed.length(), PlayerNames.MAX_LENGTH, number)
	var named := PlayerNames.clean(claimed)
	if slot != null and not named.is_empty():
		slot.player_name = named


@rpc("any_peer", "call_remote", "reliable")
func _dressed(claimed: PackedInt32Array, number := 0) -> void:
	var slot := _claimed_by(claimed.size(), KartStyle.CHOICES.size(), number)
	if slot != null:
		StyleStalls.dress(slot, claimed)


@rpc("any_peer", "call_remote", "reliable")
func _plated(claimed: String, number := 0) -> void:
	var slot := _claimed_by(claimed.length(), LicensePlate.MOST, number)
	if slot != null and slot.kart != null:
		var body := slot.kart.get_node_or_null("Body") as Node3D
		KartVisuals.plate_like(body, LicensePlate.valid(claimed))


## A color, which the client gets if nobody else in the room is in it, or a team, see
## [method SeatIdentity.claim].
@rpc("any_peer", "call_remote", "reliable")
func _colored(color: int, number := 0) -> void:
	var slot := _claimed_by(0, 0, number)
	if slot != null:
		SeatIdentity.claim(session.match_node, slot, color)


## At the host, in a call from a client carrying [param size] of what no copy of the game sends
## more than [param most] of: the slot the client plays as its seat [param number], once the call
## is counted, or null for one that carried more, a seat it does not play, or no host.
func _claimed_by(size: int, most: int, number: int) -> PlayerSlot:
	var peer := multiplayer.get_remote_sender_id()
	if not session.conduct.said_within(peer, size, most) or not session.is_host:
		return null
	return session.sender_slot(number)
