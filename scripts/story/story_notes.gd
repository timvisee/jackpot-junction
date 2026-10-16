class_name StoryNotes
extends RefCounted
## When Kit's notes turn up on the table, STORY.md 7.1: one at a time and in order, the first early
## in the first map after the license, the rest spread across their stages, and after the ending one
## every ten minutes of the clock. Before the ending a due note turns up in the first map it is due
## for; after it, whether it does is a coin toss until it has missed two, and then certain. Where in
## the match is drawn inside the clock. The numbers are [Story]'s; the note on the floor is
## [StoryNote], dealt by [NoteDealer].

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
## off, 6.1a, and after it the loyalty program's letter, its card torn off, 6.6b; and at its back
## after the ending the House's invitation and its golden ticket, the Final Hand's slip and Terms
## Accepted's card; and at the back from the first time it was torn off, the House's page torn off
## the Final Hand's slip, STATUS blank, 8.4. The House's letters are -7 to -10, see [StoryLetters].
const FINAL_SLIP := -1
const TERMS_CARD := -2
const INVITATION := -3
const TICKET := -4
const OPENING := -5
const WELCOME_LETTER := -6
const TORN_SLIP := -11
const BACK_TITLES := {
	OPENING: "To You",
	WELCOME_LETTER: "Members return",
	INVITATION: "The Invitation",
	TICKET: "Admit One",
	FINAL_SLIP: "The Final Hand",
	TERMS_CARD: "Terms Accepted",
	TORN_SLIP: "Torn off",
}
## Each note's own key, in the story's order, STORY.md 5.2: what a profile keeps of the notes it has
## found and read, so a later version can add a note anywhere in the story without a profile's notes
## coming to mean others. A note's number is its place here, counted from 1. A key, once given, is
## never changed or given to another note; one taken out of the story is kept out of here, and a
## profile that found it keeps the key as it keeps any it does not know, see [StoryState].
const KEYS: Array[StringName] = [
	&"stub",
	&"inspection",
	&"table_one",
	&"opening_night",
	&"rota",
	&"application",
	&"advisory_capacity",
	&"forklift",
	&"terms_of_participation",
	&"blanks",
	&"after_the_whistle",
	&"first_edition",
	&"traits",
	&"the_mirror",
	&"thank_you",
	&"daily_statement",
	&"the_blueprint",
	&"prediction_quality",
	&"organization_chart",
	&"selected",
	&"not_this_time",
	&"profile_complete",
	&"to_whoever_is_next",
	&"the_next_page",
]
## The story's order before it was retold, PLAN.md M20: a profile kept from before notes were kept
## by key holds their numbers in this order, see [method StoryState._found].
const KEYS_BEFORE: Array[StringName] = [
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
## roads off the books pay, GAME.md 8.9, and Kit's note for a refusal at the Final Hand. Kept by
## keys of their own, never in [constant KEYS], and numbered past the story's notes, so none of
## them is ever the story's next note; due once the bet that pays it is won, or the House's page is
## torn off, see [method loose_due], and dealt only in a map with no note of the story due, see
## [method to_deal].
const LOOSE_FROM := 101
## A line struck through by hand, as a screen reader is told it, see [method read_out].
const STRUCK := "Crossed out: %s"
const LOOSE_KEYS: Array[StringName] = [
	&"member_no", &"program_design", &"back_roads", &"not_stamped"
]
## Kit's note for a refusal, STORY.md 7.3, the last of the loose ones.
const NOT_STAMPED := LOOSE_FROM + 3
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
	NOT_STAMPED:
	{
		"title": "Not stamped",
		"paper": &"graph",
		"lines":
		[
			[
				&"hand",
				(
					"You didn't stamp it. Neither did I, the first time. They'll ask again, every"
					+ " time you sit down, and they'll be very polite about it. Whatever you answer,"
					+ " make it yours. —K."
				),
			],
		],
	},
	1:
	{
		"title": "Stub",
		"paper": &"stub",
		# Drawn as the invitation's stub is, see [method NotePage._draw_stub]; the lines are what a
		# screen reader reads of it.
		"lines":
		[
			[&"print", "ADMIT ONE DRIVER"],
			[&"print", "No experience required. Free lesson included."],
			[&"print", "No. {invitation}"],
		],
	},
	2:
	{
		"title": "Inspection",
		"paper": &"clipboard",
		# Kit's count in pencil beside the margin's line, carried on from the stub's.
		"tally": 2,
		"lines":
		[
			[&"print", "DEPT. OF KARTS · DRIVING TEST · INSPECTION"],
			[&"print", "DATE ................ {licensed}"],
			[&"print", "INSPECTOR ........... No. 4 (automated)"],
			[&"print", "LEARNER ............. Drove. Steered. Braked. Drifted."],
			[&"print", "LEARNER WROTE NOTHING DOWN."],
			[&"print", "INSPECTOR WROTE EVERYTHING DOWN."],
			[&"print", "FINDINGS ............ Nothing to object to."],
			[&"margin", "That's two. —K."],
		],
	},
	3:
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
	4:
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
			[&"print", "ADVISORY (UNPAID) ... 1   KIT, JJ-000001"],
			[&"print", "NO ACTION REQUIRED."],
		],
	},
	6:
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
	7:
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
	8:
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
			[&"margin", "Their count's right. Was yours? —K."],
		],
		# Kit's pencil under the print, with an arrow from it up to clause 4.
		"arrow": [8, 4],
	},
	10:
	{
		"title": "Blanks",
		"paper": &"graph",
		"lines":
		[
			[
				&"hand",
				(
					"There were four hundred blank licenses left in the Department's drawer the week"
					+ " they let the last examiner go. I scratched the same line into every one. If"
					+ " you're reading this, they printed you one. —K."
				),
			],
		],
	},
	11:
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
	12:
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
	13:
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
	14:
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
	15:
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
	16:
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
	17:
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
	18:
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
	19:
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
	20:
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
	21:
	{
		"title": "Not this time",
		"paper": &"strip",
		"lines": [[&"hurried", "Don't stamp it! Don't accept their terms. Not this time. —K."]],
	},
	22:
	{
		"title": "Profile complete",
		"paper": &"sheet",
		"lines":
		[
			[&"print", "HOUSE OPERATIONS · STAFF RECORD"],
			[&"print", "OPERATOR ............................ JJ-000001"],
			[&"print", "PREDICTION ACCURACY ................. 100%", true],
			[&"margin", "Not quite. —K."],
			[&"print", "PROFILE ............................. COMPLETE"],
			[&"print", "SEAT ................................ RELEASED"],
			[&"print", "THE HOUSE THANKS THE OPERATOR FOR THEIR SERVICE."],
		],
	},
	23:
	{
		"title": "To whoever is next",
		"paper": &"graph_torn",
		"lines":
		[
			[
				&"hand",
				(
					"If you're reading this, you're in the chair now. It isn't bad. Nothing"
					+ " happens. Things get decided and a name goes on them. I said no the first"
					+ " time. It was the only thing I ever did that they didn't see coming."
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
	24:
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
## a word stamped, [code]sketch[/code] a drawing in pencil, [code]tally[/code] Kit's count in pencil
## strokes over the lines, [code]at[/code] how far down the lines start, [code]tilt[/code] how far
## they are turned about their middle; [code]paper[/code] and [code]color[/code] are the back's own
## where it is not the front's.
const BACKS := {
	1:
	{
		"tally": 1,
		"at": 0.42,
		"lines": [[&"hand", "That's one. Keep count. —K."]],
	},
	3:
	{
		"sketch": &"junction",
		"lines": [[&"hand", "Fitted by hand. The next ones won't be. —K."]],
	},
	4:
	{
		"band": true,
		"lines":
		[
			[&"print", "JACKPOT JUNCTION · KEEP THIS RECEIPT"],
			[&"small", "NO RECEIPT, NO PAYOUT"],
		],
	},
	6:
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
	8:
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
	10: {"lines": [[&"hand", "Used a compass. Took all night. —K."]]},
	12:
	{
		"lines":
		[
			[&"old", "§ 0.1  These rules are written by people, for the tables."],
			[&"old", "§ 0.2  Where they are wrong, people shall change them."],
		],
	},
	14:
	{
		"through": true,
		"tilt": -0.15,
		"at": 0.72,
		"lines": [[&"hand", "Changed it again. It caught up by lunch. —K."]],
	},
	15:
	{
		"window": true,
		"lines":
		[
			[&"print", "DEPT. OF KARTS"],
			[&"print", "TO THE OCCUPANT"],
			[&"small", "POSTAGE PAID BY THE HOUSE"],
		],
	},
	17:
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
	20: {"lines": [[&"hand", "Left the lamp on. —K."]]},
	21: {"lines": [[&"print", "§ 1.1  No table shall open without human oversight."]]},
	23: {"lines": [[&"hand", "P.S. Brake on a straight now and then. It hates that. —K."]]},
}

# --- the schedule ---------------------------------------------------------------------------------


## The next note [param story] has to find, in order, or 0 once it has them all.
static func next_of(story: StoryState) -> int:
	for number: int in range(1, Story.NOTE_COUNT + 1):
		if not story.has_note(number):
			return number
	return 0


## The note due for [param profile] in a map now, or 0 for none: never before the license or with
## the story off; the first from the profile's first map, a quick match's or a Grand Prix's; the
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


## The pages of [param story]'s folder, see [NotesFolder]: the notes found, in the story's order,
## the invitation first, 6.1a, its stub, note 1, then the program's letter once its card is
## activated, 6.6b, the House's letters among the notes, 6.11; the loose ones in the back pocket in
## the order found, STORY.md 7.3; and after the ending what the player kept of it at the back,
## STORY.md 7.2, the House's page torn off among it from the first time it was.
static func folder_order(story: StoryState) -> PackedInt32Array:
	var found := PackedInt32Array()
	var loose := PackedInt32Array()
	for number: int in story.notes:
		if is_loose(number):
			loose.append(number)
		else:
			found.append(number)
	found.sort()
	StoryLetters.file_among(found, story)
	if story.kept_letter:
		found.insert(1 if found.has(1) else 0, WELCOME_LETTER)
	if story.invited:
		found.insert(0, OPENING)
	found.append_array(loose)
	if story.ended():
		found.append(INVITATION)
		found.append(TICKET)
	# The House's page torn off, kept at the back, and the slip stamped another day after it.
	if not story.torn.is_empty():
		found.append(TORN_SLIP)
	if story.ended():
		found.append(FINAL_SLIP)
		found.append(TERMS_CARD)
	return found


## The loose note due for [param profile], STORY.md 7.3, or 0 for none: with the story on, Kit's
## note for a refusal once the House's page has been torn off, then the first whose bet off the
## books has been won, in the order they were won, and not found yet.
static func loose_due(profile: Profile) -> int:
	if profile == null or not profile.story.on:
		return 0
	if profile.story.tears > 0 and not profile.story.has_note(NOT_STAMPED):
		return NOT_STAMPED
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


## Whether a note due for [param story] turns up in this map: before the ending, always, so a
## player who takes them keeps level with the story; after it, an even chance, certain once it has
## been due for two maps without turning up.
static func turns_up(story: StoryState, rng: RandomNumberGenerator) -> bool:
	if not story.ended() or story.note_waits >= Story.NOTE_CERTAIN_AFTER:
		return true
	return rng.randf() < Story.NOTE_CHANCE


## When in a match of [param length] seconds on its clock a note turns up: between twenty seconds
## in and a minute before the end, or, in a map too short for that, the middle half of it; the
## story's [param first] note no later than a minute in, so a new player meets it early.
static func moment(length: float, rng: RandomNumberGenerator, first := false) -> float:
	var earliest := minf(Story.NOTE_FROM, length * 0.25)
	var latest := length - Story.NOTE_BEFORE_END
	if latest < earliest + 10.0:
		latest = length * 0.75
	if first:
		latest = clampf(Story.FIRST_NOTE_BY, earliest + 1.0, maxf(latest, earliest + 1.0))
	return rng.randf_range(earliest, latest)


## Every note of the story earlier in the order than the last [param story] has found and not found
## itself filed, new, STORY.md 5.2: a profile from before the story was retold, whose order has
## moved under it, reads what it would have found in the folder rather than meeting it on a floor
## out of order. Nothing for a profile that has found them in order.
static func catch_up(story: StoryState) -> void:
	var last := 0
	for number: int in story.notes:
		if number >= 1 and number <= Story.NOTE_COUNT:
			last = maxi(last, number)
	for number: int in range(1, last):
		if not story.has_note(number):
			story.notes.append(number)


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
	if StoryLetters.is_letter(number):
		return StoryLetters.title_of(StoryLetters.key_of(number))
	return str(NOTES.get(number, {}).get("title", ""))


## Note [param number] as a screen reader reads it out, see [ScreenReader]: its title and its
## lines in order, filled in for [param profile], one struck through by hand said to be.
static func read_out(number: int, profile: Profile) -> String:
	if StoryLetters.is_letter(number):
		var key := StoryLetters.key_of(number)
		return ScreenReader.line([title_of(number), StoryLetters.read_out(key, profile)])
	var said := PackedStringArray([title_of(number)])
	for line: Array in NOTES.get(number, {}).get("lines", []):
		var words := StoryFill.fill(str(line[1]), profile) if profile != null else str(line[1])
		said.append(STRUCK % words if line.size() > 2 and bool(line[2]) else words)
	return ScreenReader.line(said)
