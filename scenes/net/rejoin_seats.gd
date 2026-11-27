class_name RejoinSeats
extends RefCounted
## A player back in their own kart in the map they dropped out of, GAME.md 10.8: the game crashed or
## the connection went, and they start it again and join the same game. At the host, the karts of a
## player who goes during a map are kept theirs till the map is over, a bot at the wheel meanwhile
## as ever: on Steam by their account, and off Steam by a secret the host gave them alone, which
## they hand back as they knock. At a client, the last such secret is kept on disk a while with
## where it holds, the host and whoever hosts after it, see [method remember], so the game started
## again knocks with it. The same secret proves who a player was at a new host, see
## [method MatchResume.vouched].

## How long a client keeps the last secret after it was last told it, in seconds.
const KEPT_FOR := 1800.0

## At the host: the secret each client was given, by peer; the clients sent theirs; each client's
## Steam account, read as it knocked, since a peer gone may no longer say; and the clients shown
## out, whose karts are not kept for them.
var _tokens: Dictionary[int, String] = {}
var _told: Dictionary[int, bool] = {}
var _accounts: Dictionary[int, int] = {}
var _out: Dictionary[int, bool] = {}
## At the host: the karts of the players who went during the map in play, by who they were, "a" and
## their Steam account or "t" and the proof of their secret: each seat at their machine to its slot,
## color, team and name, as [method MatchResume.seats_kept] has them.
var _left: Dictionary = {}


## A secret nobody can guess: sixteen random bytes, in hex.
static func new_token() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()


## The secret the client [param peer] is given: made for it once.
func token_of(peer: int) -> String:
	if not _tokens.has(peer):
		_tokens[peer] = new_token()
	return _tokens[peer]


## The clients among [param playing] not sent their secret yet, from now on counted as sent.
func untold(playing: PackedInt32Array) -> Array[int]:
	var due: Array[int] = []
	for peer: int in playing:
		if not _told.has(peer):
			_told[peer] = true
			due.append(peer)
	return due


## [param peer] knocked from the Steam account [param account], 0 off Steam.
func knocked(peer: int, account: int) -> void:
	_accounts[peer] = account


## [param peer] was shown out of the game: nothing kept for it as it goes.
func shown_out(peer: int) -> void:
	_out[peer] = true


## [param peer] has gone from [param session]'s game, holding [param held], each seat at its machine
## to its slot: its karts kept for it while a map is being played, by its account or the proof of
## its secret.
func went(session: NetSession, peer: int, held: Dictionary) -> void:
	var account: int = _accounts.get(peer, 0)
	var token: String = _tokens.get(peer, "")
	var shown := _out.has(peer)
	for each: Dictionary in [_tokens, _told, _accounts, _out]:
		each.erase(peer)
	var match_node := session.match_node
	if shown or match_node == null or held.is_empty() or not match_node.rules.timed:
		return
	if match_node.state not in MatchResume.PLAYING or (account == 0 and token.is_empty()):
		return
	var seats := {}
	for number: Variant in held:
		var index := int(held[number])
		if index >= 0 and index < match_node.slots.size():
			var slot := match_node.slots[index]
			seats[int(number)] = {
				"slot": index,
				"color": slot.color_index,
				"team": slot.team,
				"name": slot.player_name
			}
	if not seats.is_empty():
		_left[_who(account, token)] = seats


## Whoever was kept seats in a map carried over and has not come back for them in the time held:
## kept them for the rest of the map as any player who went is, see [method MatchResume.seats_kept].
func adopt(kept: Dictionary) -> void:
	for who: String in kept:
		var seats: Dictionary = kept[who]
		var proof := ""
		for number: Variant in seats:
			proof = str((seats[number] as Dictionary).get("proof", ""))
		if who.begins_with("a"):
			_left[who] = seats
		elif not proof.is_empty():
			_left["t" + proof] = seats


## The karts kept for a player coming back from the Steam account [param account], or off Steam
## with [param token], taken off the kept: each seat at their machine as [method went] has it;
## empty for nobody known.
func claim(account: int, token: String) -> Dictionary:
	if account == 0 and token.is_empty():
		return {}
	var who := _who(account, token)
	var seats: Dictionary = _left.get(who, {})
	_left.erase(who)
	return seats


## The map is over: nobody's karts are kept any longer.
func forget() -> void:
	_left.clear()


static func _who(account: int, token: String) -> String:
	return "a%d" % account if account != 0 else "t" + token.sha256_text()


## At a client: [param token], the secret just given by the host, kept on disk as the last one,
## with where it holds: the host [param config] joined, and whoever of [param line] hosts after it,
## on [param port].
static func remember(token: String, config: MatchConfig, line: Array, port: int) -> void:
	var settings := Game.settings
	if settings == null or token.is_empty() or config == null or config.address.is_empty():
		return
	var places := PackedStringArray(["%s:%d" % [config.address, config.port]])
	for entry: Variant in line:
		if entry is Dictionary:
			places.append("%s:%d" % [str((entry as Dictionary).get("address", "")), port])
	var until := Time.get_unix_time_from_system() + KEPT_FOR
	settings.rejoin = {"token": token, "places": places, "until": until}
	settings.save_to_disk()


## The last secret kept, for knocking at the game [param config] joins: empty where it does not
## hold there, or no longer.
static func token_for(config: MatchConfig) -> String:
	var settings := Game.settings
	if settings == null or config == null or config.address.is_empty():
		return ""
	var kept := settings.rejoin
	if float(kept.get("until", 0.0)) < Time.get_unix_time_from_system():
		return ""
	var places: Variant = kept.get("places", PackedStringArray())
	if not (places is PackedStringArray or places is Array):
		return ""
	if "%s:%d" % [config.address, config.port] not in places:
		return ""
	return str(kept.get("token", ""))
