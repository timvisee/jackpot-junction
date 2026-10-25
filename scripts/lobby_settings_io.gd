extends RefCounted
## Reads and writes the lobby's match choices, GAME.md 3.8, in the "lobby" section of the settings
## file. Kept out of [Settings] so that file stays within its length, and loaded at runtime with no
## class name of its own, so it draws no compile-time edge back into Settings.


## Reads every lobby choice from [param file] into [param settings], each falling back to what the
## settings already hold when the file has nothing to say.
static func load_into(settings: Settings, file: ConfigFile) -> void:
	# Kept in minutes until a map could be shorter than one; a file from then is read in minutes.
	settings.match_seconds = file.get_value(
		"lobby", "match_seconds", int(file.get_value("lobby", "match_minutes", 5)) * 60
	)
	settings.target_score = file.get_value("lobby", "target_score", settings.target_score)
	settings.bot_count = file.get_value("lobby", "bot_count", settings.bot_count)
	settings.difficulty = file.get_value("lobby", "difficulty", settings.difficulty)
	settings.item_set = file.get_value("lobby", "item_set", settings.item_set)
	settings.map = file.get_value("lobby", "map", settings.map)
	settings.own_bullets_hurt = file.get_value(
		"lobby", "own_bullets_hurt", settings.own_bullets_hurt
	)
	settings.joker_slots = int(file.get_value("lobby", "joker_slots", settings.joker_slots))
	settings.overtime = file.get_value("lobby", "overtime", settings.overtime)
	settings.catch_up = bool(file.get_value("lobby", "catch_up", settings.catch_up))
	settings.teams = int(file.get_value("lobby", "teams", settings.teams))
	settings.friendly_fire = bool(file.get_value("lobby", "friendly_fire", settings.friendly_fire))
	settings.grand_prix_maps = file.get_value("lobby", "grand_prix_maps", settings.grand_prix_maps)
	settings.grand_prix = file.get_value(
		"lobby", "grand_prix", file.get_value("lobby", "online_grand_prix", settings.grand_prix)
	)
	settings.grand_prix_jokers = file.get_value(
		"lobby", "grand_prix_jokers", settings.grand_prix_jokers
	)
	settings.grand_prix_normal = file.get_value(
		"lobby", "grand_prix_normal", settings.grand_prix_normal
	)
	settings.grand_prix_xl = file.get_value("lobby", "grand_prix_xl", settings.grand_prix_xl)
	settings.grand_prix_tie_breaker = file.get_value(
		"lobby", "grand_prix_tie_breaker", settings.grand_prix_tie_breaker
	)
	settings.small_maps = file.get_value("lobby", "small_maps", settings.small_maps)
	settings.floor_open = bool(file.get_value("lobby", "floor_open", settings.floor_open))
	settings.rules_open = bool(file.get_value("lobby", "rules_open", settings.rules_open))


## Writes every lobby choice from [param settings] into [param file].
static func save_from(settings: Settings, file: ConfigFile) -> void:
	file.set_value("lobby", "match_seconds", settings.match_seconds)
	file.set_value("lobby", "target_score", settings.target_score)
	file.set_value("lobby", "bot_count", settings.bot_count)
	file.set_value("lobby", "difficulty", settings.difficulty)
	file.set_value("lobby", "item_set", settings.item_set)
	file.set_value("lobby", "map", settings.map)
	file.set_value("lobby", "own_bullets_hurt", settings.own_bullets_hurt)
	file.set_value("lobby", "joker_slots", settings.joker_slots)
	file.set_value("lobby", "overtime", settings.overtime)
	file.set_value("lobby", "catch_up", settings.catch_up)
	file.set_value("lobby", "teams", settings.teams)
	file.set_value("lobby", "friendly_fire", settings.friendly_fire)
	file.set_value("lobby", "grand_prix_maps", settings.grand_prix_maps)
	file.set_value("lobby", "grand_prix", settings.grand_prix)
	file.set_value("lobby", "grand_prix_jokers", settings.grand_prix_jokers)
	file.set_value("lobby", "grand_prix_normal", settings.grand_prix_normal)
	file.set_value("lobby", "grand_prix_xl", settings.grand_prix_xl)
	file.set_value("lobby", "grand_prix_tie_breaker", settings.grand_prix_tie_breaker)
	file.set_value("lobby", "small_maps", settings.small_maps)
	file.set_value("lobby", "floor_open", settings.floor_open)
	file.set_value("lobby", "rules_open", settings.rules_open)
