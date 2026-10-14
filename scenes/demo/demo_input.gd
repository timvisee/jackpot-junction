class_name DemoInput
extends PlayerInput
## A seat of the demo for a booth, GAME.md 9.8: a player's at this machine to the HUD, the camera
## and the picks, with a bot at the wheel. Its [BotBrain] writes into [member bot], which polling
## copies, and its picks are worked where everybody sees them, see [DemoPicker].

## The first of the pad ids the demo's seats sit at while their bots drive: past any real pad, so
## nothing anybody holds drives them, and none of them is ever unplugged under its bot.
const NO_PAD := 16

## What its bot writes, copied while the bot has the wheel.
var bot := BotInput.new()
## The way its bot drives, dealt with the run, or null for one drawn as the kart is built.
var bot_trait: BotTrait
## Works the respawn pick and the keep pick the way a player would.
var picker := DemoPicker.new()
## The plate on its kart's back, made up for the run, or the learner's L.
var plate := "L"


func _init(local_seat := 0) -> void:
	super(NO_PAD + local_seat, local_seat)


## Whether [param input] is a seat of the demo with its bot at the wheel.
static func bot_drives(input: KartInput) -> bool:
	return input is DemoInput


func poll(delta: float) -> void:
	copy(bot)
	picker.work(self, _offer(), delta)


## Everything [param from] holds this tick, in place of what this held.
func copy(from: KartInput) -> void:
	steer = from.steer
	cursor = from.cursor
	throttle = from.throttle
	brake = from.brake
	handbrake = from.handbrake
	nitro = from.nitro
	aim = from.aim
	fire = from.fire
	fire_pressed = from.fire_pressed
	use_item_pressed = from.use_item_pressed
	joker_menu = false
	joker_prev_pressed = false
	joker_next_pressed = false
	joker_select = -1
	joker_drop_pressed = false
	joker_destroy_pressed = false
	joker_inspect = -1
	pick_inspect = -1
	emote = -1


## The bot at the wheel of [param slot]'s kart, a seat of the demo, in the way of driving it was
## dealt, or one drawn now. The slot itself stays a player's, with no bot's name or way of driving.
static func drive(match_node: Match, slot: PlayerSlot) -> void:
	var seat := slot.input as DemoInput
	if seat.bot_trait == null:
		seat.bot_trait = match_node.bot_traits.pick(match_node.rng)
	var brain := BotBrain.new()
	brain.name = "Brain"
	brain.setup(slot.kart, match_node, seat.bot_trait, match_node.bot_difficulty, match_node.rng)
	slot.kart.add_child(brain)


## The pick open for this seat, or null.
func _offer() -> JokerOffer:
	if kart == null or not is_instance_valid(kart):
		return null
	var match_node := kart.get_parent() as Match
	if match_node == null or kart.slot < 0 or kart.slot >= match_node.slots.size():
		return null
	var offer := match_node.slots[kart.slot].offer
	return offer if offer != null and not offer.is_done() else null
