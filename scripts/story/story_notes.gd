class_name StoryNotes
extends RefCounted
## When Kit's notes turn up on the table, STORY.md 7.1: one at a time and in order, the first in
## the second quick match after the license, the rest spread across their stages, and after the
## ending one every ten minutes of the clock. Whether a due note turns up in a map is a coin toss
## until it has missed two, and then certain; where in the match is drawn inside the clock. The
## numbers are [Story]'s; the note on the floor is [StoryNote], dealt by [NoteDealer].


## The next note [param story] has to find, in order, or 0 once it has them all.
static func next_of(story: StoryState) -> int:
	for number: int in range(1, Story.NOTE_COUNT + 1):
		if not story.has_note(number):
			return number
	return 0


## The note due for [param profile] in a map now, or 0 for none: never before the license or with
## the story off; the first only in a quick match, [param quick], the profile's second; the Final
## Hand's only at the Final Hand until the ending has passed it by; the rest once the clock reaches
## them.
static func due(profile: Profile, quick: bool) -> int:
	if profile == null or not Story.licensed(profile) or not profile.story.on:
		return 0
	var story := profile.story
	var number := next_of(story)
	if number == 0:
		return 0
	if number == 1:
		return number if quick and story.quick_matches >= Story.FIRST_NOTE_MATCH - 1 else 0
	if number == Story.FINAL_HAND_NOTE and not story.ended():
		return 0
	return number if story.seconds >= due_at(number, story) else 0


## Where on [param story]'s clock note [param number] falls due: the i-th of a stage's k notes at
## its start plus i/k of its length, the Final Hand's at the ending if it was missed there, and the
## Operator's every ten minutes after that.
static func due_at(number: int, story: StoryState) -> float:
	if number == Story.FINAL_HAND_NOTE:
		return story.final_seconds
	for stage: int in range(Story.Stage.PLAYER, Story.Stage.OPERATOR):
		var notes := Story.STAGE_NOTES[stage]
		if number < notes.x or number > notes.y:
			continue
		var start := Story.STAGE_STARTS[stage]
		var end := (
			Story.STAGE_STARTS[stage + 1]
			if stage + 1 < Story.STAGE_STARTS.size()
			else Story.FINAL_HAND_AT
		)
		var share := float(number - notes.x) / float(notes.y - notes.x + 1)
		return start + share * (end - start)
	return story.final_seconds + float(number - Story.FINAL_HAND_NOTE) * Story.NOTE_EVERY_AFTER


## Whether a note due for [param story] turns up in this map: an even chance, certain once it has
## been due for two maps without turning up.
static func turns_up(story: StoryState, rng: RandomNumberGenerator) -> bool:
	if story.note_waits >= Story.NOTE_CERTAIN_AFTER:
		return true
	return rng.randf() < Story.NOTE_CHANCE


## When in a match of [param length] seconds on its clock a note turns up: between twenty seconds
## in and a minute before the end, or, in a map too short for that, the middle half of it.
static func moment(length: float, rng: RandomNumberGenerator) -> float:
	var earliest := minf(Story.NOTE_FROM, length * 0.25)
	var latest := length - Story.NOTE_BEFORE_END
	if latest < earliest + 10.0:
		latest = length * 0.75
	return rng.randf_range(earliest, latest)


## Files note [param number] for [param profile], found and not yet read, STORY.md 7.2. The one
## place a note is filed, so whether linked profiles move on through the notes too, STORY.md 13, is
## decided here.
static func file(profile: Profile, number: int) -> void:
	if profile == null or profile.story.has_note(number):
		return
	profile.story.notes.append(number)
	profile.story.note_waits = 0
