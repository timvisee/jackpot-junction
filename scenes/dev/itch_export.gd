extends "res://scenes/dev/key_art.gd"
## Renders the pictures the game's page on itch.io wears, docs/ITCH.md, into build/itch and quits,
## which is what `make itch-art` runs: the cover, a shot of the Vault with karts drifting round its
## Junction under the seal and the name, and the page's background, what is behind the title screen,
## dark on purpose so the page's words stay what it is about. Both are the game's own pieces, see
## key_art.gd, so they follow the game as it changes.

const OUT := "res://build/itch"
## itch.io's own size for a cover, drawn this many times over and scaled down so its edges are
## smooth.
const COVER := Vector2i(630, 500)
const OVER := 2
## The background: wide enough for a wide screen, its middle under the page's column. A JPEG, since
## the engraving's fine lines make a PNG of it bigger than itch.io takes; at this quality they hold.
const BACKGROUND := Vector2i(2560, 1440)
const BACKGROUND_QUALITY := 0.9

## The cover's camera: where it is and what it looks at.
const COVER_EYE := Vector3(-0.6, 5.5, 10.8)
const COVER_AT := Vector3(-0.6, 0.6, 0.6)
const COVER_FOV := 42.0
## Where the title's sunburst is centered on the background, as a share of it: high, so its beams
## and rings fan out round the top of the page's column. And how big the mark it is centered on
## would be, which sets where its rays start.
const TITLE_FOCUS := Vector2(0.5, 0.2)
const TITLE_MARK := 360.0

## The seal and the name over the cover's top, as the title sets them, on a band of the house's
## stock fading into the room: in pixels of the cover, before it is drawn over.
const MARK := 140
const NAME_SIZE := 76
const LOCKUP_GAP := 18
const LOCKUP_TOP := 18
const BAND := 0.6
const BAND_INK := 0.92
## Where down the band it starts to fade, and how dark it still is there.
const BAND_HOLD := 0.45
const BAND_HELD := 0.7


func _ready() -> void:
	make_out(OUT)
	save(await _cover(), OUT + "/cover.png", COVER)
	save(
		await backdrop(BACKGROUND, TITLE_FOCUS, TITLE_MARK),
		OUT + "/background.jpg",
		BACKGROUND,
		BACKGROUND_QUALITY
	)
	get_tree().quit()


## The Vault with the karts round its Junction, the seal and the name over it.
func _cover() -> Image:
	var size := COVER * OVER
	var world := stage(size)
	var viewport: SubViewport = world["viewport"]
	look(world, COVER_EYE, COVER_AT, COVER_FOV)
	put_table(world)
	var shade := band(BAND_INK, BAND_HOLD, BAND_HELD)
	shade.size = Vector2(size.x, size.y * BAND)
	viewport.add_child(shade)
	var row := lockup(MARK * OVER, NAME_SIZE * OVER, LOCKUP_GAP * OVER)
	row.size = Vector2(size.x, MARK * OVER)
	row.position = Vector2(0.0, LOCKUP_TOP * OVER)
	viewport.add_child(row)
	var image := await taken(viewport, DRIVE_FRAMES)
	park()
	return image
