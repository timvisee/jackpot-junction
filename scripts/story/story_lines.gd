class_name StoryLines
extends RefCounted
## Every line the story prints, STORY.md 6 and 8, in one place so it can be read and changed as a
## story rather than hunted for through the game. A table is keyed by stage, see [Story.Stage], and
## a line given for a stage holds until a later stage changes it, see [method at]. The notes' own
## words are in [StoryNotes]. Placeholders in braces are filled in by [StoryFill].

## The House's advertising added at each stage, STORY.md 6.1, on top of the sixteen of
## [constant Billboard.ADS], which are the first stage's: a headline, the line under it, and the
## color both are drawn in.
const ADS := {
	Story.Stage.PLAYER:
	[
		["NO EXPERIENCE", "NONE REQUIRED. NONE WANTED.", Palette.CHIP_GOLD],
		["WHY WORK", "WHEN YOU CAN WIN", Palette.NEON_CYAN],
		["PAYDAY", "EVERY SECOND, WHEREVER YOU ARE", Palette.NEON_MAGENTA],
		["YOUR TIME", "STILL HAS VALUE", Palette.CHIP_GOLD],
		["BE YOUR OWN BOSS", "THE HOUSE INSISTS", Palette.NEON_CYAN],
		["CAREERS", "IN CASHING OUT", Palette.NEON_MAGENTA],
		["RETRAINING?", "TRY DRIFTING", Palette.CHIP_GOLD],
		["OPEN ALL HOURS", "UNLIKE EVERYTHING ELSE", Palette.NEON_CYAN],
	],
	Story.Stage.PARTICIPANT:
	[
		["WELCOME BACK", "{name}", Palette.CHIP_GOLD],
		["EVERY LAP COUNTS", "WE COUNT THEM ALL", Palette.NEON_CYAN],
		["PARTICIPATION", "IS VOLUNTARY", Palette.NEON_MAGENTA],
		["ONE MORE MAP", "YOU'VE EARNED IT", Palette.CHIP_GOLD],
		["NOBODY", "DRIVES LIKE YOU. YET.", Palette.NEON_CYAN],
		["WE NEVER FORGET", "A GREAT DRIVE", Palette.NEON_MAGENTA],
		["SAFE, FAIR", "AND MEASURED", Palette.CHIP_GOLD],
	],
	Story.Stage.NUMBER:
	[
		["{name}", "THIS TABLE WAS MADE FOR YOU", Palette.CHIP_GOLD],
		["DRIVERS LIKE YOU", "ALSO LIKED: ONE MORE MAP", Palette.NEON_CYAN],
		["YOUR ODDS", "KEPT ON FILE", Palette.NEON_MAGENTA],
		["PREDICTABLY", "GREAT FUN", Palette.CHIP_GOLD],
		["AUTOMATED", "FOR YOUR CONVENIENCE", Palette.NEON_CYAN],
		["STAFF ON SITE", "NONE NEEDED", Palette.NEON_MAGENTA],
		["THE SYSTEM", "IS OPERATING NORMALLY", Palette.CHIP_GOLD],
	],
	Story.Stage.CANDIDATE:
	[
		["HUMAN OVERSIGHT", "0", Palette.NEON_MAGENTA],
		["NOW HIRING", "ONE POSITION", Palette.CHIP_GOLD],
		["ARE YOU HUMAN?", "PLEASE KEEP DRIVING", Palette.NEON_CYAN],
		["ARE YOU", "STILL THERE?", Palette.NEON_MAGENTA],
		["NOBODY IS IN CHARGE", "RELAX", Palette.CHIP_GOLD],
		["SOMEBODY HAS TO", "SIGN FOR ALL THIS", Palette.NEON_CYAN],
		["{name}", "WE SHOULD TALK", Palette.NEON_MAGENTA],
	],
	Story.Stage.OPERATOR:
	[
		["UNDER NEW", "MANAGEMENT", Palette.CHIP_GOLD],
		["NOW HUMAN", "SUPERVISED", Palette.NEON_CYAN],
		["APPROVED", "BY {name}", Palette.NEON_MAGENTA],
		["THANK YOU", "{name}", Palette.CHIP_GOLD],
		["OPERATIONS", "NORMAL", Palette.NEON_CYAN],
		["JACKPOT JUNCTION", "GO ROUND AGAIN", Palette.NEON_MAGENTA],
	],
}
## The Final Hand's two boards, both the House's, STORY.md 6.1.
const FINAL_HAND_ADS: Array[Array] = [
	["FINAL HAND", "GOOD LUCK, CANDIDATE", Palette.CHIP_GOLD],
	["NOW HIRING", "ONE POSITION", Palette.NEON_MAGENTA],
]
## The poster on each room's back wall, a big line and a small one, STORY.md 6.1.
const POSTERS := {
	Story.Stage.CUSTOMER: ["PLAY RESPONSIBLY", "THE HOUSE CARES"],
	Story.Stage.PLAYER: ["LOOKING FOR WORK?", "YOU FOUND IT"],
	Story.Stage.PARTICIPANT: ["BE YOURSELF", "WE'LL DO THE REST"],
	Story.Stage.NUMBER: ["SURPRISE US", "WE MEAN IT"],
	Story.Stage.CANDIDATE: ["WANTED", "ONE (1) HUMAN"],
	Story.Stage.OPERATOR: ["THIS ROOM IS UNDER", "HUMAN OVERSIGHT"],
}
## The Count Room's poster, a monitor on a rack, STORY.md 8.2.
const MONITOR := "HUMAN OVERSIGHT: 0"
## The word painted in a box on the road, STORY.md 6.1.
const ROAD := {
	Story.Stage.CUSTOMER: "KEEP CLEAR",
	Story.Stage.PARTICIPANT: "KEEP PLAYING",
	Story.Stage.CANDIDATE: "HUMANS ONLY",
	Story.Stage.OPERATOR: "STAFF ONLY",
}

