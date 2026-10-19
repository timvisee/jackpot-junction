class_name KartOwner
extends RefCounted
## Whose kart a tab of the kart dialog dresses, GAME.md 4.4: a seat at this machine, in a room or
## not, or a profile kept on it that nobody is playing as. What it is called, what its kart wears,
## its color and its plate are read and kept the way the rest of the game keeps them, the seat's in
## the settings and a profile's in its own file; in a room the seat's kart wears a change at once,
## here and on every other screen, the way the lobby's stalls and the pause menu's switch put it on.
## What a piece is worn in and whether it may be worn at all is the loyalty program's, GAME.md 8.9:
## the seat's profile's, or for a guest the profile playing's.

## How a seat's tab is headed, and a profile's that nobody plays as.
const SEAT := "Seat %d"
const PROFILE := "Profile"

## The seat at this machine, from 0, or -1 for a profile nobody here plays as.
var seat := -1
## Whose program says what may be worn and whose card back it is: the seat's own profile, the
## profile playing for a guest, or the profile itself.
var profile: Profile
## In a room: its slot, and the room, for the kart to wear what is changed at once.
var slot: PlayerSlot
var match_node: Match


## The owner of [param seat] at this machine, out of any room.
static func for_seat(seat_at: int) -> KartOwner:
	var owner := KartOwner.new()
	owner.seat = seat_at
	owner.profile = _profile_of_seat(seat_at)
	return owner


## The owner of [param in_slot] in [param room], a seat at this machine, or null for anybody else's.
static func for_slot(room: Match, in_slot: PlayerSlot) -> KartOwner:
	var player := player_here(room, in_slot)
	if player == null or player.seat < 0:
		return null
	var owner := for_seat(player.seat)
	owner.slot = in_slot
	owner.match_node = room
	return owner


## The owner of [param kept], a profile nobody at this machine is playing as right now.
static func for_profile(kept: Profile) -> KartOwner:
	var owner := KartOwner.new()
	owner.profile = kept
	return owner


## Every kart to dress, a tab each, GAME.md 4.4: in [param room] the seats at this machine in it,
## in the order they sat down; out of one the profile playing; and after them every profile kept
## here that none of them is.
static func everybody(room: Match = null) -> Array[KartOwner]:
	var found: Array[KartOwner] = []
	var settings := Game.settings
	if room != null:
		var seated: Array[KartOwner] = []
		for each: PlayerSlot in room.slots:
			var owner := for_slot(room, each)
			if owner != null:
				seated.append(owner)
		seated.sort_custom(func(a: KartOwner, b: KartOwner) -> bool: return a.seat < b.seat)
		found.append_array(seated)
	if found.is_empty():
		found.append(for_seat(0))
	var playing: Array[String] = []
	for owner: KartOwner in found:
		if not owner.is_guest():
			playing.append(owner.profile.id)
	for kept: Profile in settings.profiles():
		if kept.id not in playing:
			found.append(for_profile(kept))
	return found


## The player at this machine who drives [param in_slot] in [param room], or null: the one in the
## seat here, or on a client the one this machine is, see [StyleStalls].
static func player_here(room: Match, in_slot: PlayerSlot) -> PlayerInput:
	if room.puppet:
		if room.local_seats.has(in_slot.index):
			return room.local_seats[in_slot.index]
		return room.local_input if in_slot.index == room.local_slot else null
	return in_slot.input as PlayerInput


static func _profile_of_seat(seat_at: int) -> Profile:
	var settings := Game.settings
	var own := settings.seat_profile(seat_at)
	return own if own != null else settings.profile


## Whether this is a seat with no profile of its own, a guest of the profile playing, GAME.md 3.8:
## it has the profile playing's program and plate, and no card back of its own.
func is_guest() -> bool:
	return seat > 0 and Game.settings.seat_profile(seat) == null


## What its tab says over its name: the seat, or that it is a profile nobody is playing as.
func heading() -> String:
	return SEAT % (seat + 1) if seat >= 0 else PROFILE


## What it is called, as typed, empty for a seat that gave no name.
func given_name() -> String:
	if seat >= 0:
		return Game.settings.seat_name(seat)
	return profile.player_names[0]


## What its tab calls it: its name, or what the room calls it, or the profile's own name.
func display_name() -> String:
	var named := given_name()
	if not named.is_empty():
		return named
	if slot != null:
		return slot.display_name()
	if seat < 0:
		return profile.display_name()
	return SEAT % (seat + 1)


## A name typed for it, cleaned, kept, and in a room its kart's from now on, see [SeatIdentity].
func rename(typed: String) -> void:
	var named := PlayerNames.clean(typed)
	if slot != null and match_node != null:
		SeatIdentity.rename(slot, named)
		return
	if seat >= 0:
		Game.settings.set_seat_name(seat, named)
		Game.settings.save_to_disk()
		return
	profile.player_names[0] = named
	profile.save_to_disk()


