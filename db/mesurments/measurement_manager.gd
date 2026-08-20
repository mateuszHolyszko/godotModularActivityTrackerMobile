class_name MeasurementManager
extends RefCounted

const FILE_EXTENSION := ".json"
const DATE_FORMAT := "%04d-%02d-%02d"
const VALID_TYPES := ["arms", "chest", "waist", "thigh", "weight"]

var items: Array[MeasurementEntry] = []
var base_directory: String = ""
var measurements_directory: String = ""

func setup(base_dir: String) -> void:
	base_directory = base_dir
	measurements_directory = base_dir + "measurements/"
	
	# Create the measurements directory if it doesn't exist
	var dir := DirAccess.open(base_directory)
	if dir and not dir.dir_exists("measurements"):
		dir.make_dir("measurements")

func load() -> void:
	items.clear()
	
	var dir := DirAccess.open(measurements_directory)
	if not dir:
		push_error("MeasurementManager: failed to open directory %s" % measurements_directory)
		return
	
	# List all JSON files in the directory
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(FILE_EXTENSION):
			var file_path := measurements_directory + file_name
			var entry := load_entry_file(file_path)
			if entry:
				items.append(entry)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# Sort by timestamp (oldest first)
	items.sort_custom(func(a, b): return a.timestamp < b.timestamp)

func load_entry_file(file_path: String) -> MeasurementEntry:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("MeasurementManager: failed to read %s" % file_path)
		return null
	
	var text := file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		var entry := MeasurementEntry.from_dict(parsed)
		if not entry:
			push_error("MeasurementManager: malformed entry data in %s" % file_path)
		return entry
	else:
		push_error("MeasurementManager: invalid measurement data in %s" % file_path)
		return null

func save_entry_file(entry: MeasurementEntry) -> void:
	var file_path := get_file_path_for_entry(entry)
	
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(entry.to_dict(), "\t"))
		file.close()
	else:
		push_error("MeasurementManager: failed to write %s (err %d)" % [file_path, FileAccess.get_open_error()])

func get_file_path_for_entry(entry: MeasurementEntry) -> String:
	var dt := Time.get_datetime_dict_from_unix_time(entry.timestamp)
	var date_str := DATE_FORMAT % [dt.year, dt.month, dt.day]
	# type + timestamp keeps entries of different types on the same day from colliding,
	# and keeps multiple same-type entries on the same day unique too.
	return measurements_directory + date_str + "_" + entry.type + "_" + str(entry.timestamp) + FILE_EXTENSION

func _is_same_calendar_day(ts_a: int, ts_b: int) -> bool:
	var a := Time.get_datetime_dict_from_unix_time(ts_a)
	var b := Time.get_datetime_dict_from_unix_time(ts_b)
	return a.year == b.year and a.month == b.month and a.day == b.day

## Add a single atomic measurement (e.g. just "weight") without touching any other type.
## Any existing entry of the SAME type on the SAME calendar day is replaced.
func add_entry(measurement_type: String, value: float, timestamp: int = -1) -> void:
	var type_key := measurement_type.to_lower()
	if type_key not in VALID_TYPES:
		push_error("MeasurementManager: Invalid measurement type '%s'" % measurement_type)
		return
	
	if timestamp < 0:
		timestamp = Time.get_unix_time_from_system()
	
	# Remove any existing entry of this same type on this same calendar day.
	for i in range(items.size() - 1, -1, -1):
		var existing := items[i]
		if existing.type == type_key and _is_same_calendar_day(existing.timestamp, timestamp):
			var old_file_path := get_file_path_for_entry(existing)
			if FileAccess.file_exists(old_file_path):
				var dir := DirAccess.open(measurements_directory)
				if dir:
					dir.remove(old_file_path.get_file())
			items.remove_at(i)
	
	var entry := MeasurementEntry.create(type_key, value, timestamp)
	items.append(entry)
	save_entry_file(entry)
	
	items.sort_custom(func(a, b): return a.timestamp < b.timestamp)

func remove_at(index: int) -> void:
	if index < 0 or index >= items.size():
		return
	
	var entry := items[index]
	
	var file_path := get_file_path_for_entry(entry)
	if FileAccess.file_exists(file_path):
		var dir := DirAccess.open(measurements_directory)
		if dir:
			dir.remove(file_path.get_file())
	
	items.remove_at(index)

