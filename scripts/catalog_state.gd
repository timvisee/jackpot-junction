class_name CatalogState
extends RefCounted
## One profile's part in the catalog of GAME.md 8.8: every joker and every power-up it ever took,
## how many times, and which of them it has not looked at there yet, kept in a section of its own
## in the profile's file. Written by [CatalogRecord]; nothing in it goes over the wire.
##
## Kept by id. An id this version does not know, a joker taken out of the game or one a newer
## version has, is kept as it is and never shown or counted, so no record is lost to a version.

const SECTION := "catalog"

## How many times each joker was taken, by its id.
var jokers: Dictionary[StringName, int] = {}
## How many times each power-up was picked up, by its id.
var items: Dictionary[StringName, int] = {}
## The jokers and power-ups taken for the first time that the catalog has not shown under its
## cursor yet, which wear a NEW tag there.
var fresh := PackedStringArray()


func read(file: ConfigFile) -> void:
	jokers = _counts(file.get_value(SECTION, "jokers", {}))
	items = _counts(file.get_value(SECTION, "items", {}))
	var kept: Variant = file.get_value(SECTION, "fresh", PackedStringArray())
	fresh = (
		PackedStringArray(kept)
		if kept is PackedStringArray or kept is Array
		else PackedStringArray()
	)


func write(file: ConfigFile) -> void:
	file.set_value(SECTION, "jokers", _plain(jokers))
	file.set_value(SECTION, "items", _plain(items))
	file.set_value(SECTION, "fresh", fresh)


## [param id] went into a hand once more. True the first time.
func take_joker(id: StringName) -> bool:
	return _take(jokers, id)


## [param id] was picked up once more. True the first time.
func take_item(id: StringName) -> bool:
	return _take(items, id)


## How many times the joker or power-up [param id] was taken.
func times(id: StringName) -> int:
	return jokers.get(id, items.get(id, 0))


## Whether the joker or power-up [param id] was ever taken.
func found(id: StringName) -> bool:
	return times(id) > 0


## Whether [param id] was taken for the first time since the catalog last showed it.
func is_fresh(id: StringName) -> bool:
	return String(id) in fresh


## The catalog has shown [param id] under its cursor. True if it was fresh until now.
func look_at(id: StringName) -> bool:
	var at := fresh.find(String(id))
	if at < 0:
		return false
	fresh.remove_at(at)
	return true


## How many of [param ids] were ever taken: those this version has, out of all of them.
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