## What its kart wears, with the finishes its program has moved each piece up to.
func style() -> KartStyle:
	if slot != null:
		return slot.style.duplicate_style()
	if seat >= 0:
		return KartStyle.from_array(Game.settings.seat_style(seat))
	return KartStyle.from_array(Loyalty.with_finishes(profile, profile.kart_styles[0]))


## [param style] with [param part] of [constant KartStyle.CHOICES] made [param index], in the
## finish its owner has it in.
func trying(style_now: KartStyle, part: int, index: int) -> KartStyle:
	var values := style_now.to_array()
	values.resize(KartStyle.CHOICES.size())
	values[part] = index
	var tried := KartStyle.from_array(values)
	tried.finishes = style_now.finishes.duplicate()
	tried.finishes[part] = finish_of(part, index)
	return tried


## Puts [param index] of [param part] on its kart and keeps it, see [method _put_on]. Nothing for
## a piece it has not won.
func wear(part: int, index: int) -> bool:
	if not owns(part, index):
		return false
	_put_on(trying(style(), part, index).to_array(), part)
	return true


## Puts [param values], a choice of each part, on its kart all at once and keeps them, as
## [method wear] does a piece at a time, each in its finish; a part with a choice it has not won is
## left as it was.
func dress(values: PackedInt32Array) -> void:
	var now := style().to_array()
	now.resize(KartStyle.CHOICES.size())
	for part: int in mini(values.size(), KartStyle.CHOICES.size()):
		if owns(part, values[part]):
			now[part] = values[part]
	var dressed := KartStyle.from_array(now)
	for part: int in KartStyle.CHOICES.size():
		dressed.finishes[part] = finish_of(part, now[part])
	_put_on(dressed.to_array(), 0)


## [param values] on its kart and kept: in a room on the kart at once and said to every screen, as
## a stall does, see [StyleStalls], [param part] being what changed; and its program hears of it,
## for the dress it has worn, GAME.md 8.10.
func _put_on(values: PackedInt32Array, part: int) -> void:
	if slot != null and match_node != null:
		StyleStalls.dress(slot, values)
		StyleStalls.keep(slot)
		var session := SeatIdentity.client_of(slot)
		if session != null:
			var mine := session.seat_at(slot.index)
			session.claims.say_style(values, mine.seat if mine != null else 0)
		elif not match_node.puppet:
			Events.kart_dressed.emit(slot.index, part, values)
	elif seat >= 0:
		Game.settings.set_seat_style(seat, values)
		Game.settings.save_to_disk()
	else:
		profile.kart_styles[0] = values.slice(0, KartStyle.CHOICES.size())
		profile.save_to_disk()
	Achievements.arrive(profile, slot.index if slot != null else -1)


## Whether it may wear [param index] of [param part]: everybody's, or won in its program. The card
## back, past the kart's own parts, as [method card_backs] has it.
func owns(part: int, index: int) -> bool:
	var dress: PackedStringArray = Loyalty.unlocks_of(profile)["dress"]
	if part == KartStyle.CHOICES.size():
		return index == 0 or piece_name(part, index) in dress
	return KartStyle.allowed(part, index, dress)


## The name [param index] of [param part] goes by among the dress won, "hat:Fedora", see
## [method KartStyle.won_name]; the card back's, past the kart's own parts, "card_back:Gilt".
static func piece_name(part: int, index: int) -> String:
	if part == KartStyle.CHOICES.size():
		return "card_back:%s" % CardBack.STYLES[index]
	return KartStyle.won_name(part, index)


## The part and the index of the piece of dress called [param piece], as [method piece_name] names
## it; an index of -1 for one this version does not have.
static func piece_of(piece: String) -> Vector2i:
	var kind := piece.get_slice(":", 0)
	var part := KartStyle.PARTS.find(StringName(kind))
	if kind == "card_back":
		part = KartStyle.CHOICES.size()
	if part < 0:
		return Vector2i(0, -1)
	return Vector2i(part, KartDialog.choices_of(part).find(piece.substr(kind.length() + 1)))


## The pieces it may wear that its program has won, or moved up a finish, since the kart dialog
## last showed them there, GAME.md 4.4a, each as its part and index: never one of everybody's, nor
## a card back for a guest, who has none of its own.
func new_pieces() -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	var dress: PackedStringArray = Loyalty.unlocks_of(profile)["dress"]
	for piece: String in profile.loyalty.dress_fresh:
		var at := piece_of(piece)
		var back := at.x == KartStyle.CHOICES.size()
		if at.y <= 0 or piece not in dress or (back and not has_card_back()):
			continue
		if back or at.y not in KartStyle.EVERYBODY[at.x]:
			found.append(at)
	return found


## The finish [param index] of [param part] is worn in, GAME.md 8.9, 0 for none.
func finish_of(part: int, index: int) -> int:
	if index <= 0 or part >= KartStyle.CHOICES.size():
		return 0
	return Loyalty.finish_of(profile, KartStyle.won_name(part, index))


## Where in the loyalty program [param index] of [param part] is won, the landmark's own name, or
## empty for one everybody has.
static func won_at(part: int, index: int) -> String:
	var piece := piece_name(part, index)
	for each: LoyaltyLandmark in Loyalty.map().landmarks:
		var pays := "%s:%s" % [each.dress_part, each.dress]
		if (each.dress_part != &"" and pays == piece) or piece in each.also:
			return each.title
	return ""


