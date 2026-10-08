class_name CatalogState
extends RefCounted
## One profile's part in the catalog of GAME.md 8.8: every joker it ever took and every power-up it
## ever used, how many times, and which of them it has not looked at there yet, kept in a section
## of its own in the profile's file. Written by [CatalogRecord]; nothing in it goes over the wire.
##
## Kept by id. An id this version does not know, a joker taken out of the game or one a newer
## version has, is kept as it is and never shown or counted, so no record is lost to a version.

const SECTION := "catalog"

## How many times each joker was taken, by its id.
var jokers: Dictionary[StringName, int] = {}
## How many times each power-up was used, by its id. Kept as "used": 0.14.1 counted power-ups as
## they were picked up, under "items", which is left behind, since picking one up no longer counts.
var items: Dictionary[StringName, int] = {}
## The jokers and power-ups found for the first time that the catalog has not shown under its
## cursor yet, which wear a NEW tag there.
var fresh := PackedStringArray()


func read(file: ConfigFile) -> void:
	jokers = _counts(file.get_value(SECTION, "jokers", {}))
	items = _counts(file.get_value(SECTION, "used", {}))
	var kept: Variant = file.get_value(SECTION, "fresh", PackedStringArray())
	fresh = PackedStringArray()
	if kept is PackedStringArray or kept is Array:
		# Only what is found can be new: a power-up 0.14.1 counted as picked up is not, yet.
		for id: Variant in kept:
			if found(StringName(str(id))) and str(id) not in fresh:
				fresh.append(str(id))


func write(file: ConfigFile) -> void:
	file.set_value(SECTION, "jokers", _plain(jokers))
	file.set_value(SECTION, "used", _plain(items))
	file.set_value(SECTION, "fresh", fresh)


## [param id] went into a hand once more. True the first time.
func take_joker(id: StringName) -> bool:
	return _take(jokers, id)


## [param id] was used once more. True the first time.
func use_item(id: StringName) -> bool:
	return _take(items, id)


## How many times the joker [param id] was taken, or the power-up [param id] used.
func times(id: StringName) -> int:
	return jokers.get(id, items.get(id, 0))


## Whether the joker [param id] was ever taken, or the power-up [param id] ever used.
func found(id: StringName) -> bool:
	return times(id) > 0


## Whether [param id] was found for the first time since the catalog last showed it.
func is_fresh(id: StringName) -> bool:
	return String(id) in fresh


## The catalog has shown [param id] under its cursor. True if it was fresh until now.
func look_at(id: StringName) -> bool:
	var at := fresh.find(String(id))
	if at < 0:
		return false
	fresh.remove_at(at)
	return true


## How many of [param ids] were ever found: those this version has, out of all of them.
func found_of(ids: Array[StringName]) -> int:
	var count := 0
	for id: StringName in ids:
		if found(id):
			count += 1
	return count


func _take(counts: Dictionary[StringName, int], id: StringName) -> bool:
	if id == &"":
		return false
	var first := not counts.has(id)
	counts[id] = counts.get(id, 0) + 1
	if first and String(id) not in fresh:
		fresh.append(String(id))
	return first


## The counts out of whatever the file held: ids with a whole number above nothing.
static func _counts(value: Variant) -> Dictionary[StringName, int]:
	var counts: Dictionary[StringName, int] = {}
	if not value is Dictionary:
		return counts
	for key: Variant in value:
		var count: Variant = value[key]
		if (key is String or key is StringName) and (count is int or count is float):
			if int(count) > 0:
				counts[StringName(key)] = int(count)
	return counts


## [param counts] as the file keeps them: keys as plain strings, so a file reads the same whatever
## wrote it.
static func _plain(counts: Dictionary[StringName, int]) -> Dictionary:
	var plain := {}
	for id: StringName in counts:
		plain[String(id)] = counts[id]
	return plain
