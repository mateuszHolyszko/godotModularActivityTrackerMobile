extends Resource
class_name Exercise

@export var name: String = ""
@export var note: String = ""
"""
Note on var note: String
it differs from the rest of the fields in that its meant to be edited in session section not in exercise section
in that its more similar to exercise_entry but i decided to put it here, because i have no need for history of notes,
so storing one node in each entry would be redundant
"""
@export var target_muscle: String = ""
@export var bodyweight: bool = false
@export var rep_range: Vector2i = Vector2i()

func to_dict() -> Dictionary:
	return {
		"name": name,
		"note": note,
		"target_muscle": target_muscle,
		"bodyweight": bodyweight,
		"rep_range": [rep_range.x, rep_range.y],
	}

static func from_dict(d: Dictionary) -> Exercise:
	var e := Exercise.new()
	e.name = str(d.get("name", ""))
	e.note = str(d.get("note", ""))
	e.target_muscle = str(d.get("target_muscle", ""))
	e.bodyweight = bool(d.get("bodyweight", false))
	var rr = d.get("rep_range", [0, 0])
	if typeof(rr) == TYPE_ARRAY and rr.size() >= 2:
		e.rep_range = Vector2i(int(rr[0]), int(rr[1]))
	else:
		e.rep_range = Vector2i()

	# Validate target_muscle against autoloaded MuscleDict, if available
	# MuscleDict.MUSCLE_COLORS is expected to be a Dictionary of muscle -> color
	if e.target_muscle != "" and e.target_muscle not in MuscleDict.MUSCLE_COLORS.keys():
		push_error("Exercise.from_dict: invalid target_muscle '%s'" % e.target_muscle)
		e.target_muscle = ""

	return e
