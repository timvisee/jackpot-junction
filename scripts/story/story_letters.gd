class_name StoryLetters
extends RefCounted
## The House's letters, STORY.md 6.11: one at the title as stages 2, 3 and 4 begin, and the
## Operator's duties at the first visit after the ending, each shown as the program's welcome is,
## see [HouseMail], and then filed in Kit's folder under a title of Kit's in pencil. A profile keeps
## the keys of the letters it has been shown; one that reached a stage without being shown the
## letters before it, a profile from before they were written, is shown the last and has the rest
## filed as they are. Their words are [constant StoryLines.HOUSE_LETTERS].

## The letters in the order they come, each by its key.
const KEYS: Array[StringName] = [&"statement", &"profile_notice", &"your_table", &"duties"]
## Each letter's page in the folder, numbered under the notes as what the folder keeps that is not
## a note is, see [constant StoryNotes.BACK_TITLES].
const PAGES := {
	&"statement": -7,
	&"profile_notice": -8,
	&"your_table": -9,
	&"duties": -10,
}

## For a test, or a debug build's `++ --story-letter`: the next letter owed shown whether or not it
## is a visit to the title it would come on.
static var again := false


## The stage that brings letter [param key].
static func stage_of(key: StringName) -> int:
	return int(StoryLines.HOUSE_LETTERS[key]["stage"])


## The letters [param of] has been brought and not been shown, in order: with its story on and
## licensed, those of every stage it has reached.
static func owed(of: Profile) -> Array[StringName]:
	var still: Array[StringName] = []
	if of == null or not of.story.on or not Story.licensed(of):
		return still
	var stage := Story.stage_of(of)
	for key: StringName in KEYS:
		if stage_of(key) <= stage and String(key) not in of.story.letters:
			still.append(key)
	return still


## The letter to show [param of] at the title now, or empty for none: the last it is owed, and
## never in a run nobody watches.
static func due(of: Profile) -> StringName:
	var still := owed(of)
	if still.is_empty():
		return &""
	if not again and (Game.is_headless() or Game.is_scripted()):
		return &""
	return still[still.size() - 1]


## Every letter [param of] is owed filed in its folder, the one just shown among them.
static func file_owed(of: Profile) -> void:
	for key: StringName in owed(of):
		of.story.letters.append(String(key))


## The House's letters [param story] has filed put among [param found], its notes in order, each
## before the first note of the stage it came at, STORY.md 6.11.
static func file_among(found: PackedInt32Array, story: StoryState) -> void:
	for key: StringName in KEYS:
		if String(key) not in story.letters:
			continue
		var first := Story.STAGE_NOTES[stage_of(key)].x
		var at := found.size()
		for i: int in found.size():
			if found[i] >= first:
				at = i
				break
		found.insert(at, int(PAGES[key]))


## Whether page [param number] of the folder is one of the House's letters.
static func is_letter(number: int) -> bool:
	return number in PAGES.values()


## The letter on page [param number] of the folder, or empty.
static func key_of(number: int) -> StringName:
	for key: StringName in PAGES:
		if int(PAGES[key]) == number:
			return key
	return &""


## Kit's title over letter [param key]'s page in the folder.
static func title_of(key: StringName) -> String:
	return str(StoryLines.HOUSE_LETTERS[key]["title"])


## What the House fills in letter [param key] with for [param of], beyond what [StoryFill] knows:
## the class its whole record comes closest to, how much of it that explains, and the class's line.
static func table_for(of: Profile) -> Dictionary:
	var classed := StorySlip.classify_record(of)
	return {
		"trait": classed[0],
		"share": str(classed[1]),
		"class_line": str(StoryLines.CLASS_LINES.get(classed[0], "")),
	}


## Letter [param key]'s lines for [param of], filled in, each a label and a value or a line alone.
static func lines_for(key: StringName, of: Profile) -> Array[PackedStringArray]:
	var table := table_for(of) if of != null else {}
	var out: Array[PackedStringArray] = []
	for line: Array in StoryLines.HOUSE_LETTERS[key]["lines"]:
		var filled := PackedStringArray()
		for part: String in line:
			filled.append(StoryFill.fill(part, of, table) if of != null else part)
		out.append(filled)
	return out


## Letter [param key] as a screen reader reads it out, see [ScreenReader]: its heading and its
## lines in order, filled in for [param of].
static func read_out(key: StringName, of: Profile) -> String:
	var said := PackedStringArray()
	var heading := str(StoryLines.HOUSE_LETTERS[key].get("heading", ""))
	if not heading.is_empty():
		said.append(ScreenReader.spoken(heading))
	for line: PackedStringArray in lines_for(key, of):
		var words := " ".join(line).strip_edges()
		if not words.is_empty():
			said.append(ScreenReader.spoken(words))
	return ScreenReader.line(said)
