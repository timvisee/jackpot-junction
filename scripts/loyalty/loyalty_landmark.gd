class_name LoyaltyLandmark
extends Resource
## One landmark on the loyalty program's map, GAME.md 8.9: a bet, where it stands, and what it pays
## once won. The bet is one of a few kinds, so a new bet of a known kind is a line of data and no
## code: a statistic of 8.5 reaching a count, a feat of one map, a thing found, notes found, or the
## card itself on the slip road. See [Loyalty] for when a landmark is open and when it is won.

## Which part of the map it stands in.
enum District {
	## The slip road, where every profile starts.
	SLIP,
	## The house's own, on the left.
	STRIP,
	## The Department of Karts', on the right.
	DEPARTMENT,
	## Kit's roads in pencil across the top, only with the story on and a note found.
	OFF_THE_BOOKS,
}

## What its bet asks.
enum Kind {
	## The program's card activated: the slip road's landmark, won with the welcome.
	CARD,
	## A statistic of the profile, [LifetimeStats], reaching [member count].
	STAT,
	## A feat of one map, [member stat] being its id in [member LoyaltyState.feats].
	FEAT,
	## A thing of Lost Property found, its id in [member LoyaltyState.found].
	FIND,
	## As many of the story's notes found as [member count].
	NOTES,
}

## Its name in the profile, which never changes however the map is redrawn.
@export var id: StringName
## The character it is drawn as on the map's grid.
@export var mark := ""
@export var district := District.STRIP
## The last landmark on its district's road to the roundabout: open only once every road into it is
## won, and then asking a bet of its own.
@export var keystone := false
## Open as soon as its district is, with no road won: the slip road's, and the first off the books.
@export var entry := false
@export var kind := Kind.STAT
## The statistic a [constant Kind.STAT] bet reads, or the feat a [constant Kind.FEAT] bet asks for.
@export var stat: StringName
## How much of the statistic, or how many notes, the bet asks for.
@export var count := 1.0
## How the bet reads on the map, "{count}" standing for the count as the map shows it.
@export var bet := ""

@export_group("Pays")
## The jokers it adds to the profile's deck, by id.
@export var jokers: Array[StringName] = []
## The power-ups of the later set it adds, by id.
@export var items: Array[StringName] = []
## The kind of dress it pays, paint, hat, flag, trail, frame, marks or card_back, and which.
@export var dress_part: StringName
@export var dress := ""
## The loose note it makes due, STORY.md 7.3.
@export var note: StringName
## Whether it opens the Showroom, GAME.md 8.9.
@export var showroom := false