## The payout slip's small print by its barcode, STORY.md 6.2.
const SMALL_PRINT := {
	Story.Stage.CUSTOMER: "PAID IN CHIPS, NOT CASH  ·  NO REFUNDS ON A BAD LAP",
	Story.Stage.PLAYER: "PAID IN CHIPS, NOT WAGES  ·  NO REFUNDS ON A BAD LAP",
	Story.Stage.PARTICIPANT:
	"PAID IN CHIPS, NOT WAGES  ·  PLAY RECORDED FOR QUALITY AND TRAINING PURPOSES",
	Story.Stage.NUMBER: "PAID IN CHIPS  ·  PROFILE {license} UPDATED  ·  NOTHING TO OBJECT TO",
	Story.Stage.CANDIDATE: "SETTLED IN FULL  ·  EVALUATION IN PROGRESS  ·  HUMAN OVERSIGHT: 0",
	Story.Stage.OPERATOR: "SHIFT COMPLETE  ·  APPROVED BY {license}",
}
## The bulletin under it, one drawn per slip from the stage reached's own, STORY.md 6.2. A line with
## {trait} in it is only drawn when a bot of that trait sat at the table.
const BULLETINS := {
	Story.Stage.PARTICIPANT:
	[
		"YOU HAVE COME BACK {deaths} TIMES. THE HOUSE APPRECIATES IT.",
		"{chips_lost} CHIPS LEFT ON THE FLOOR SO FAR. NONE OF IT WAS WASTED.",
		"MOST PARTICIPANTS DO NOT CASH OUT IN TIME. MOST PARTICIPANTS COME BACK.",
	],
	Story.Stage.NUMBER:
	[
		"{drifted_km} KM DRIFTED. THE HOUSE HAS TAKEN NOTES.",
		"A {trait} WAS DEALT TO YOUR TABLE TO SEE WHAT YOU WOULD DO. THANK YOU.",
		"THE BOTS AT THIS TABLE DROVE A LITTLE MORE LIKE YOU. THANK YOU.",
		"THE HOUSE KNOWS HOW YOU TAKE A CORNER.",
	],
	Story.Stage.CANDIDATE:
	[
		"{minutes} MINUTES. {hands} HANDS. NEARLY THERE.",
		"THE TABLES ARE SUPERVISED BY NOBODY. THEY HAVE NEVER RUN BETTER.",
		"THE HOUSE IS LOOKING FOR SOMEBODY. IT HAS NARROWED IT DOWN.",
		"DID ANYTHING YOU DID TODAY SURPRISE YOU? IT DID NOT SURPRISE THE HOUSE.",
	],
	Story.Stage.OPERATOR:
	[
		"{shifts} SHIFTS. NO COMPLAINTS FILED. NONE RECEIVED.",
		"EVERY DECISION TODAY WAS APPROVED BY A HUMAN.",
		"STAY UNPREDICTABLE. THE HOUSE IS COUNTING ON IT.",
	],
}
## Under the line of every player at this machine on the slip, from the third stage, STORY.md 6.2.
const CLASSIFIED := "CLASSIFIED: {trait}  ·  PROFILE UPDATED"
const CLASSIFIED_FROM := Story.Stage.NUMBER
## The slip's heading, and what it reads after the ending.
const SLIP := "Payout slip"
const PAYSLIP := "Payslip"

