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

# --- Optional fields (all default to "empty" so old saved data stays compatible) ---

## Secondary muscles hit by this exercise, mapped to how much they're involved.
## Dictionary shape: { muscle_name: String -> fraction: float (0.0 - 1.0) }
## Can contain any number of entries (including zero).
@export var secondary_targets: Dictionary = {}

## Equipment/modality used for the exercise. One of MODALITIES, or "" for "unset".
@export var modality: String = ""

## Freeform-ish exercise modifiers. At most ONE value per category (see MODIFIER_CATEGORIES),
## but any subset of categories may be represented (including none).
## Stored flat, e.g. ["incline", "unilateral"].
@export var modifiers: Array[String] = []

const MODALITIES: Array[String] = [
	"barbell", "dumbbell", "kettlebell", "machines", "cable", "calisthenics", "bands"
]

## category name -> allowed values. At most one value per category may be present
## in `modifiers` at a time.
const MODIFIER_CATEGORIES: Dictionary = {
	"posture": ["flat", "incline", "decline"],
	"involvement": ["unilateral", "bilateral"],
	"foot_placement": ["feet_elevated", "feet_wide", "feet_narrow"],
}

## Returns the category a modifier value belongs to, or "" if it isn't a recognized value.
static func get_modifier_category(value: String) -> String:
	for category in MODIFIER_CATEGORIES.keys():
		if value in MODIFIER_CATEGORIES[category]:
			return category
	return ""

## Sets/replaces this exercise's modifier for `value`'s category (removing any previous
## modifier from that same category). Returns true on success.
func set_modifier(value: String) -> bool:
	var category := get_modifier_category(value)
	if category == "":
		push_error("Exercise.set_modifier: invalid modifier value '%s'" % value)
		return false

	for existing in modifiers.duplicate():
		if get_modifier_category(existing) == category:
			modifiers.erase(existing)

	modifiers.append(value)
	return true

## Removes whatever modifier (if any) is set for `category`.
func clear_modifier_category(category: String) -> void:
	for existing in modifiers.duplicate():
		if get_modifier_category(existing) == category:
			modifiers.erase(existing)

## Returns the modifier currently set for `category`, or "" if none.
func get_modifier_for_category(category: String) -> String:
	for existing in modifiers:
		if get_modifier_category(existing) == category:
			return existing
	return ""

## Adds/updates a secondary target muscle with the given fraction (clamped to 0-1).
func set_secondary_target(muscle: String, fraction: float) -> bool:
	if muscle == "" or muscle not in MuscleDict.MUSCLE_COLORS.keys():
		push_error("Exercise.set_secondary_target: invalid muscle '%s'" % muscle)
		return false
	secondary_targets[muscle] = clampf(fraction, 0.0, 1.0)
	return true

func remove_secondary_target(muscle: String) -> void:
	secondary_targets.erase(muscle)

func to_dict() -> Dictionary:
	return {
		"name": name,
		"note": note,
		"target_muscle": target_muscle,
		"bodyweight": bodyweight,
		"rep_range": [rep_range.x, rep_range.y],
		"secondary_targets": secondary_targets,
		"modality": modality,
		"modifiers": modifiers,
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

	# --- secondary_targets: optional, defaults to {} for old data ---
	e.secondary_targets = {}
	var st = d.get("secondary_targets", {})
	if typeof(st) == TYPE_DICTIONARY:
		for muscle in st.keys():
			var muscle_name := str(muscle)
			if muscle_name not in MuscleDict.MUSCLE_COLORS.keys():
				push_error("Exercise.from_dict: invalid secondary target muscle '%s'" % muscle_name)
				continue
			e.secondary_targets[muscle_name] = clampf(float(st[muscle]), 0.0, 1.0)

	# --- modality: optional, defaults to "" for old data ---
	e.modality = str(d.get("modality", ""))
	if e.modality != "" and e.modality not in MODALITIES:
		push_error("Exercise.from_dict: invalid modality '%s'" % e.modality)
		e.modality = ""

	# --- modifiers: optional, defaults to [] for old data ---
	e.modifiers = []
	var mods = d.get("modifiers", [])
	if typeof(mods) == TYPE_ARRAY:
		var seen_categories := {}
		for raw in mods:
			var value := str(raw)
			var category := get_modifier_category(value)
			if category == "":
				push_error("Exercise.from_dict: invalid modifier '%s'" % value)
				continue
			if seen_categories.has(category):
				push_error("Exercise.from_dict: multiple modifiers for category '%s', keeping first" % category)
				continue
			seen_categories[category] = true
			e.modifiers.append(value)

	return e
