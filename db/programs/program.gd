extends Resource
class_name Program

@export var program_name: String = ""

# Ordered list of entries. Each entry is a Dictionary:
#   {"type": "exercise", "exercise_name": String}
#   {"type": "superset", "exercise_names": Array[String]}
var items: Array = []

func add_exercise(exercise_name: String) -> void:
	items.append({"type": "exercise", "exercise_name": exercise_name})

func add_superset(exercise_names: Array) -> void:
	items.append({"type": "superset", "exercise_names": exercise_names.duplicate()})

func insert_exercise_at(index: int, exercise_name: String) -> void:
	items.insert(index, {"type": "exercise", "exercise_name": exercise_name})

func insert_superset_at(index: int, exercise_names: Array) -> void:
	items.insert(index, {"type": "superset", "exercise_names": exercise_names.duplicate()})

func remove_item_at(index: int) -> void:
	if index < 0 or index >= items.size():
		return
	items.remove_at(index)

func move_item(from_index: int, to_index: int) -> void:
	if from_index < 0 or from_index >= items.size():
		return
	if to_index < 0 or to_index >= items.size():
		return
	var item = items[from_index]
	items.remove_at(from_index)
	items.insert(to_index, item)

## Resolves item entries into actual Exercise objects using the given ExerciseManager.
## Returns Array of Dictionaries:
##   {"type": "exercise", "exercise": Exercise}
##   {"type": "superset", "exercises": Array[Exercise]}
## Any referenced exercise that no longer exists is skipped (with a push_error).
func resolve(exercise_manager) -> Array:
	var resolved: Array = []
	for item in items:
		if item.get("type") == "exercise":
			var ex = exercise_manager.get_exercise(item.get("exercise_name", ""))
			if ex:
				resolved.append({"type": "exercise", "exercise": ex})
			else:
				push_error("Program.resolve: exercise '%s' not found" % item.get("exercise_name", ""))
		elif item.get("type") == "superset":
			var superset_exercises: Array = []
			for ex_name in item.get("exercise_names", []):
				var ex = exercise_manager.get_exercise(ex_name)
				if ex:
					superset_exercises.append(ex)
				else:
					push_error("Program.resolve: exercise '%s' not found (in superset)" % ex_name)
			resolved.append({"type": "superset", "exercises": superset_exercises})
	return resolved

func to_dict() -> Dictionary:
	var serialized_items: Array = []
	for item in items:
		if item.get("type") == "exercise":
			serialized_items.append({
				"type": "exercise",
				"exercise_name": item.get("exercise_name", ""),
			})
		elif item.get("type") == "superset":
			serialized_items.append({
				"type": "superset",
				"exercise_names": item.get("exercise_names", []).duplicate(),
			})
	return {
		"program_name": program_name,
		"items": serialized_items,
	}

static func from_dict(d: Dictionary) -> Program:
	var p := Program.new()
	p.program_name = str(d.get("program_name", ""))

	var raw_items = d.get("items", [])
	if typeof(raw_items) != TYPE_ARRAY:
		return p

	for raw_item in raw_items:
		if typeof(raw_item) != TYPE_DICTIONARY:
			continue
		var type := str(raw_item.get("type", ""))
		if type == "exercise":
			p.items.append({
				"type": "exercise",
				"exercise_name": str(raw_item.get("exercise_name", "")),
			})
		elif type == "superset":
			var names: Array = []
			var raw_names = raw_item.get("exercise_names", [])
			if typeof(raw_names) == TYPE_ARRAY:
				for n in raw_names:
					names.append(str(n))
			p.items.append({
				"type": "superset",
				"exercise_names": names,
			})
		else:
			push_error("Program.from_dict: unknown item type '%s'" % type)
	return p
