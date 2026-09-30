class_name FrameGroups
extends RefCounted
## Groups asked about many times a frame, read off the tree once a frame and shared, GAME.md 10.7:
## the karts, which every bot looks for up to four times a tick and every turret and bullet once,
## and the targets aim assist chooses among. Asking the tree walks the whole group and builds a
## new array every time.
##
## Per drawn frame, since a node freed at the end of one frame is gone by the next. One freed in
## the middle of a frame is still listed until then, so whatever reads a group checks that each
## member is alive, and one that joins in the middle of a frame is listed from the next.

static var _read_at: Dictionary[StringName, int] = {}
static var _members: Dictionary[StringName, Array] = {}


## The nodes in [param group] in [param tree], as of this frame.
static func of(tree: SceneTree, group: StringName) -> Array[Node]:
	var frame := Engine.get_process_frames()
	if _read_at.get(group, -1) != frame:
		_read_at[group] = frame
		_members[group] = tree.get_nodes_in_group(group)
	return _members[group]
