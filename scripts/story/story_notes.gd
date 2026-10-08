class_name StoryNotes
extends RefCounted
## When Kit's notes turn up on the table, STORY.md 7.1: one at a time and in order, the first in
## the second quick match after the license, the rest spread across their stages, and after the
## ending one every ten minutes of the clock. Whether a due note turns up in a map is a coin toss
## until it has missed two, and then certain; where in the match is drawn inside the clock. The
## numbers are [Story]'s; the note on the floor is [StoryNote], dealt by [NoteDealer].

# --- the notes ---------------------------------------------------------------------------------

## Each note as STORY.md 7.3 has it, by number: its title, the paper it is on, see [NotePage], and
## its lines, each a voice and the words in it. The House's print is [code]print[/code], the
## pamphlet's too small to read [code]small[/code]; Kit's pencil [code]hand[/code], ballpoint
## [code]pen[/code], felt-tip [code]felt[/code], a hand gone shaky [code]shaky[/code], pressed hard
## [code]hard[/code] and in a hurry [code]hurried[/code]; a pencil note in a margin
## [code]margin[/code]; the old book's face [code]old[/code]; a flyer's headline
## [code]display[/code]. A line may carry a third entry, true, for one struck through by hand.
## Written lines are in Kit's hand unless the note names another, [code]hand[/code], see
## [constant NotePage.HANDS]; the blueprint's pencil beside its signature is its
## [code]margin[/code], and its signer [code]signed[/code] over [code]signed_as[/code];
## [code]arrow[/code] runs a pencil arrow from one line to another, [code]crossed[/code] crosses a
## post of the chart through in red pen, and a calendar's [code]slogan[/code] and
## [code]footer[/code] are its print. Placeholders are filled in for the profile reading, see
## [StoryFill].
## What the player keeps in the folder that is not a note, STORY.md 7.2, numbered under the notes
## so it is never one: at its front the invitation that brought them to the tables, its stub torn
## off, 6.1a; and at its back after the ending the House's invitation and its golden ticket, the
## Final Hand's slip and Terms Accepted's card.
const FINAL_SLIP := -1
const TERMS_CARD := -2
const INVITATION := -3
const TICKET := -4
const OPENING := -5
const BACK_TITLES := {
	OPENING: "To the Occupant",
	INVITATION: "The Invitation",
	TICKET: "Admit One",
	FINAL_SLIP: "The Final Hand",
	TERMS_CARD: "Terms Accepted",
}
## Each note's own key, in the story's order, STORY.md 5.2: what a profile keeps of the notes it has
## found and read, so a later version can add a note anywhere in the story without a profile's notes
## coming to mean others. A note's number is its place here, counted from 1. A key, once given, is
## never changed or given to another note.
const KEYS: Array[StringName] = [
	&"opening_night",
	&"table_one",
	&"application",
	&"now_enrolling",
	&"rota",
	&"advisory_capacity",
	&"forklift",
	&"after_the_whistle",
	&"terms_of_participation",
	&"first_edition",
	&"inspection",
	&"traits",
	&"the_mirror",
	&"thank_you",
	&"daily_statement",
	&"the_blueprint",
	&"prediction_quality",
	&"organization_chart",
	&"selected",
	&"your_table",
	&"not_this_time",
	&"duties",
	&"approvals",
	&"profile_complete",
	&"to_whoever_is_next",
	&"the_next_page",
]
## The loose notes, STORY.md 7.3: three outside the story's order, which the loyalty program's
## roads off the books pay, GAME.md 8.9. Kept by keys of their own, never in [constant KEYS], and
## numbered past the story's notes, so none of them is ever the story's next note; due once the
## bet that pays it is won, see [method loose_due], and dealt only in a map with no note of the
## story due, see [method to_deal].
const LOOSE_FROM := 101
const LOOSE_KEYS: Array[StringName] = [&"member_no", &"program_design", &"back_roads"]
const NOTES := {
	LOOSE_FROM:
	{
		"title": "Member No. 0000 0001",
		"paper": &"half_card",
		"lines":
		[
			[
				&"hand",
				(
					"They sent me one too. Number one, naturally. I cut it in half and posted it back"
					+ " to them."
				),
			],
			[
				&"hand",
				"The next week a new one came, with a letter thanking me for my loyalty. —K."
			],
		],
	},
	LOOSE_FROM + 1:
	{
		"title": "Program design",
		"paper": &"memo",
		"lines":
		[
			[&"print", "HOUSE OPERATIONS · LOYALTY PROGRAM · DESIGN NOTE, REVISION 9"],
			[&"print", "EVERY MEMBER CAN SEE THE NEXT REWARD."],
			[&"print", "EVERY NEXT REWARD IS A LITTLE FURTHER AWAY."],
			[&"print", "A MEMBER WHO CAN SEE THE NEXT REWARD DOES NOT STOP."],
			[&"print", "LAPS ......................................... UNLIMITED"],
			[&"print", "EXIT ......................................... NOT APPLICABLE"],
		],
	},
	LOOSE_FROM + 2:
	{
		"title": "Back roads",
		"paper": &"graph_torn",
		"lines":
		[
			[
				&"hand",
				(
					"All their roads go to the roundabout. That's what it's for. Mine don't go"
					+ " anywhere, and that's what mine are for."
				),
			],
			[&"hand", "Go round theirs as long as you like. Just know you can stop. —K."],
		],
	},
	1:
	{
		"title": "Opening night",
		"paper": &"receipt",
		"lines":
		[
			[&"print", "JACKPOT JUNCTION · TABLE 0001"],
			[&"print", "OPENING NIGHT"],
			[&"print", "CHIPS ISSUED ................ 4,000"],
			[&"print", "DRIVERS ........................ 12"],
			[&"print", "STAFF ON DUTY .................. 31"],
			[&"print", "THANK YOU FOR PLAYING!"],
		],
	},
	2:
	{
		"title": "Table one",
		"paper": &"graph",
		"lines":
		[
			[
				&"hand",
				(
					"Table one is done. Felt off the old pool hall on Ninth, karts out of my own"
					+ " scrap. Some kids came to watch me fit the Junction and one asked if this"
					+ " was a real job. Told them it's the best job in town. It's the only one"
					+ " left, but still. —K."
				),
			],
		],
	},
	3:
	{
		"title": "Application",
		"hand": &"driver",
		"paper": &"form",
		"lines":
		[
			[&"print", "DEPT. OF KARTS · APPLICATION FOR A CLASS K LICENSE"],
			[&"print", "PREVIOUS OCCUPATION ________"],
			[&"small", "(If none, write NONE. Most applicants write NONE.)"],
			[&"hand", "Yard. Forklift. 11 years."],
			[&"print", "REASON FOR APPLYING ________"],
			[&"hand", "The forklift drives itself now."],
			[&"print", "FOR OFFICE USE: SUITABLE. ALL APPLICANTS ARE SUITABLE."],
		],
	},
	4:
	{
		"title": "Now enrolling",
		"paper": &"flyer",
		"lines":
		[
			[&"display", "NOW ENROLLING"],
			[&"print", "Earn your very own living!"],
			[&"print", "No experience required."],
			[&"print", "Why wait for a job when the tables are open all night?"],
			[&"small", "JACKPOT JUNCTION · DEPT. OF KARTS · LICENSED ON EVERY TABLE"],
		],
	},
	5:
	{
		"title": "Rota",
		"paper": &"sheet",
		"lines":
		[
			[&"print", "TABLE 0001 · STAFF ON DUTY"],
			[&"print", "WEEK 1 ......... 31"],
			[&"print", "WEEK 9 ......... 18"],
			[&"print", "WEEK 23 ......... 7"],
			[&"print", "WEEK 40 ......... 2"],
			[&"print", "WEEK 41 ......... 0   AUTOMATED"],
			[&"print", "NO ACTION REQUIRED."],
		],
	},
	6:
	{
		"title": "Advisory capacity",
		"paper": &"graph",
		"lines":
		[
			[
				&"hand",
				(
					"The tables print themselves now, felt and all, faster than I ever built"
					+ " one. They kept me on in an advisory capacity. Nobody has asked me"
					+ " anything since. I still come in. The lamp's on a timer. —K."
				),
			],
		],
	},
	7:
	{
		"title": "Forklift",
		"hand": &"driver",
		"paper": &"slip",
		"lines":
		[
			[
				&"pen",
				(
					"eleven years i drove a real forklift in a real yard. now i drive a toy"
					+ " around a picture of the same yard and the House pays better. my hard hat"
					+ " is still hanging out back. nobody's moved it"
				),
			],
		],
	},
	8:
	{
		"title": "After the whistle",
		"hand": &"stranger",
		"paper": &"napkin",
		"lines":
		[
			[
				&"hand",
				(
					"stayed after the whistle once to watch the crowd go home. they didn't. the"
					+ " lights went down and they just stood there, all of them, facing the"
					+ " table. i left. i don't think they noticed. i don't think they notice"
					+ " anything"
				),
			],
		],
	},
	9:
	{
		"title": "Terms of participation",
		"paper": &"pamphlet",
		"lines":
		[
			[&"small", "JACKPOT JUNCTION · TERMS OF PARTICIPATION (EXTRACT)"],
			[&"small", "1. TAKING A SEAT ACCEPTS THESE TERMS."],
			[&"small", "2. TAKING A JOKER ACCEPTS FURTHER TERMS."],
			[&"small", "3. COMING BACK AFTER A LOSS ACCEPTS ALL TERMS AGAIN."],
			[&"small", "4. THESE TERMS NEED NOT BE READ TO BE ACCEPTED."],
			[&"small", "5. THE TERMS MAY CHANGE AT ANY TIME. PLAYING ON ACCEPTS THE CHANGE."],
			[&"small", "THE PARTICIPANT HAS ACCEPTED THESE TERMS {accepted} TIMES."],
			[&"small", "THANK YOU FOR PARTICIPATING."],
			[&"margin", "Nobody reads it. That's what clause 4 is for. —K."],
		],
		# Kit's pencil under the print, with an arrow from it up to clause 4.
		"arrow": [8, 4],
	},
	10:
	{
		"title": "First edition",
		"paper": &"old_page",
		"lines":
		[
			[&"old", "THE HIGHWAY CODE OF THE JUNCTION · FIRST EDITION"],
			[&"old", "§ 1.1  No table shall open without human oversight."],
			[&"old", "§ 1.2  The House shall not oversee itself."],
			[
				&"margin",
				(
					"Still in the 212th, word for word. Every other page has changed. Nobody can"
					+ " tell me why. —K."
				),
			],
		],
	},
	11:
	{
		"title": "Inspection",
		"paper": &"clipboard",
		"lines":
		[
			[&"print", "DEPT. OF KARTS · DRIVING TEST · INSPECTION"],
			[&"print", "INSPECTOR ........... No. 4 (automated)"],
			[&"print", "LEARNER ............. Drove. Steered. Braked. Drifted."],
			[&"print", "LEARNER WROTE NOTHING DOWN."],
			[&"print", "INSPECTOR WROTE EVERYTHING DOWN."],
			[&"print", "FINDINGS ............ Nothing to object to."],
		],
	},
	12:
	{
		"title": "Traits",
		"paper": &"memo",
		"lines":
		[
			[&"print", "HOUSE MEMO · PARTICIPANT TRAITS, CURRENT"],
			[&"print", "BALANCED 40 · GREEDY 15 · CAUTIOUS 15 · HUNTER 15 · BUMPER 10 · GRAZER 5"],
			[&"print", "UNCLASSIFIED: UNDER 1"],
			[&"print", "MODELS ARE DEALT TO TABLES TO MATCH, AND TO TEST:"],
			[&"print", "A HUNTER WHERE A RESPONSE UNDER PRESSURE IS WANTED,"],
			[&"print", "A GREEDY ONE WHERE A RESPONSE TO TEMPTATION IS WANTED."],
			[&"print", "EVERY PARTICIPANT IS CLASSIFIED AFTER EVERY TABLE. PROFILES ARE UPDATED."],
			[&"print", "UNCLASSIFIED PARTICIPANTS ARE OF INTEREST."],
		],
	},
	13:
	{
		"title": "The mirror",
		"paper": &"graph",
		"lines":
		[
			[
				&"hard",
				(
					"Worked out what the bots are. They're us. Every one is somebody who plays"
					+ " here, averaged. There's a Hunter that brakes exactly the way I brake. So"
					+ " I stopped braking like that. Next day, so had it. —K."
				),
			],
		],
	},
	14:
	{
		"title": "Thank you",
		"hand": &"stranger",
		"paper": &"envelope",
		"lines":
		[
			[
				&"felt",
				(
					"started driving stupid on purpose. braking on straights, shooting walls,"
					+ " sitting in the jackpot with nobody near. the bots couldn't follow it."
					+ " next day the House sent me a letter. it said THANK YOU. for what??"
				),
			],
		],
	},
	15:
	{
		"title": "Daily statement",
		"paper": &"roll",
		"lines":
		[
			[&"print", "HOUSE OPERATIONS · DAILY STATEMENT"],
			[&"print", "TABLES OPEN ............................ 1,204,388"],
			[&"print", "PARTICIPANTS ........................... 9,811,450"],
			[&"print", "CHIPS LEFT ON FLOORS, RETURNED ......... 100%"],
			[&"print", "ECONOMIC ACTIVITY ...................... WITHIN TARGET"],
			[&"print", "SOCIAL STABILITY ....................... WITHIN TARGET"],
			[&"print", "PREDICTION QUALITY ..................... BELOW TARGET"],
			[&"print", "HUMAN OVERSIGHT ........................ 0"],
			[&"print", "STATUS ................................. NORMAL"],
		],
	},
	16:
	{
		"title": "The blueprint",
		"paper": &"blueprint",
		"margin": "People signed this. —K.",
		"signed": "E. Halloran",
		"signed_as": "MINISTER OF KARTS",
		"lines":
		[
			[&"print", "DRAWING 1 OF 1"],
			[&"print", "PROJECT ....... JACKPOT JUNCTION"],
			[
				&"print",
				"PURPOSE ....... SOMEWHERE FOR PEOPLE TO GO WHEN THEY ARE NO LONGER NEEDED,"
			],
			[&"print", "AND A REASON TO KEEP GOING ROUND."],
			[&"print", "APPROVED ......"],
		],
	},
	17:
	{
		"title": "Prediction quality",
		"paper": &"memo",
		"stamp": "INTERNAL CIRCULATION",
		"lines":
		[
			[&"print", "HOUSE MEMO · PREDICTION QUALITY"],
			[&"print", "MODELS TRAINED ON MODELS ARE CONVERGING."],
			[&"print", "EVERY HUNTER IS BECOMING THE SAME HUNTER."],
			[&"print", "PREDICTIONS: MORE CONFIDENT. LESS CORRECT."],
			[&"print", "REMEDY: ONE (1) HUMAN, UNPREDICTABLE, IN THE LOOP."],
			[&"print", "SEE HIGHWAY CODE § 1.1. THE RULE WAS RIGHT."],
		],
	},
	18:
	{
		"title": "Organization chart",
		"paper": &"chart",
		# Crossed through in red pen.
		"crossed": "MINISTER OF KARTS",
		"lines":
		[
			[&"print", "THE HOUSE"],
			[&"print", "MINISTER OF KARTS (vacant)"],
			[&"print", "CHIEF EXAMINER (automated)"],
			[&"print", "INSPECTORS 1 TO 4 (automated) · EXAMINERS (automated)"],
			[&"print", "HUMAN OVERSIGHT, § 1.1 ........ vacant. Candidate search in progress."],
		],
	},
	19:
	{
		"title": "Selected",
		"paper": &"graph",
		"lines":
		[
			[
				&"shaky",
				(
					'They told me I\'d been selected. I asked what for. "A position has opened."'
					+ " I asked whose. They said it doesn't matter, it's mine now. I'm leaving my"
					+ " tools where they are. Somebody turn the calendar over. —K."
				),
			],
		],
	},
	20:
	{
		"title": "Your table",
		"paper": &"letter",
		"lines":
		[
			[&"print", "DEAR {name} ({license}),"],
			[&"print", "THANK YOU FOR YOUR CONTINUED PARTICIPATION."],
			[&"print", "YOUR TABLE IS BEING PREPARED."],
			[&"print", "PLEASE DO NOT CHANGE ANYTHING ABOUT THE WAY YOU PLAY."],
			[&"print", "THERE IS NO NEED TO PREPARE."],
			[&"print", "THE HOUSE"],
		],
	},
	21:
	{
		"title": "Not this time",
		"paper": &"strip",
		"lines": [[&"hurried", "Don't stamp it! Don't accept their terms. Not this time. —K."]],
	},
	22:
	{
		"title": "Duties",
		"paper": &"card",
		"lines":
		[
			[&"print", "HOUSE OPERATOR · DUTIES"],
			[&"print", "1. BE HUMAN."],
			[&"print", "2. BE UNPREDICTABLE."],
			[&"print", "3. APPROVE WHERE INDICATED. THE HOUSE WILL INDICATE."],
			[&"print", "THERE ARE NO FURTHER DUTIES."],
		],
	},
	23:
	{
		"title": "Approvals",
		"paper": &"roll",
		"lines":
		[
			[&"print", "DECISIONS APPROVED BY HUMAN OVERSIGHT TODAY ..... 4,118,920,113"],
			[&"print", "AVERAGE TIME PER APPROVAL ....................... 0.0000 S"],
			[&"print", "OPERATOR {license}: THANK YOU."],
			[&"print", "END OF REPORT"],
		],
	},
	24:
	{
		"title": "Profile complete",
		"paper": &"sheet",
		"lines":
		[
			[&"print", "HOUSE OPERATIONS · STAFF RECORD"],
			[&"print", "OPERATOR ............................ JJ-000001"],
			[&"print", "PREDICTION ACCURACY ................. 100%", true],
			[&"print", "PROFILE ............................. COMPLETE"],
			[&"print", "SEAT ................................ RELEASED"],
			[&"print", "THE HOUSE THANKS THE OPERATOR FOR THEIR SERVICE."],
		],
	},
	25:
	{
		"title": "To whoever is next",
		"paper": &"graph_torn",
		"lines":
		[
			[
				&"hand",
				(
					"If you're reading this, you're in the chair now. It isn't bad. Nothing"
					+ " happens. Things get decided and a name goes on them. I tried not"
					+ " approving once. That was noted, and approved."
				),
			],
			[
				&"hand",
				(
					"It learns you a choice at a time. Stay strange as long as you can. When it"
					+ " can guess you, it starts looking for the next one. —K."
				),
			],
		],
	},
	26:
	{
		"title": "The next page",
		"paper": &"calendar",
		# The House's own wall calendar: the month's picture, and the print along its foot.
		"slogan": "A FRESH MONTH. A FRESH START.",
		"footer": "THE HOUSE  ·  TABLE CALENDAR",
		"lines": [[&"hand", "Turned over at last. Thanks. —K."]],
	},
}
## What is on the back of each note, STORY.md 7.3, for a note turned over, see [NoteView]; a note
## not here is bare paper on the back. [code]lines[/code] are written as a note's are, see
## [constant NOTES]; [code]through[/code] shows the front backward, faint, as ink and dents do;
## [code]band[/code] is a till roll's printed band, [code]window[/code] an envelope's,
## [code]seal[/code] the House's, [code]box[/code] a stamped box round the lines, [code]stamp[/code]
## a word stamped, [code]sketch[/code] a drawing in pencil, [code]at[/code] how far down the lines
## start, [code]tilt[/code] how far they are turned about their middle; [code]paper[/code] and
## [code]color[/code] are the back's own where it is not the front's.
const BACKS := {
	1:
	{
		"band": true,
		"lines":
		[
			[&"print", "JACKPOT JUNCTION · KEEP THIS RECEIPT"],
			[&"small", "NO RECEIPT, NO PAYOUT"],
		],
	},
	2:
	{
		"sketch": &"junction",
		"lines": [[&"hand", "Fitted by hand. The next ones won't be. —K."]],
	},
	3:
	{
		"lines":
		[
			[&"print", "NOTES FOR APPLICANTS"],
			[&"small", "1. WRITE CLEARLY."],
			[&"small", "2. PREVIOUS OCCUPATIONS ARE KEPT FOR STATISTICAL PURPOSES."],
			[&"small", "3. YOU WILL BE NOTIFIED."],
			[&"small", "4. THERE IS NO NEED TO WAIT BY THE DOOR."],
		],
	},
	4: {"through": true, "color": Color(0.93, 0.93, 0.9)},
	7:
	{
		"lines":
		[
			[&"print", "PAYOUT SLIP · TABLE ONE"],
			[&"print", "PLACE .......... 1ST"],
			[&"print", "BANKED .......... 1,240 CHIPS"],
		],
		"stamp": "PAID",
	},
	9:
	{
		"lines":
		[
			[&"small", "14.2  PARTICIPATION CONSTITUTES ACCEPTANCE."],
			[&"small", "14.3  ACCEPTANCE CONSTITUTES PARTICIPATION."],
			[&"small", "14.4  SEE 14.2."],
		],
	},
	10:
	{
		"lines":
		[
			[&"old", "§ 0.1  These rules are written by people, for the tables."],
			[&"old", "§ 0.2  Where they are wrong, people shall change them."],
		],
	},
	13:
	{
		"through": true,
		"tilt": -0.15,
		"at": 0.72,
		"lines": [[&"hand", "Changed it again. It caught up by lunch. —K."]],
	},
	14:
	{
		"window": true,
		"lines":
		[
			[&"print", "DEPT. OF KARTS"],
			[&"print", "TO THE OCCUPANT"],
			[&"small", "POSTAGE PAID BY THE HOUSE"],
		],
	},
	16:
	{
		"color": Color(0.9, 0.92, 0.95),
		"at": 0.42,
		"box": true,
		"lines":
		[
			[&"print", "JACKPOT JUNCTION · DRAWING 1 OF 1"],
			[&"print", "MASTER COPY · DO NOT REMOVE"],
		],
	},
	19: {"lines": [[&"hand", "Left the lamp on. —K."]]},
	20: {"through": true},
	21: {"lines": [[&"print", "§ 1.1  No table shall open without human oversight."]]},
	22: {"seal": true},
	25: {"lines": [[&"hand", "P.S. Brake on a straight now and then. It hates that. —K."]]},
}

