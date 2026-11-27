class_name SoundLibrary
extends RefCounted
## Every sound effect the game plays by name, GAME.md 8.4, and the files each picks from at random,
## for [Audio] to play. A name with a slash is under [constant Audio.AUDIO_DIR], anything else under
## [constant Audio.SFX_DIR]. Every file is logged in THIRD_PARTY.md.

const EFFECTS: Dictionary[StringName, Array] = {
	&"chip": ["chip-lay-1.ogg", "chip-lay-2.ogg", "chip-lay-3.ogg"],
	&"gold_chip": ["chips-stack-1.ogg", "chips-stack-2.ogg"],
	&"chips_scatter": ["chips-collide-1.ogg", "chips-collide-2.ogg"],
	&"die": ["dice-throw-1.ogg", "dice-throw-2.ogg", "dice-throw-3.ogg"],
	&"mult": ["pluck_001.ogg", "pluck_002.ogg"],
	&"graze": ["glass_001.ogg", "glass_002.ogg", "glass_003.ogg"],
	&"fire": ["drop_001.ogg", "drop_002.ogg"],
	&"dry_fire": ["click_002.ogg"],
	&"bounce":
	["impactMetal_light_000.ogg", "impactMetal_light_001.ogg", "impactMetal_light_002.ogg"],
	&"bump": ["kart/crash_1.ogg", "kart/crash_2.ogg"],
	&"crash": ["kart/crash_1.ogg", "kart/crash_2.ogg", "kart/crash_3.ogg"],
	&"crash_hard": ["kart/crash_heavy.ogg"],
	&"death": ["impactGlass_heavy_000.ogg", "impactGlass_heavy_001.ogg"],
	&"fall": ["back_001.ogg"],
	&"crate": ["impactPlate_light_000.ogg", "impactPlate_light_001.ogg"],
	&"turbo": ["maximize_001.ogg", "maximize_002.ogg"],
	&"bank_tick": ["tick_001.ogg", "tick_002.ogg"],
	&"bank_done": ["confirmation_002.ogg"],
	&"fanfare": ["bong_001.ogg", "confirmation_001.ogg"],
	&"death_bank": ["back_001.ogg"],
	&"jackpot_full": ["bong_001.ogg"],
	&"item_pick": ["open_001.ogg"],
	&"item_use": ["switch_001.ogg"],
	&"joker_offer": ["card-fan-1.ogg"],
	&"joker_take": ["card-place-1.ogg", "card-place-2.ogg"],
	&"joker_drop": ["card-shove-1.ogg"],
	&"countdown": ["kart/start_tone_low.ogg"],
	&"go": ["kart/start_tone_high.ogg"],
	&"last_call": ["error_001.ogg"],
	&"results": ["bong_001.ogg", "chips-handle-1.ogg"],
	&"ui_click": ["click_001.ogg"],
	&"ui_move": ["tick_001.ogg"],
	&"ui_back": ["back_001.ogg"],
	&"shield_pop": ["impactBell_heavy_000.ogg"],
	&"turret_place": ["impactSoft_heavy_000.ogg"],
	&"explosion": ["impactPunch_heavy_000.ogg"],
	&"pad_claim": ["select_001.ogg"],
	# The waiting room's pad, GAME.md 9.6: a soft tick per block of the charge, a chime once ready.
	&"ready_charge": ["tick_002.ogg"],
	&"ready": ["confirmation_001.ogg"],
	# Its football: a soft thump off a kart, and a knock off a wall, a prop or a shot.
	&"ball_kick":
	[
		"impactSoft_medium_000.ogg",
		"impactSoft_medium_001.ogg",
		"impactSoft_medium_002.ogg",
		"impactSoft_medium_003.ogg",
		"impactSoft_medium_004.ogg",
	],
	&"ball_knock":
	[
		"impactGeneric_light_000.ogg",
		"impactGeneric_light_001.ogg",
		"impactGeneric_light_002.ogg",
		"impactGeneric_light_003.ogg",
		"impactGeneric_light_004.ogg",
	],
	&"oil": ["kart/spin_out.ogg"],
	&"bounty": ["question_001.ogg"],
	&"target": ["select_002.ogg"],
	&"wounded": ["impactPunch_heavy_000.ogg"],
	&"patched": ["confirmation_002.ogg"],
	&"explosion_tail": ["impactSoft_heavy_001.ogg"],
	&"firework": ["impactSoft_heavy_001.ogg", "impactPunch_heavy_000.ogg"],
	&"turbo_pass": ["kart/turbo_pass.ogg"],
	# A pop bumper firing, GAME.md 6.2: its ring's knock under a wall-bounce, a pinball bell over it.
	&"bumper_knock":
	["impactMetal_light_000.ogg", "impactMetal_light_001.ogg", "impactMetal_light_002.ogg"],
	&"bumper_bell": ["impactBell_heavy_000.ogg"],
	# A live cabinet's zap, GAME.md 6.2: the arc, the current's buzz, the pop, tools/make_zap_sound.
	&"zap": ["zap.ogg"],
	# A live cabinet coming live: a small snap and a buzz falling away, quiet, a map's detail.
	&"cabinet_live": ["cabinet_live.ogg"],
	# A sewing machine's needle on a kart, GAME.md 6.2: a light metal knock under the tires letting go.
	&"needle":
	["impactMetal_light_000.ogg", "impactMetal_light_001.ogg", "impactMetal_light_002.ogg"],
	# The driving school, GAME.md 9.4a: a page of the theory book, the book shutting, the stamp struck.
	&"page": ["card-shove-1.ogg", "card-place-2.ogg"],
	# A card of the table turned over on its felt, GAME.md 9.6: put down face up or face down.
	&"card_flip": ["card-place-1.ogg", "card-place-2.ogg"],
	&"book": ["impactPlate_light_000.ogg"],
	&"stamp": ["impactPunch_heavy_000.ogg"],
	# A note of Kit's off the table, STORY.md 7.1: paper rustling, a pencil's NOTE COLLECTED scratch.
	&"note": ["bookFlip2.ogg"],
	&"pencil": ["pencil-scratch.wav"],
	# Kit's folder, STORY.md 7.2: opening, shutting, a leaf turning and a note put back.
	&"folder_open": ["bookOpen.ogg"],
	&"folder_shut": ["bookClose.ogg"],
	&"leaf": ["bookFlip1.ogg", "bookFlip2.ogg", "bookFlip3.ogg"],
	&"note_down": ["bookPlace1.ogg"],
	# The Final Hand's golden ticket, STORY.md 8.1: ADMIT ONE torn off at the door.
	&"tear": ["paper-tear.wav"],
	&"nitro_swell": ["kart/nitro_swell.ogg"],
	# An achievement, GAME.md 8.10: a bell run over a few chips, see tools/make_achievement_sound.
	&"achievement": ["achievement.ogg"],
	# A slot machine paying, GAME.md 3.15: three sevens and a void pull, see tools/make_slot_sounds.
	&"slot_bell": ["slot_bell.ogg"],
	&"slot_jackpot": ["slot_jackpot.ogg"],
	&"slot_void": ["slot_void.ogg"],
	# The name die thrown, GAME.md 4.4a and 9.6: one die landing on a table three times, timed to
	# the die drawn hopping, see tools/make_die_sound and [NameDie].
	&"die_throw": ["die_throw_1.ogg", "die_throw_2.ogg", "die_throw_3.ogg"],
	# The kart dialog's shuffle, GAME.md 4.4a: its push button pushed, a tick for each face of its
	# die going by as it spins, and a clack where it lands, see tools/make_die_sound and [PartHook].
	&"shuffle_roll": ["shuffle_roll_1.ogg", "shuffle_roll_2.ogg", "shuffle_roll_3.ogg"],
}
