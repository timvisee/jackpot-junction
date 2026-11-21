class_name SupporterTrails
extends RefCounted
## The supporter pack's trails, GAME.md 10.8, beside the rest of what a kart leaves behind it, see
## [ExhaustSmoke]: the Prism, a ribbon of its own, see [PrismRibbon]; and its picture on the kart
## dialog's rack.


## The picture of the pack's trail called [param named] in [param box] on [param on], for the kart
## dialog: the prism a band of the spectrum swept round in an arc.
static func trail_icon(on: CanvasItem, box: Rect2, named: String) -> void:
	var middle := box.get_center()
	var side := minf(box.size.x, box.size.y)
	match named:
		"Prism":
			var bands := PrismRibbon.BANDS
			for band: int in bands.size():
				var reach := side * (0.42 - 0.035 * float(band))
				on.draw_arc(
					middle + Vector2(0.0, side * 0.3),
					reach,
					PI * 1.08,
					PI * 1.92,
					32,
					Color(bands[band], 0.9),
					side * 0.036,
					true
				)