# --- the schedule ---------------------------------------------------------------------------------


## The next note [param story] has to find, in order, or 0 once it has them all.
static func next_of(story: StoryState) -> int:
	for number: int in range(1, Story.NOTE_COUNT + 1):
		if not story.has_note(number):
			return number
	return 0


## The note due for [param profile] in a map now, or 0 for none: never before the license or with
## the story off; the first from the profile's second map, a quick match's or a Grand Prix's; the
## Final Hand's only at the Final Hand until the ending has passed it by; the rest once the clock
## reaches them.
static func due(profile: Profile) -> int:
	if profile == null or not Story.licensed(profile) or not profile.story.on:
		return 0
	var story := profile.story
	var number := next_of(story)
	if number == 0:
		return 0
	if number == 1:
		return number if story.maps >= Story.FIRST_NOTE_MAP - 1 else 0
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


## The loose note due for [param profile], STORY.md 7.3, or 0 for none: with the story on, the
## first whose bet off the books has been won, in the order they were won, and not found yet.
static func loose_due(profile: Profile) -> int:
	if profile == null or not profile.story.on:
		return 0
	for id: String in profile.loyalty.won:
		var landmark := Loyalty.map().landmark(StringName(id))
		if landmark == null or landmark.note == &"":
			continue
		var number := number_of(landmark.note)
		if is_loose(number) and not profile.story.has_note(number):
			return number
	return 0