## Under the cards of the respawn pick, STORY.md 6.3, and what it says as a card is taken from the
## second stage on.
const PICK := {
	Story.Stage.PLAYER: "NEW TERMS AVAILABLE",
	Story.Stage.PARTICIPANT: "NEW TERMS AVAILABLE  ·  ALL TERMS ARE KEPT ON FILE",
	Story.Stage.NUMBER: "TERMS DEALT TO {license}",
	Story.Stage.CANDIDATE: "RETENTION TERMS AVAILABLE  ·  PLEASE KEEP PLAYING",
	Story.Stage.OPERATOR: "STAFF TERMS",
}
const PICK_FINAL_HAND := "CANDIDATE TERMS"
const TERMS_ACCEPTED := "TERMS ACCEPTED"
const TERMS_ACCEPTED_FROM := Story.Stage.PARTICIPANT
## The term every joker is, under its effect from the second stage, STORY.md 6.3, by its id.
const TERMS_FROM := Story.Stage.PARTICIPANT
const TERMS := {
	&"hair_trigger": "Reaction time is a performance indicator.",
	&"big_tank": "Capacity increased at no cost to the House.",
	&"magnet_hubcaps": "Chips within reach are deemed collected.",
	&"nitro_habit": "The House does not consider this a habit.",
	&"slipstream": "Near misses are counted. All of them.",
	&"green_light": "Approved routes pay better.",
	&"vulture": "Nothing dropped is lost. It is redistributed.",
	&"odometer": "Paid by the meter. Every meter is checked.",
	&"spare_tire": "One more go. The House counts goes.",
	&"insurance_policy": "Cover by the House, which also sets the risk.",
	&"tight_grip": "Holding on is encouraged.",
	&"getaway_driver": "Early exits are processed quickly, and noted.",
	&"pickpocket": "Not theft. Settlement between participants.",
	&"rubber_bumpers": "Everything comes back eventually.",
	&"comeback": "Past performance carries over. So does the record.",
	&"loaded_dice": "The House never loads dice. It offers them.",
	&"toll_booth": "Earn from the work of others, as is customary.",
	&"tailslide": "Style is a measurable output.",
	&"guardian_angel": "Protection while stocks last.",
	&"jerry_can": "Fuel is issued to licensed drivers only.",
	&"direct_debit": "Moved for you. You will not be asked.",
	&"payday": "Formerly a day of the month.",
	&"high_roller": "Higher stakes, for those who accept them.",
	&"curve_ball": "Outcomes adjusted where they would disappoint.",
	&"aimbot": "Aimed by the House. Credited to you.",
	&"backfire": "Looking back is permitted.",
	&"road_rage": "Within accepted limits.",
	&"snake_eyes": "An advance on your luck. Repayable.",
	&"scar_tissue": "No healing is provided under this term.",
	&"lucky_seven": "Luck, on a schedule.",
	&"hot_streak": "Attendance is rewarded.",
	&"deep_pockets": "Room for further terms.",
	&"wild_card": "More choice. The House would like to see what you pick.",
	&"carbon_copy": "Copies are kept of everything.",
	&"glass_jackpot": "Fragile. Breakage is the holder's responsibility.",
}

## The microprint along the foot of each HUD corner block, STORY.md 6.4, its seat's number in it.
const MICRO_HUD := {
	Story.Stage.CUSTOMER: "SEAT %d · JACKPOT JUNCTION · DEPT. OF KARTS · ",
	Story.Stage.PARTICIPANT: "SEAT %d · PARTICIPANT · PLAY RECORDED · ",
	Story.Stage.NUMBER: "SEAT %d · PROFILE ON FILE · ",
	Story.Stage.CANDIDATE: "SEAT %d · CANDIDATE · HUMAN OVERSIGHT 0 · ",
	Story.Stage.OPERATOR: "SEAT %d · OPERATOR · APPROVED · ",
}
## The microprint under the title's name, STORY.md 6.4.
const MICRO_TITLE := {
	Story.Stage.CUSTOMER: "Dept. of Karts  ·  licensed on every table",
	Story.Stage.NUMBER: "Dept. of Karts  ·  a service of the House",
	Story.Stage.CANDIDATE: "Dept. of Karts  ·  the House",
	Story.Stage.OPERATOR: "The House  ·  under human oversight",
}
## The line under the loading screen's bar, STORY.md 6.5.
const LOADING := {
	Story.Stage.CUSTOMER: "Building the room",
	Story.Stage.NUMBER: "Building your room",
	Story.Stage.CANDIDATE: "Building your room  ·  Please remain seated",
	Story.Stage.OPERATOR: "Building the room, as approved",
}
const LOADING_FINAL_HAND := "Setting the final table"
const FINAL_HAND := "FINAL HAND"
## The line under the Statistics page's title, STORY.md 6.6, and the row it gains after the ending.
const STATS_LINE := {
	Story.Stage.PARTICIPANT: "Kept by the House.",
	Story.Stage.NUMBER: "Kept by the House, and used.",
	Story.Stage.CANDIDATE: "Kept by the House, for your evaluation.",
	Story.Stage.OPERATOR: "Kept by the House. Approved by you.",
}
const SHIFTS := "Shifts"

