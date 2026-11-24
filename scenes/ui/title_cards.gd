class_name TitleCards
extends Node
## What the title puts up by itself as it comes up, GAME.md 3.8: the shaders compiling first, once a
## version, said in a pane over all of it, 10.7, see [WarmupPane]; then one card a visit at the
## most, the first of them due: the invitation that brought the player here, the first time a
## profile comes to the title, STORY.md 6.1a; the supporter pack's thanks, GAME.md 10.8; the
## House's welcome to its loyalty program, 8.9; a letter of the House's as a stage begins, STORY.md
## 6.11. A visit back from the settings or Play Online, where the player went to change something
## rather than to play, brings none but the invitation. A card is put up at once, under the
## warm-up's pane, so it has drawn everything once by the time it starts, and started once the
## shaders have compiled. Once nothing is up the title is the player's, see [signal opened].

## Nothing is up any more: the title is the player's, its opening to play or the cursor to go on
## Play.
signal opened
## The program's welcome has opened its map over the title, [param dialog].
signal welcomed(dialog: LoyaltyDialog)

## Whether the next visit to the title is back from the settings or Play Online, see the class.
static var from_the_menus := false

## The shaders compiling, said over the title while they do, or null, see [WarmupPane].
var warming: WarmupPane
## The invitation that brought the player here while it is up, STORY.md 6.1a, and where accepting
## it goes for a player with no license yet: the free lesson its stub promises, GAME.md 9.4a,
## unless a test says otherwise.
var invitation: OpeningInvitation
var to_school := Game.go_to_tutorial
## The House's welcome to its loyalty program while it is up, GAME.md 8.9, and the map it opens
## until that is put away.
var welcome: LoyaltyWelcome
## The supporter pack's thanks while they are up, GAME.md 10.8, or a letter of the House's, STORY.md
## 6.11.
var mail: Variant

var _title: Control


## The cards for [param title], under it, going to [param school] for the free lesson: put up by
## [method put_up] once the title has said what it wants told.
static func add_to(title: Control, school: Callable) -> TitleCards:
	var cards := TitleCards.new()
	cards.name = "Cards"
	cards._title = title
	cards.to_school = school
	title.add_child(cards)
	return cards


## The card due put up, if any, and the warm-up started over it, or the card started at once with
## nothing to compile.
func put_up() -> void:
	var profile := Game.settings.profile
	var quiet := from_the_menus
	from_the_menus = false
	if OpeningInvitation.due(profile):
		invitation = OpeningInvitation.over(_title, profile)
		invitation.accepted.connect(_on_invited)
		# It comes in silence, the music faded out if it was playing, and held off till the title
		# opens.
		Audio.hold_music(true)
	# Nothing more on a visit back from the settings or Play Online.
	elif quiet:
		pass
	# Or the supporter pack's thanks, GAME.md 10.8, the same way: next after the invitation, never
	# with it.
	elif SupporterThanks.due():
		mail = SupporterThanks.over(_title)
	# Or, once a map has been played to its whistle, the House's welcome to its loyalty program,
	# GAME.md 8.9.
	elif LoyaltyWelcome.due(profile):
		welcome = LoyaltyWelcome.over(_title, profile)
		welcome.welcomed.connect(_on_welcomed)
	# Or a letter of the House's, as a stage begins, STORY.md 6.11: one a visit, after the rest.
	elif not StoryLetters.due(profile).is_empty():
		mail = HouseMail.over(_title, profile)
	if mail != null:
		mail.put_away.connect(_on_mail_put_away)
	# The shaders compile first, once a version, GAME.md 10.7, said in a pane over all of it, the
	# license too, with Skip; the opening waits for them, since it would only stutter while they
	# compile, and the menu is the player's once both are done.
	var warmup := ShaderWarmup.add_to(_title)
	if warmup != null:
		warming = WarmupPane.over(_title, warmup)
		warming.put_away.connect(_on_warmed)
	else:
		_on_warmed()


## Whether the warm-up's pane, with [param warm_up], the invitation or the program's welcome is up,
## which the title's own keys keep out of the way of.
func holding(warm_up := true) -> bool:
	return (warm_up and warming != null) or invitation != null or welcome != null


## The shaders compiled, skipped, or none to compile: the card put up starts, or the title opens.
func _on_warmed() -> void:
	warming = null
	if Demo.playing():
		return
	# A friend's game on Steam, which Steam started the game to join, GAME.md 10.8.
	if Store.join_asked_at_launch():
		return
	if invitation != null:
		invitation.start()
		return
	if welcome != null:
		welcome.start()
		return
	if mail != null:
		mail.start()
		return
	_open()


## The invitation accepted: the free lesson its stub promises, GAME.md 9.4a, the title and its
## opening waiting until the test is passed or skipped. A profile that holds a license already, one
## from before the invitation was, comes to the title as it always did.
func _on_invited() -> void:
	if not Game.settings.license_number.is_empty():
		_open()
		return
	invitation = null
	Audio.hold_music(false)
	DrivingSchool.free_lesson = true
	to_school.call()


## Welcomed, the program's map open over the title, [param dialog]: told, and once the map is put
## away the title is the player's.
func _on_welcomed(dialog: LoyaltyDialog) -> void:
	welcomed.emit(dialog)
	dialog.put_away.connect(
		func() -> void:
			welcome = null
			_open()
	)


func _on_mail_put_away() -> void:
	mail = null
	_open()


func _open() -> void:
	invitation = null
	opened.emit()