## The note to deal for [param profile] in a map now: the story's due, or, with none due, a loose
## one due, never in its place; 0 for none.
static func to_deal(profile: Profile) -> int:
	var number := due(profile)
	return number if number > 0 else loose_due(profile)


## Whether note [param number] is a loose one, outside the story's order.
static func is_loose(number: int) -> bool:
	return number >= LOOSE_FROM and number < LOOSE_FROM + LOOSE_KEYS.size()


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


## Note [param number]'s key, see [constant KEYS] and [constant LOOSE_KEYS]; empty for no note.
static func key_of(number: int) -> StringName:
	if is_loose(number):
		return LOOSE_KEYS[number - LOOSE_FROM]
	return KEYS[number - 1] if number >= 1 and number <= KEYS.size() else &""


## The note with [param key], see [constant KEYS] and [constant LOOSE_KEYS]; 0 for a key this
## version does not know.
static func number_of(key: StringName) -> int:
	var loose := LOOSE_KEYS.find(key)
	if loose >= 0:
		return LOOSE_FROM + loose
	return KEYS.find(key) + 1


## What is on the back of note [param number], see [constant BACKS]: nothing for bare paper.
static func back_of(number: int) -> Dictionary:
	return BACKS.get(number, {})


## Note [param number]'s title, as its page is headed, or the title of a page at the back.
static func title_of(number: int) -> String:
	if BACK_TITLES.has(number):
		return str(BACK_TITLES[number])
	return str(NOTES.get(number, {}).get("title", ""))
