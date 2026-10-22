extends Control
## Dev harness for the README's two posed UI shots, see tools/screenshots: the House's opening
## invitation and the Your kart dialog, each mounted on the throwaway profile this runs under with
## `++ --shot=<invitation|kart>`. The Game autoload's `--screenshot` grabs it, oversampled, as the
## gameplay shots are grabbed through the playground. Nothing here ships: it dresses a test profile
## and shows a screen the game already has.


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	MenuTheme.background(self)
	if _shot() == "invitation":
		# Shown all at once, as a press brings it, rather than played in from the dark.
		OpeningInvitation.over(self, Game.settings.profile).come_on_now()
	else:
		_kart()


## The `--shot=` asked for, the kart dialog by default.
func _shot() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			return arg.get_slice("=", 1)
	return "kart"


## The Your kart dialog on a profile that has won every piece of dress, GAME.md 8.9, in the set the
## README shows: racing stripes, a top hat, the checkered flag and confetti, on the racer, in blue.
func _kart() -> void:
	var profile := Game.settings.profile
	for landmark: LoyaltyLandmark in Loyalty.map().landmarks:
		profile.loyalty.win(landmark.id)
	Loyalty.settle(profile)
	Game.settings.set_seat_color(0, 1)
	Game.settings.set_seat_style(0, PackedInt32Array([5, 2, 3, 2, 0, 0, 0]))
	KartDialog.open(self)
