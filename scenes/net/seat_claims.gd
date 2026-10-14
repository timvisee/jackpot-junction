class_name SeatClaims
extends RefCounted
## What a seat at a client says of itself to the host the moment the seat is known, GAME.md 3.8 and
## 10.3: the host made the seat before it could ask who was sitting in it. Its name, an empty one
## leaving the funny name the host already handed out standing; its kart's dress; its plate; and
## its favorite color, which the host puts it in only if nobody else in the room is in it. Each is
## the host's to put on, and reaches every screen in the snapshot.


static func say(session: NetSession, each: ClientSeat, number: int) -> void:
	session.claims.say_name(PlayerNames.clean(each.player_name), number)
	if not each.style.is_empty():
		session.claims.say_style(each.style, number)
	session.claims.say_plate(Game.settings.seat_plate(number), number)
	var color := Game.settings.seat_color(number)
	if color >= 0:
		session.claims.say_color(color, number)
