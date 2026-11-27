class_name AchievementIcons
extends RefCounted
## Each achievement's own picture, GAME.md 8.10: what it is about, on the inlay of its chip or the
## enamel of its pin, so no two of the list look alike. An SVG drawing of its own in
## assets/icons/achievements, printed by [IconPress] as the jokers' and power-ups' are, GAME.md
## 8.3a: on a chip's cream inlay in two inks, the chip's own color with its shadow side screened
## in a dark one; on the House's pins in gold as a card is; on Kit's pins and on one not earned yet
## in a single flat ink, the paper or the enamel standing in for cream.


## The picture of [param id] into [param box] on [param on], in [param ink] on [param ground],
## with [param paper] for what is cream on paper.
static func draw_into(
	on: CanvasItem,
	box: Rect2,
	id: StringName,
	ink: Color,
	ground := IconPress.Ground.PAPER,
	paper := Color.TRANSPARENT
) -> void:
	if not IconPress.draw(on, box, id, ink, ground, paper):
		IconPress.draw(on, box.grow(-box.size.x * 0.2), &"ui_star", ink, ground, paper)


## Every id this knows a picture for, so a test can hold the set to the list.
static func known() -> Array[StringName]:
	var ids: Array[StringName] = [
		&"street_legal",
		&"honor_roll",
		&"flawless",
		&"beat_the_house",
		&"clean_sweep",
		&"last_kart_standing",
		&"all_in",
		&"by_a_nose",
		&"buzzer_beater",
		&"winner_takes_all",
		&"partners_in_crime",
		&"push_your_luck",
		&"point_of_sale",
		&"hit_the_jackpot",
		&"most_wanted",
		&"snatch_and_grab",
		&"full_house",
		&"let_it_ride",
		&"suit_yourself",
		&"bank_shot",
		&"parry",
		&"long_shot",
		&"payback",
		&"payment_interrupted",
		&"untouchable",
		&"tough_as_nails",
		&"two_birds",
		&"set_and_forget",
		&"road_hog",
		&"slick_operator",
		&"dead_ringer",
		&"long_way_round",
		&"push_comes_to_shove",
		&"a_pit_do_not",
		&"property_damage",
		&"a_real_handful",
		&"stacked",
		&"asking_for_trouble",
		&"full_deck",
		&"toybox",
		&"plus_one",
		&"long_distance",
		&"full_table",
		&"front_row",
		&"dressed_to_the_nines",
		&"know_every_street",
		&"most_valued_member",
		&"lap_of_luxury",
		&"off_the_books",
		&"terms_accepted",
		&"not_this_time",
		&"employee_of_the_month",
		&"under_the_floorboards",
		&"a_fresh_start",
	]
	return ids
