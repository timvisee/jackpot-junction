class_name HandFanfare
extends Node
## A hand made or lost, said on the screen of the player whose hand it is, GAME.md 7.3, beside the
## [JokerHand] it belongs to. Made, its name is stamped into the sign with a shine across it to a
## riffle of cards and a bell, higher for a better hand; it is called in gold under the player's
## corner; and the cards that make it light up one after the other, as dealt. Lost, while the kart
## lives, the sign lets it go, struck through and dropping off, and a note in gray says so. The
## table sees a hand made too, see [HandFlare].

## Which of these go off, to try them: the stamp, the call, the cards lit, the letting go and the
## note.
const STAMP := true
const CALL := true
const LIGHT := true
const LET_GO := true
const NOTE := true
## The call: how big, how far under the corner, how much it grows as it comes, and how long it
## stays and takes to go.
const CALL_SIZE := 40
const CALL_UNDER := 10.0
const CALL_GROW := 0.4
const CALL_STAYS := 1.0
const CALL_GOES := 0.4
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
	Audio.play_sfx(&"joker_offer", -8.0)
	var rank := JokerHands.Hand.size() - 1 - made_hand
	Audio.play_sfx(&"slot_bell", -12.0, 0.0, 0.92 + rank * 0.06)
	if CALL:
		_call(JokerHands.name_of(made_hand).to_upper() + "!")
	if LIGHT:
		var jokers := _kart.jokers.jokers
		hand.shine_cards(JokerHands.cards_of(jokers, _kart.jokers.made, made_hand))


## [param lost_hand] lost: the sign lets go of what it showed, and a note says so.
func _lost(lost_hand: int) -> void:
	if LET_GO and not _word.is_empty():
		hand._suited.let_go(_shown, _word)
	Audio.play_sfx(&"joker_drop", -12.0, 0.0, 0.85)
	if NOTE:
		_note(LOST % JokerHands.name_of(lost_hand))


## [param words] called in gold under the player's corner, growing in and then going.
func _call(words: String) -> void:
	var hud := hand.get_parent() as MatchHud
	var parts := hud.block_parts(_kart.slot) if hud != null else {}
	var box: Control = parts.get("box")
	if box == null or not is_instance_valid(box):
		return
	# Under the corner and the hints hung off it.
	var under := box.get_global_rect()
	var hints: Control = parts.get("hints")
	if hints != null and is_instance_valid(hints) and hints.is_visible_in_tree():
		under = under.merge(hints.get_global_rect())
	var called := Label.new()
	called.text = words
	called.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.display(called, CALL_SIZE, Palette.CHIP_GOLD)
	called.add_theme_color_override("font_outline_color", HudText.SHADOW)
	called.add_theme_constant_override("outline_size", 6)
	hud.add_child(called)
	called.global_position = Vector2(under.position.x, under.end.y + CALL_UNDER)
	called.pivot_offset = called.get_combined_minimum_size() * Vector2(0.0, 0.5)
	called.scale = Vector2.ONE * (1.0 + CALL_GROW)
	var show := called.create_tween()
	show.tween_property(called, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
	show.tween_interval(CALL_STAYS)
	show.tween_property(called, "modulate:a", 0.0, CALL_GOES)
	show.tween_callback(called.queue_free)


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