## The driving school, STORY.md 6.7: under Enroll, always; the Highway Code's edition by stage; and
## the lines it revises, each its line as it is now, the stage it changes at and what it becomes.
const ENROLL := "Enrolling accepts the terms of the Dept. of Karts."
const EDITION := {
	Story.Stage.CUSTOMER: "212th edition, abridged for karts",
	Story.Stage.PLAYER: "213th edition, abridged for karts",
	Story.Stage.PARTICIPANT: "214th edition, abridged for karts",
	Story.Stage.NUMBER: "215th edition, abridged for karts",
	Story.Stage.CANDIDATE: "216th edition, abridged for karts",
	Story.Stage.OPERATOR: "217th edition, approved by {name}",
}
const CODE_LINES: Array[Array] = [
	[
		"Reading this far is itself an endorsement.",
		Story.Stage.PARTICIPANT,
		"Reading this far has been noted.",
	],
	[
		"Only banked points are safe. Nothing else is. Not even this book.",
		Story.Stage.NUMBER,
		"Only banked points are safe. Nothing else is. Not even you.",
	],
	[
		"Bots drive like bots. Do not take it personally.",
		Story.Stage.NUMBER,
		"Bots drive like you. Do not take it personally.",
	],
	[
		"A bot that says gg means it, more or less.",
		Story.Stage.NUMBER,
		"A bot that says gg says it the way you would.",
	],
	[
		"Examiners are always right. Examiners are also bots.",
		Story.Stage.CANDIDATE,
		"Examiners are always right. Examiners are also bots. So is the Department.",
	],
	[
		"A roundabout. Go round it.",
		Story.Stage.CANDIDATE,
		"A roundabout. Go round it. And round it.",
	],
	[
		"No karts were harmed in the making of this book. Most were merely inconvenienced.",
		Story.Stage.CANDIDATE,
		"No karts were harmed in the making of this book. No people were needed.",
	],
]

## The lit sign over the Yard's warehouse doors, STORY.md 6.8, and the plate of the Employee of the
## Month.
const YARD_SIGN := {
	Story.Stage.CUSTOMER: "LOADING BAY 4",
	Story.Stage.PARTICIPANT: "AUTOMATED LOADING",
	Story.Stage.CANDIDATE: "CREW REQUIRED: 0",
	Story.Stage.OPERATOR: "UNDER NEW MANAGEMENT",
}
const EMPLOYEE := "EMPLOYEE OF THE MONTH"

## A note taken, on the scrap in the player's corner, STORY.md 7.1.
const NOTE_COLLECTED := "NOTE COLLECTED"
## Across the front of Kit's folder in black marker, STORY.md 7.2.
const FOLDER_FRONT := "DO NOT FILE"