## One of the pieces of [param part] it has won, or everybody has, at random by [param rng], for
## the kart dialog's shuffle.
func any_piece(part: int, rng: RandomNumberGenerator) -> int:
	var won: Array[int] = []
	for index: int in KartDialog.choices_of(part).size():
		if owns(part, index):
			won.append(index)
	return won[rng.randi_range(0, won.size() - 1)] if not won.is_empty() else 0


## A color for it at random by [param rng], of those nobody else in the room is in, another than
## its own where there is one, and its own, or -1 for none yet, where there is not.
func any_color(rng: RandomNumberGenerator) -> int:
	var free: Array[int] = []
	for each: int in Palette.PLAYER_COLORS.size():
		if each != color() and color_free(each):
			free.append(each)
	if free.is_empty():
		return color()
	return free[rng.randi_range(0, free.size() - 1)]


## Its color, as an index into [constant Palette.PLAYER_COLORS]: the room's for a seat in one, its
## favorite otherwise, or -1 for none yet.
func color() -> int:
	if slot != null:
		return slot.color_index
	if seat >= 0:
		return Game.settings.seat_color(seat)
	return profile.colors[0]


## Whether it may take [param wanted]: anything out of a room, and in one only a color nobody else
## in it is in, see [method SeatIdentity.is_free].
func color_free(wanted: int) -> bool:
	if slot == null or match_node == null:
		return true
	return SeatIdentity.is_free(match_node, slot, wanted)


## Who else has [param wanted] in the room, by the name they go by, or empty.
func color_taker(wanted: int) -> String:
	if slot == null or match_node == null:
		return ""
	for other: PlayerSlot in match_node.slots:
		if other != slot and other.color_index == wanted and not other.input is VacantSeat:
			return other.display_name()
	return ""


## Takes [param wanted] as its color and favorite: in a room at once, here and on the host, or
## asked of the host on a client, see [SeatIdentity]. False for one somebody else in it is in.
func recolor(wanted: int) -> bool:
	if wanted < 0 or wanted >= Palette.PLAYER_COLORS.size() or not color_free(wanted):
		return false
	if slot != null and match_node != null:
		var player := player_here(match_node, slot)
		if player != null and player.seat >= 0:
			Game.settings.set_seat_color(player.seat, wanted)
			Game.settings.save_to_disk()
		var session := SeatIdentity.client_of(slot)
		if session != null:
			session.claim_color(wanted, slot.index)
		else:
			SeatIdentity.paint(match_node, slot, wanted)
		return true
	if seat >= 0:
		Game.settings.set_seat_color(seat, wanted)
		Game.settings.save_to_disk()
	else:
		profile.colors[0] = wanted
		profile.save_to_disk()
	return true


## Whether its plate can be changed here: a profile's own, once it has its license, GAME.md 4.4.
## A guest wears the profile playing's, and a learner the L.
func has_plate() -> bool:
	return not is_guest() and not profile.license_number.is_empty()


## What its kart wears on its back: "L" before a license, or the plate.
func plate() -> String:
	return "L" if profile.license_number.is_empty() else profile.license_plate


## Keeps [param typed] as its plate, cleaned, and puts it on every kart at this machine wearing it
## in a room: its own, and a guest's of the profile playing.
func replate(typed: String) -> void:
	if not has_plate():
		return
	var cleaned := LicensePlate.clean(typed)
	if cleaned.is_empty() or cleaned == profile.license_plate:
		return
	profile.license_plate = cleaned
	keep()
	if match_node == null:
		return
	for each: PlayerSlot in match_node.slots:
		var player := player_here(match_node, each)
		if player == null or player.seat < 0 or _profile_of_seat(player.seat) != profile:
			continue
		var session := SeatIdentity.client_of(each)
		if session != null:
			var mine := session.seat_at(each.index)
			session.claims.say_plate(cleaned, mine.seat if mine != null else 0)
		if each.kart != null and is_instance_valid(each.kart):
			KartVisuals.license_plate(each.kart, cleaned)


## Whether it has a card back of its own to choose, GAME.md 8.9: a profile's, never a guest's.
func has_card_back() -> bool:
	return not is_guest()


func card_back() -> int:
	return profile.loyalty.card_back


## Has [param style] of [constant CardBack.STYLES] be its card back, if it has won it.
func turn_back(style_at: int) -> bool:
	if not has_card_back() or not owns(KartStyle.CHOICES.size(), style_at):
		return false
	profile.loyalty.card_back = style_at
	keep()
	Achievements.arrive(profile, slot.index if slot != null else -1)
	return true


## Its profile kept as it is now: the profile playing's and a seat's with the settings, which keep
## the profiles of the seats too, and any other in its own file.
func keep() -> void:
	if profile == Game.settings.profile or seat >= 0:
		Game.settings.save_to_disk()
	else:
		profile.save_to_disk()
