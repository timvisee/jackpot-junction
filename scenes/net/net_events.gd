class_name NetEvents
extends RefCounted
## Which of the [Events] a host says again to its clients, GAME.md 10.3, and which stay on the
## machine that raised them. Kept apart from [NetSession] so that file stays about the connection.
## Between the two lists every signal [Events] has is accounted for, and a test says so.

## The events a host relays to every client, as they happen.
const RELAYED: Array[StringName] = [
	&"player_kicked",
	&"coin_collected",
	&"mult_gained",
	&"grazed",
	&"kill_detailed",
	&"kart_killed",
	&"decoy_destroyed",
	&"kart_respawned",
	&"death_banked",
	&"bank_started",
	&"bank_tick",
	&"bank_completed",
	&"jackpot_collected",
	&"jackpot_full",
	&"jackpot_emptied",
	&"slot_spun",
	&"slot_paid",
	&"item_picked",
	&"item_used",
	&"joker_offered",
	&"joker_taken",
	&"match_state_changed",
	&"bullet_fired",
	&"bullet_bounced",
	&"bullet_struck",
	&"bullet_deflected",
	&"kart_bumped",
	&"turbo_taken",
	&"nitro_gained",
	&"pad_claimed",
	&"flush_completed",
	&"bounty_called",
	&"bounty_claimed",
	&"bounty_lapsed",
	&"kart_wounded",
	&"life_restored",
	&"joker_went_off",
	&"joker_used_up",
	&"crate_destroyed",
	&"target_struck",
	&"shield_popped",
	&"bomb_exploded",
	&"oil_hit",
	&"player_joined",
	&"team_joined",
	&"player_ready",
	&"match_planned",
	&"room_planned",
	&"grand_prix_scored",
	&"player_left",
	&"countdown_tick",
	&"countdown_done",
	&"kart_crashed",
	&"kart_fell",
	&"nitro_started",
	&"drift_boosted",
	&"kart_dressed",
	&"emoted",
	&"watcher_emoted",
	&"bullets_met",
]
## The events that stay on the machine that raised them. Between this and [constant
## RELAYED] every signal [Events] has is accounted for, and a test says so, so a new one
## has to be put in one list or the other rather than quietly never reaching a client.
##
## [code]announced[/code] is made on each machine by its own announcer, out of the events above,
## so relaying it would say everything twice. [code]wild_joker_dropped[/code] has nothing
## listening to it on any machine; the card it names arrives as a pickup like any other.
## [code]kart_corrected[/code] is about this machine's own guess being put right, which is news
## to nobody else: their picture of that kart never changed. [code]kart_shot[/code] is counted
## by the host alone, and the counts reach everybody in the snapshot. [code]room_building[/code] is
## this machine's own loading screen, and each machine puts its rooms up by itself.
## [code]joker_answered[/code], [code]joker_destroyed[/code] and [code]joker_left[/code] are a
## player's own doing, heard where they did it, a client's own pick and menu included, for that
## machine's loyalty program alone, GAME.md 8.9. [code]cannon_jammed[/code] is for a player at
## the machine alone, and a client hears its own from the host's count of shots refused, see
## [method KartPrediction.hear]. [code]achievement_earned[/code] and [code]watched_emote[/code]
## are this machine's own profiles', each machine counting its own, GAME.md 8.10.
const LOCAL: Array[StringName] = [
	&"announced",
	&"wild_joker_dropped",
	&"kart_corrected",
	&"kart_shot",
	&"room_building",
	&"joker_answered",
	&"joker_destroyed",
	&"joker_left",
	&"cannon_jammed",
	&"achievement_earned",
	&"watched_emote",
]