func remove_all() -> void:
	var dir := DirAccess.open(measurements_directory)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(FILE_EXTENSION):
				dir.remove(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	
	items.clear()

## Query entries within a time range, optionally filtered to a single type.
## Pass "" for measurement_type to get all types.
func query_measurements(start_timestamp: int = 0, end_timestamp: int = 0, measurement_type: String = "") -> Array[MeasurementEntry]:
	var type_key := measurement_type.to_lower()
	var results: Array[MeasurementEntry] = []
	
	for e in items:
		if type_key != "" and e.type != type_key:
			continue
		if start_timestamp > 0 and e.timestamp < start_timestamp:
			continue
		if end_timestamp > 0 and e.timestamp > end_timestamp:
			continue
		results.append(e)
	
	return results

## Get all entries for a specific calendar date, optionally filtered to one type.
func get_measurements_by_date(year: int, month: int, day: int, measurement_type: String = "") -> Array[MeasurementEntry]:
	var target_date := Time.get_unix_time_from_datetime_dict({
		"year": year,
		"month": month,
		"day": day,
		"hour": 0,
		"minute": 0,
		"second": 0
	})
	var end_of_day := target_date + 86399  # 23:59:59
	
	return query_measurements(target_date, end_of_day, measurement_type)

## Get the most recent entry for a given type (each type has its own independent timeline).
func get_latest_entry(measurement_type: String) -> MeasurementEntry:
	var type_key := measurement_type.to_lower()
	if type_key not in VALID_TYPES:
		push_error("MeasurementManager: Invalid measurement type '%s'" % measurement_type)
		return null
	
	# items is sorted oldest -> newest; scan backwards for the first match.
	for i in range(items.size() - 1, -1, -1):
		if items[i].type == type_key:
			return items[i]
	
	return null

func get_last_measurement(measurement_type: String) -> Dictionary:
	"""
	Get the last recorded value for a specific measurement type.
	
	Args:
		measurement_type: String - "arms", "chest", "waist", "thigh", or "weight"
	
	Returns:
		Dictionary with keys: "date", "value", "timestamp"
		Returns empty dictionary if no measurements exist for that type.
	"""
	var latest := get_latest_entry(measurement_type)
	if not latest:
		return {}
	
	var dt := Time.get_datetime_dict_from_unix_time(latest.timestamp)
	var date_str := DATE_FORMAT % [dt.year, dt.month, dt.day]
	
	return {
		"date": date_str,
		"value": latest.value,
		"timestamp": latest.timestamp
	}

func get_last_measurements() -> Dictionary:
	"""
	Get the last recorded date and value for each measurement type independently.
	Each type may have a completely different date, since they're tracked atomically.
	
	Returns:
		Dictionary with keys: "arms", "chest", "waist", "thigh", "weight"
		Each value is a Dictionary with keys: "date", "value", "timestamp"
		Types with no recorded entries are omitted.
	"""
	var result := {}
	
	for type_key in VALID_TYPES:
		var last := get_last_measurement(type_key)
		if not last.is_empty():
			result[type_key] = last
	
	return result

func query_measurement_by_weeks(measurement_type: String, weeks: int) -> Array:
	"""
	Query measurements of a specific type within the last N weeks.
	
	Args:
		measurement_type: String - "arms", "chest", "waist", "thigh", or "weight"
		weeks: int - Number of weeks to look back
	
	Returns:
		Array of Dictionaries with keys: "date", "value", "timestamp"
		Returns empty array if no measurements exist or invalid type.
	"""
	var type_key := measurement_type.to_lower()
	if type_key not in VALID_TYPES:
		push_error("MeasurementManager: Invalid measurement type '%s'" % measurement_type)
		return []
	
	var now_unix := Time.get_unix_time_from_system()
	var weeks_in_seconds := weeks * 7 * 86400
	var start_timestamp := now_unix - weeks_in_seconds
	
	var entries_in_range := query_measurements(start_timestamp, now_unix, type_key)
	
	var records: Array = []
	for entry in entries_in_range:
		var dt := Time.get_datetime_dict_from_unix_time(entry.timestamp)
		var date_str := DATE_FORMAT % [dt.year, dt.month, dt.day]
		records.append({
			"date": date_str,
			"value": entry.value,
			"timestamp": entry.timestamp
		})
	
	records.sort_custom(func(a, b): return a.timestamp < b.timestamp)
	
	return records

func print_measurements() -> void:
	if items.is_empty():
		print("MeasurementManager: no measurements stored.")
		return
	
	print("MeasurementManager: %d entry/entries" % items.size())
	for e in items:
		var dt := Time.get_datetime_dict_from_unix_time(e.timestamp)
		var date_str := DATE_FORMAT % [dt.year, dt.month, dt.day]
		print("[%s] %s: %.1f" % [date_str, e.type, e.value])

func seed_example_data() -> void:
	# Clear existing data
	remove_all()
	
	var now_dict := Time.get_datetime_dict_from_system()
	var now_unix := Time.get_unix_time_from_datetime_dict(now_dict)
	
	var num_entries := 10
	var days_span := 90
	
	var base_values := {
		"arms": 35.0,
		"chest": 100.0,
		"waist": 82.0,
		"thigh": 55.0,
		"weight": 78.0
	}
	
	randi()
	
	# Each type gets its own independent set of days, to demonstrate that
	# types no longer need to share the same dates.
	for type_key in VALID_TYPES:
		for i in range(num_entries):
			var days_ago := int(float(i) / float(num_entries - 1) * days_span)
			var timestamp := now_unix - (days_ago * 86400)
			var progress := float(days_ago) / float(days_span)
			var improvement := (1.0 - progress) * 2.0
			
			var fluctuation := (randf() - 0.5) * 1.2
			var value: float = base_values[type_key]
			
			match type_key:
				"arms":
					value += improvement + fluctuation
				"chest":
					value += improvement * 0.5 + fluctuation * 1.25
				"waist":
					value -= improvement * 0.8
					value += fluctuation
				"thigh":
					value += improvement * 0.3 + fluctuation
				"weight":
					value -= improvement * 0.3
					value += fluctuation * 0.67
			
			value = max(value, 20.0)
			
			add_entry(type_key, value, timestamp)
	
	print("MeasurementManager: Seeded example data across %d types" % VALID_TYPES.size())
