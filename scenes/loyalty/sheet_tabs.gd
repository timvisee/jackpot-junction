class_name SheetTabs
extends TabBar
## The loyalty map's sheets as index tabs on its well's top edge, as the settings' pages are on
## theirs, GAME.md 8.5 and 8.9: the House's map and Kit's, see [LoyaltyMapLayout.Sheet], there once
## Kit's is on it. Each wears NEW while a landmark won on its sheet has not been looked at yet, as
## the catalog's tabs do for their pages, see [TabTags].

const HOUSE := "The House's map"
const KIT := "Kit's map"

## Each sheet's NEW tag.
var tags: TabTags


## The tabs of [param profile]'s map, tagged as its landmarks are.
static func of(profile: Profile) -> SheetTabs:
	var bar := SheetTabs.new()
	bar.name = "Sheets"
	bar.add_tab(HOUSE)
	bar.add_tab(KIT)
	bar.tab_alignment = TabBar.ALIGNMENT_LEFT
	bar.focus_mode = Control.FOCUS_NONE
	bar.clip_tabs = false
	MenuTheme.tabs(bar)
	AtlasTicketStyle.dress_tabs(bar, 16.0 if TouchInput.enabled else 11.0)
	bar.visible = Loyalty.district_open(profile, LoyaltyLandmark.District.OFF_THE_BOOKS)
	bar.tags = TabTags.on(bar)
	bar.tag(profile)
	return bar


## Each sheet's tab wears NEW while a landmark won on it and drawn on it has not been looked at, as
## the landmark itself does, see [method Loyalty.has_fresh].
func tag(profile: Profile) -> void:
	var fresh: Array[bool] = [false, false]
	for id: String in profile.loyalty.fresh:
		var landmark := Loyalty.map().landmark(StringName(id))
		if landmark != null and Loyalty.is_drawn(profile, landmark):
			fresh[LoyaltyMapLayout.sheet_of(landmark)] = true
	tags.wear(fresh)
