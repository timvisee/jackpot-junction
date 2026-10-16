class_name StoryTable
extends Node
## What the story does at an ordinary table that no word says, STORY.md 6.9: from the second stage
## figures in the crowd stop dancing to follow the player's kart round the table, more of them each
## stage, see [method Crowd.watched_by]; and from the third, one bot at the table wears a piece of
## the player's own dress, a hat or a flag, see [method dress_bot]. All of it on this machine
## alone, for the profile playing's own seat, and none of it at the Final Hand, whose crowd and
## models are the House's in a way of their own, see [FinalHandTable].

## How many in the crowd watch the player's kart at each stage, none before the second.
const WATCHERS := {
	Story.Stage.PARTICIPANT: 1,
	Story.Stage.NUMBER: 6,
	Story.Stage.CANDIDATE: 24,
	Story.Stage.OPERATOR: 24,
}
## The stage from which a bot wears a piece of the player's dress.
const DRESSED_FROM := Story.Stage.NUMBER

var match_node: Match
## The stage this machine shows, as the table was laid.
var stage := Story.Stage.CUSTOMER
## The bot dressed in a piece of the player's dress, once it has been.
var dressed: Kart

var _watching := false


## The story's table in [param in_match], at the stage this machine shows; nothing for a table
## where the story is not going on, or for the Final Hand.
static func add_to(in_match: Match) -> StoryTable:
	if Story.final_hand_on or not Story.on_here():
		return null
	var table := StoryTable.new()
	table.name = "StoryTable"
	table.match_node = in_match
	table.stage = Story.stage_here()
	in_match.add_child(table)
	return table


func _process(_delta: float) -> void:
	if match_node == null or match_node.arena == null:
		return
	var player := player_slot(match_node)
	if player == null or player.kart == null:
		return
	if not _watching and match_node.arena.crowd != null:
		_watching = true
		match_node.arena.crowd.watched_by(int(WATCHERS.get(stage, 0)), player.kart)
	if dressed == null and stage >= DRESSED_FROM:
		var bot := a_bot(match_node)
		if bot != null and bot.kart != null:
			dressed = bot.kart
			dress_bot(bot.kart, player.kart.style)
	if _watching and (dressed != null or stage < DRESSED_FROM):
		set_process(false)


## The seat at [param in_match] whose profile is the one playing, the first seat's: whose kart the
## crowd watches and whose dress a bot borrows.
static func player_slot(in_match: Match) -> PlayerSlot:
	for slot: PlayerSlot in in_match.slots:
		if slot.bot_trait == null and MatchRecord.profile_of(slot) == Game.settings.profile:
			return slot
	return null


## The first bot at [param in_match]'s table, or null for a table of people.
static func a_bot(in_match: Match) -> PlayerSlot:
	for slot: PlayerSlot in in_match.slots:
		if slot.bot_trait != null:
			return slot
	return null


## [param bot] drawn in a piece of [param of]'s dress, STORY.md 6.9: the player's hat, or their flag
## if they wear no hat, as the House's models learn them. Only how it is drawn changes, on this
## machine: its own dress is kept as it was, which is what goes over the wire.
static func dress_bot(bot: Kart, of: KartStyle) -> void:
	# The crown is the bounty's, and on a bot would read as a price on its head, GAME.md 4.4.
	var hat := of.hat if of.hat != KartStyle.HATS.find("Crown") else 0
	if hat == 0 and of.flag == 0:
		return
	var own := bot.style
	var borrowed := own.duplicate_style()
	if hat != 0:
		borrowed.hat = hat
	else:
		borrowed.flag = of.flag
	bot.style = borrowed
	KartVisuals.redress(bot, own)
	bot.style = own
