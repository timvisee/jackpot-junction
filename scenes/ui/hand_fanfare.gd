class_name HandFanfare
extends Node
## A hand made or lost, said on the screen of the player whose hand it is, GAME.md 7.3, beside the
## [JokerHand] it belongs to. Made, its name is stamped into the sign with a shine across it, and
## for a Four of a Kind or a Flush to a soft riffle of cards and a bell, higher for the Flush; it is
## called in gold over the hand of cards, on a dark half disc fading up from the screen's edge; and
## the cards that make it light up one after the other, as dealt. Lost, while the kart lives, the
## sign lets it go, struck through and dropping off, and a note in gray says so. Nothing of it is
## seen on the table: a ring of suits round the kart and a column of gold over it were too much
## for a hand, see [SuitBurst].

## Which of these go off, to try them: the stamp, the call, the cards lit, the letting go and the
## note.
const STAMP := true
const CALL := true
const LIGHT := true
const LET_GO := true
const NOTE := true
## The worst hand that sounds, made or lost: Four of a Kind and Flush only.
const SOUNDED := JokerHands.Hand.FOUR_OF_A_KIND
## The call over the hand of cards: how big, how far up off the screen's edge, how much it grows as
## it comes, the dark half disc it stands on, how big and how dark, how far over the cards it is
## drawn, and how long it takes to come, stays and takes to go.
const CALL_SIZE := 46
const CALL_UP := 96.0
const CALL_GROW := 0.35
const CALL_SHADE := Vector2(760.0, 420.0)
const CALL_DARK := 0.88
const CALL_OVER := 60
const CALL_COMES := 0.2
const CALL_STAYS := 1.0
const CALL_GOES := 0.45
## The note: how big, how far it rises, how long it stays and goes, and how it says what was lost.
const NOTE_SIZE := 16
const NOTE_RISE := 14.0
const NOTE_TIME := 1.8
const LOST := "%s lost"
const NOTE_INK := Color(0.72, 0.72, 0.76)

var hand: JokerHand
var _kart: Kart
## The suits the sign showed and its word, before the hand changed, for letting it go.
var _shown: Array[int] = []
var _word := ""


func _process(_delta: float) -> void:
	if hand.kart == _kart:
		return
	if _kart != null and is_instance_valid(_kart) and _kart.jokers != null:
		if _kart.jokers.hands_changed.is_connected(_on_hands_changed):
			_kart.jokers.hands_changed.disconnect(_on_hands_changed)
	_kart = hand.kart
	if _kart != null and _kart.jokers != null:
		_kart.jokers.hands_changed.connect(_on_hands_changed)
		_remember()


func _exit_tree() -> void:
	if _kart != null and is_instance_valid(_kart) and _kart.jokers != null:
		if _kart.jokers.hands_changed.is_connected(_on_hands_changed):
			_kart.jokers.hands_changed.disconnect(_on_hands_changed)


func _on_hands_changed(gained: Array[int], lost: Array[int]) -> void:
	if not gained.is_empty():
		_made(gained.min())
	elif not lost.is_empty() and _kart.alive:
		_lost(lost.min())
	_remember()


func _remember() -> void:
	var made := _kart.jokers.made
	_shown = made.shown.duplicate()
	_word = JokerHands.name_of(made.best()).to_upper() if made.best() >= 0 else ""


## [param made_hand] made: stamped, called, its cards lit, to a riffle and a bell.
func _made(made_hand: int) -> void:
	if STAMP:
		hand._suited.stamp()
	# Heard for the best hands alone: one for every hand made was too much.
	if made_hand <= SOUNDED:
		Audio.play_sfx(&"joker_offer", -14.0)
		var rank := JokerHands.Hand.size() - 1 - made_hand
		Audio.play_sfx(&"slot_bell", -17.0, 0.0, 0.92 + rank * 0.06)
	if CALL:
		_call(JokerHands.name_of(made_hand).to_upper() + "!")
	if LIGHT:
		var jokers := _kart.jokers.jokers
		hand.shine_cards(JokerHands.cards_of(jokers, _kart.jokers.made, made_hand))


## [param lost_hand] lost: the sign lets go of what it showed, and a note says so.
func _lost(lost_hand: int) -> void:
	if LET_GO and not _word.is_empty():
		hand._suited.let_go(_shown, _word)
	if lost_hand <= SOUNDED:
		Audio.play_sfx(&"joker_drop", -16.0, 0.0, 0.85)
	if NOTE:
		_note(LOST % JokerHands.name_of(lost_hand))


## [param words] called in gold over the hand of cards, on a dark half disc that fades up from the
## screen's edge behind the hand, growing in and then going.
func _call(words: String) -> void:
	var held := hand.held_at()
	var edge := hand.size.y if not hand.hangs() else 0.0
	var call := Control.new()
	call.name = "Call"
	call.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Over the cards, which stand in the hand up to one more than there are of them.
	call.z_index = CALL_OVER
	hand.add_child(call)
	var shade := TextureRect.new()
	shade.texture = _shade()
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.size = CALL_SHADE
	shade.position = Vector2(held.x, edge) - CALL_SHADE * 0.5
	call.add_child(shade)
	var called := Label.new()
	called.text = words
	called.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.display(called, CALL_SIZE, Palette.CHIP_GOLD)
	called.add_theme_color_override("font_outline_color", HudText.SHADOW)
	called.add_theme_constant_override("outline_size", 6)
	call.add_child(called)
	var wide := called.get_combined_minimum_size()
	var up := -CALL_UP if not hand.hangs() else CALL_UP
	called.position = Vector2(held.x, edge + up) - wide * 0.5
	called.pivot_offset = wide * 0.5
	called.scale = Vector2.ONE * (1.0 + CALL_GROW)
	call.modulate.a = 0.0
	var show := call.create_tween()
	show.tween_property(call, "modulate:a", 1.0, CALL_COMES)
	show.parallel().tween_property(called, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK)
	show.tween_interval(CALL_STAYS)
	show.tween_property(call, "modulate:a", 0.0, CALL_GOES)
	show.tween_callback(call.queue_free)


## The dark half disc the call stands on: black in its middle, fading out to nothing at its rim.
static func _shade() -> GradientTexture2D:
	var fade := GradientTexture2D.new()
	fade.fill = GradientTexture2D.FILL_RADIAL
	fade.fill_from = Vector2(0.5, 0.5)
	fade.fill_to = Vector2(1.0, 0.5)
	fade.width = 256
	fade.height = 128
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.0, 0.0, 0.0, CALL_DARK))
	ramp.set_color(1, Color(0.0, 0.0, 0.0, 0.0))
	ramp.add_point(0.6, Color(0.0, 0.0, 0.0, CALL_DARK * 0.8))
	fade.gradient = ramp
	return fade


## [param words] in gray over the sign, rising and going.
func _note(words: String) -> void:
	var note := Label.new()
	note.text = words
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.strong(note, NOTE_SIZE, NOTE_INK)
	HudText.shadowed(note, 2)
	hand.add_child(note)
	var at := hand._suited.position + Vector2(0.0, -NOTE_SIZE - 10.0)
	if hand.hangs():
		at = hand._suited.position + Vector2(0.0, hand._suited.size.y + 6.0)
	note.position = at
	var show := note.create_tween().set_parallel()
	show.tween_property(note, "position:y", at.y - NOTE_RISE, NOTE_TIME)
	show.tween_property(note, "modulate:a", 0.0, NOTE_TIME).set_ease(Tween.EASE_IN)
	show.chain().tween_callback(note.queue_free)
