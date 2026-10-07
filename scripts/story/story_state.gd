class_name StoryState
extends RefCounted
## One profile's part in the story, STORY.md 5.2: its clock, what it has found and read, and how
## far past the ending it is, kept in a section of its own in the profile's file. Nothing in it goes
## over the wire, STORY.md 5.3; see [Story] for what it means.

const SECTION := "story"

## Whether the story is on for this profile, STORY.md 5.4. Off, its clock stops and every screen
## shows the casino of the first stage.
var on := true
## The story's clock: seconds of maps played since the license, the match clock's own, STORY.md 5.1.
var seconds := 0.0
## Maps played to the whistle since the license, and the deaths and jokers taken in them, for the
## placeholders of STORY.md 6.
var maps := 0
var deaths := 0
var jokers := 0
## Quick matches played to the whistle since the license, for the first note, STORY.md 7.1.
var quick_matches := 0
## The notes found and the notes read, by number, STORY.md 7.3, each in the order it happened.
var notes := PackedInt32Array()
var notes_read := PackedInt32Array()
## How many maps the next note has been due for without turning up, STORY.md 7.1.
var note_waits := 0
## The day the stamp came down on the Final Hand, empty before, STORY.md 8.4, and the clock then.
var final_hand := ""
var final_seconds := 0.0
## Maps played to the whistle since the Final Hand, STORY.md 6.6.
var shifts := 0
## What the Final Hand's evaluation said, kept for the folder, STORY.md 7.2.
var evaluation: Dictionary = {}


func read(file: ConfigFile) -> void:
	on = bool(file.get_value(SECTION, "on", on))
	seconds = maxf(float(file.get_value(SECTION, "seconds", 0.0)), 0.0)
	maps = maxi(int(file.get_value(SECTION, "maps", 0)), 0)
	deaths = maxi(int(file.get_value(SECTION, "deaths", 0)), 0)
	jokers = maxi(int(file.get_value(SECTION, "jokers", 0)), 0)
	quick_matches = maxi(int(file.get_value(SECTION, "quick_matches", 0)), 0)
	notes = _numbers(file.get_value(SECTION, "notes", PackedInt32Array()))
	notes_read = _numbers(file.get_value(SECTION, "notes_read", PackedInt32Array()))
	note_waits = maxi(int(file.get_value(SECTION, "note_waits", 0)), 0)
	final_hand = str(file.get_value(SECTION, "final_hand", ""))
	final_seconds = maxf(float(file.get_value(SECTION, "final_seconds", 0.0)), 0.0)
	shifts = maxi(int(file.get_value(SECTION, "shifts", 0)), 0)
	var kept: Variant = file.get_value(SECTION, "evaluation", {})
	evaluation = kept if kept is Dictionary else {}


func write(file: ConfigFile) -> void:
	file.set_value(SECTION, "on", on)
	file.set_value(SECTION, "seconds", seconds)
	file.set_value(SECTION, "maps", maps)
	file.set_value(SECTION, "deaths", deaths)
	file.set_value(SECTION, "jokers", jokers)
	file.set_value(SECTION, "quick_matches", quick_matches)
	file.set_value(SECTION, "notes", notes)
	file.set_value(SECTION, "notes_read", notes_read)
	file.set_value(SECTION, "note_waits", note_waits)
	file.set_value(SECTION, "final_hand", final_hand)
	file.set_value(SECTION, "final_seconds", final_seconds)
	file.set_value(SECTION, "shifts", shifts)
	file.set_value(SECTION, "evaluation", evaluation)


## Whether note [param number] has been found.
func has_note(number: int) -> bool:
	return number in notes


## Whether note [param number] has been found and not yet read: new, STORY.md 7.2.
func is_new(number: int) -> bool:
	return has_note(number) and number not in notes_read


## Whether any note found is still new.
func any_new() -> bool:
	for number: int in notes:
		if number not in notes_read:
			return true
	return false


## Whether the stamp has come down on the Final Hand.
func ended() -> bool:
	return not final_hand.is_empty()


## Whole numbers out of whatever the file held, anything else dropped.
static func _numbers(value: Variant) -> PackedInt32Array:
	var kept := PackedInt32Array()
	if value is PackedInt32Array or value is Array:
		for item: Variant in value:
			if item is int or item is float:
				kept.append(int(item))
	return kept