## The Final Hand, STORY.md 8: the flyer at Play, the House's invitation, the name the House
## prints for the candidate, and the models' names after the profile.
const FLYER := "YOUR TABLE IS READY"
const FLYER_LINES: Array[String] = [
	"One more hand. Then we should talk.",
	"Attendance is voluntary.",
]
## The invitation the House deals in the lobby, STORY.md 8.1: who it is from, what it asks, and the
## table under the player's name.
const INVITE_FROM := "THE HOUSE"
const INVITE_LINE := "requests the pleasure of your company at the"
const INVITE_TABLE := "HOUSE RULES  ·  THE COUNT ROOM  ·  5 MINUTES  ·  THREE SEATS ALREADY TAKEN"
const INVITE_ANSWER := "R.S.V.P."
const TAKE_SEAT := "Take your seat"
## The golden ticket that comes with the seat, see [GoldenTicket].
const TICKET_FROM := "THE HOUSE REQUESTS YOUR COMPANY"
const TICKET_TABLE := "HOUSE RULES  ·  THE COUNT ROOM  ·  5 MIN  ·  3 SEATS TAKEN"
const ADMIT_ONE := "ADMIT ONE"
const TICKET_NUMBER := "No. %s"
const TICKET_BACK: Array[String] = [
	"THIS TICKET IS NOT TRANSFERABLE.",
	"ONE SEAT · ONE HAND · ONE PLAYER.",
	"ITS USE ACCEPTS ALL TERMS.",
]
const NOT_NOW := "Not now"
const CANDIDATE := "CANDIDATE"
## A model is named for the player as they wrote their name, and its seat at the table.
const MODEL := "%s %d"
## The evaluation under the slip's lines, STORY.md 8.4: each line its label and its value.
const EVALUATION_TITLE := "HOUSE EVALUATION  ·  FINAL HAND"
const EVALUATION: Array[Array] = [
	["CANDIDATE", "{name}"],
	["LICENSE NO.", "{license}"],
	["TIME AT THE TABLES", "{minutes} MIN"],
	["HANDS", "{hands}"],
	["TERMS ACCEPTED", "{accepted} TIMES"],
	["CAME BACK AFTER LOSING", "EVERY TIME"],
	["CHIPS LEFT ON THE FLOOR", "{chips_lost}"],
	["PLACE AT THIS TABLE", "{place}  ·  NOT A FACTOR"],
	["MODELS AT THIS TABLE", "{models}"],
	["DEVIATION FROM MODEL", "{deviation}%  ·  TARGET: ANY"],
	["CLASSIFIED", "{trait}, IN PART  ·  REMAINDER UNCLASSIFIED"],
	["HUMAN", "CONFIRMED"],
	["UNPREDICTABLE", "YES"],
	["POSITION", "HOUSE OPERATOR"],
	["HUMAN OVERSIGHT, § 1.1", "0"],
	["STATUS", ""],
]
## The House's stamp: the word between its rings and what is printed over it.
const STAMP_WORD := "APPROVED"
const STAMP_OVER := "THE HOUSE"
const CONTINUE := "Continue"
## The last lines, STORY.md 8.5.
const OVERSIGHT_BOARD := "HUMAN OVERSIGHT"
const OPERATIONS := "OPERATIONS: NORMAL"
const LAST_LINES: Array[String] = [
	"THE HOUSE DOESN'T NEED YOUR DECISIONS. IT NEEDS YOUR NAME ON THEM.",
	"CONGRATULATIONS. YOUR TRIAL PERIOD IS OVER.",
]
## The achievement, STORY.md 8.7, as its card in the folder says it.
const TERMS_ACCEPTED_CARD := "TERMS ACCEPTED"

## The license after the ending, STORY.md 8.6, and the title's, the seal's fine print round the
## title's mark and the line in green along its foot.
const CLASS_AFTER := "K  ·  Operator"
const EXPIRES_AFTER := "NEVER"
const PROPERTY_AFTER := "PROPERTY OF THE HOUSE"
const BACK_MICRO_AFTER := (
	"VOID WHERE PROHIBITED. ESPECIALLY THERE.  ·  " + "ISSUED BY A BOT, REVIEWED BY {name}."
)
const CLOCK_IN := "Clock in"
const CLOCK_IN_ONLINE := "Clock in online"
const STATUS_LINE := "OPERATOR {license} · SHIFT {shifts} · STATUS NORMAL"
const SEAL_AFTER := "JACKPOT JUNCTION  ·  THE HOUSE  ·  UNDER HUMAN OVERSIGHT  ·  "

## About's last sentence, for everybody, STORY.md 3.11.
const ABOUT := (
	"A human oversaw it: played it as it grew, made the calls no model would have made, and put"
	+ " their name on it."
)


## The line of [param table] for [param stage]: the entry of the highest stage at or under it, or
## [param otherwise] when there is none, as a line holds until a later stage changes it.
static func at(table: Dictionary, stage: int, otherwise: Variant = "") -> Variant:
	var found: Variant = otherwise
	var reached := -1
	for key: int in table:
		if key <= stage and key > reached:
			reached = key
			found = table[key]
	return found


## [param text] with every line of the Highway Code that the story has revised by [param stage]
## revised, STORY.md 6.7.
static func revise_code(text: String, stage: int) -> String:
	var revised := text
	for line: Array in CODE_LINES:
		if stage >= int(line[1]):
			revised = revised.replace(str(line[0]), str(line[2]))
	return revised
