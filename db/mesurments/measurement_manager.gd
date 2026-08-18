class_name MeasurementManager
extends RefCounted

const FILE_EXTENSION := ".json"
const DATE_FORMAT := "%04d-%02d-%02d"

var items: Array[Measurement] = []
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
			var measurement := load_measurement_file(file_path)
			if measurement:
				items.append(measurement)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# Sort by timestamp (oldest first)
	items.sort_custom(func(a, b): return a.timestamp < b.timestamp)

func load_measurement_file(file_path: String) -> Measurement:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("MeasurementManager: failed to read %s" % file_path)
		return null
	
	var text := file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		return Measurement.from_dict(parsed)
	else:
		push_error("MeasurementManager: invalid measurement data in %s" % file_path)
		return null

func save_measurement_file(measurement: Measurement) -> void:
	var file_path := get_file_path_for_measurement(measurement)
	
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(measurement.to_dict(), "\t"))
		file.close()
	else:
		push_error("MeasurementManager: failed to write %s (err %d)" % [file_path, FileAccess.get_open_error()])

func get_file_path_for_measurement(measurement: Measurement) -> String:
	var dt := Time.get_datetime_dict_from_unix_time(measurement.timestamp)
	var date_str := DATE_FORMAT % [dt.year, dt.month, dt.day]
	# Use timestamp to ensure uniqueness for multiple measurements on same day
	return measurements_directory + date_str + "_" + str(measurement.timestamp) + FILE_EXTENSION

func add(m: Measurement) -> void:
	var new_date := Time.get_datetime_dict_from_unix_time(m.timestamp)
	
	# Remove any existing measurements from the same calendar day.
	for i in range(items.size() - 1, -1, -1):
		var existing_date := Time.get_datetime_dict_from_unix_time(items[i].timestamp)
		
		if (
			existing_date.year == new_date.year
			and existing_date.month == new_date.month
			and existing_date.day == new_date.day
		):
			# Also delete the file for the old measurement
			var old_file_path := get_file_path_for_measurement(items[i])
			if FileAccess.file_exists(old_file_path):
				var dir := DirAccess.open(measurements_directory)
				if dir:
					dir.remove(old_file_path.get_file())
			
			items.remove_at(i)
	
	# Add the newest measurement
	items.append(m)
	
	# Save individual measurement file
	save_measurement_file(m)
	
	# Sort after adding
	items.sort_custom(func(a, b): return a.timestamp < b.timestamp)

func remove_at(index: int) -> void:
	if index < 0 or index >= items.size():
		return
	
	var measurement := items[index]
	
	# Remove the file
	var file_path := get_file_path_for_measurement(measurement)
	if FileAccess.file_exists(file_path):
		var dir := DirAccess.open(measurements_directory)
		if dir:
			dir.remove(file_path.get_file())
	
	# Remove from array
	items.remove_at(index)

func remove_all() -> void:
	# Delete all measurement files
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

func query_measurements(start_timestamp: int = 0, end_timestamp: int = 0) -> Array[Measurement]:
	"""Query measurements within a time range. Returns all if no range specified."""
	var results: Array[Measurement] = []
	
	for m in items:
		var include := true
		
		if start_timestamp > 0 and m.timestamp < start_timestamp:
			include = false
		
		if end_timestamp > 0 and m.timestamp > end_timestamp:
			include = false
		
		if include:
			results.append(m)
	
	return results

func get_measurements_by_date(year: int, month: int, day: int) -> Array[Measurement]:
	"""Get all measurements for a specific date."""
	var target_date := Time.get_unix_time_from_datetime_dict({
		"year": year,
		"month": month,
		"day": day,
		"hour": 0,
		"minute": 0,
		"second": 0
	})
	
	# Get start and end of day
	var end_of_day := target_date + 86399  # 23:59:59
	
	return query_measurements(target_date, end_of_day)

func get_latest_measurement() -> Measurement:
	"""Get the most recent measurement."""
	if items.is_empty():
		return null
	
	# Items are sorted by timestamp (oldest first)
	return items[items.size() - 1]

func get_last_measurement(measurement_type: String) -> Dictionary:
	"""
	Get the last recorded value for a specific measurement type.
	
	Args:
		measurement_type: String - "arms", "chest", "waist", "thigh", or "weight"
	
	Returns:
		Dictionary with keys: "date", "value", "timestamp"
		Returns empty dictionary if no measurements exist.
	"""
	if items.is_empty():
		return {}
	
	var latest := get_latest_measurement()
	if not latest:
		return {}
	
	var dt := Time.get_datetime_dict_from_unix_time(latest.timestamp)
	var date_str := DATE_FORMAT % [dt.year, dt.month, dt.day]
	
	var value := 0.0
	match measurement_type.to_lower():
		"arms":
			value = latest.arms
		"chest":
			value = latest.chest
		"waist":
			value = latest.waist
		"thigh":
			value = latest.thigh
		"weight":
			value = latest.weight
		_:
			push_error("MeasurementManager: Invalid measurement type '%s'" % measurement_type)
			return {}
	
	return {
		"date": date_str,
		"value": value,
		"timestamp": latest.timestamp
	}

func get_last_measurements() -> Dictionary:
	"""
	Get the last recorded date and value for all measurement types.
	
	Returns:
		Dictionary with keys: "arms", "chest", "waist", "thigh", "weight"
		Each value is a Dictionary with keys: "date", "value", "timestamp"
		Returns empty dictionary if no measurements exist.
	"""
	if items.is_empty():
		return {}
	
	var latest := get_latest_measurement()
	if not latest:
		return {}
	
	var dt := Time.get_datetime_dict_from_unix_time(latest.timestamp)
	var date_str := DATE_FORMAT % [dt.year, dt.month, dt.day]
	
	return {
		"arms": {
			"date": date_str,
			"value": latest.arms,
			"timestamp": latest.timestamp
		},
		"chest": {
			"date": date_str,
			"value": latest.chest,
			"timestamp": latest.timestamp
		},
		"waist": {
			"date": date_str,
			"value": latest.waist,
			"timestamp": latest.timestamp
		},
		"thigh": {
			"date": date_str,
			"value": latest.thigh,
			"timestamp": latest.timestamp
		},
		"weight": {
			"date": date_str,
			"value": latest.weight,
			"timestamp": latest.timestamp
		}
	}

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
	if items.is_empty():
		return []
	
	# Validate measurement type
	var valid_types := ["arms", "chest", "waist", "thigh", "weight"]
	if measurement_type.to_lower() not in valid_types:
		push_error("MeasurementManager: Invalid measurement type '%s'" % measurement_type)
		return []
	
	# Calculate timestamp for N weeks ago
	var now_unix := Time.get_unix_time_from_system()
	var weeks_in_seconds := weeks * 7 * 86400
	var start_timestamp := now_unix - weeks_in_seconds
	
	# Get all measurements within the time range
	var measurements_in_range := query_measurements(start_timestamp, now_unix)
	
	if measurements_in_range.is_empty():
		return []
	
	# Extract values for the specified measurement type
	var records: Array = []
	
	for measurement in measurements_in_range:
		var value: float = 0.0
		match measurement_type.to_lower():
			"arms":
				value = measurement.arms
			"chest":
				value = measurement.chest
			"waist":
				value = measurement.waist
			"thigh":
				value = measurement.thigh
			"weight":
				value = measurement.weight
		
		var dt := Time.get_datetime_dict_from_unix_time(measurement.timestamp)
		var date_str := DATE_FORMAT % [dt.year, dt.month, dt.day]
		
		records.append({
			"date": date_str,
			"value": value,
			"timestamp": measurement.timestamp
		})
	
	# Sort records by timestamp (oldest first)
	records.sort_custom(func(a, b): return a.timestamp < b.timestamp)
	
	return records

func print_measurements() -> void:
	if items.is_empty():
		print("MeasurementManager: no measurements stored.")
		return
	
	print("MeasurementManager: %d measurement(s)" % items.size())
	for m in items:
		var dt := Time.get_datetime_dict_from_unix_time(m.timestamp)
		var date_str := DATE_FORMAT % [dt.year, dt.month, dt.day]
		print("[%s] arms: %.1f, chest: %.1f, waist: %.1f, thigh: %.1f, weight: %.1f" % [
			date_str, m.arms, m.chest, m.waist, m.thigh, m.weight
		])

func seed_example_data() -> void:
	# Clear existing data
	remove_all()
	
	# Get current date
	var now_dict := Time.get_datetime_dict_from_system()
	var now_unix := Time.get_unix_time_from_datetime_dict(now_dict)
	
	# Create 10 entries spread over the last 90 days (3 months)
	var num_entries := 10
	var days_span := 90
	
	# Starting values (in cm and kg)
	var base_arms := 35.0
	var base_chest := 100.0
	var base_waist := 82.0
	var base_thigh := 55.0
	var base_weight := 78.0
	
	# Seed the random number generator
	randi()
	
	for i in range(num_entries):
		# Calculate how many days ago this entry should be
		# Spread evenly from 90 days ago to today
		var days_ago := int(float(i) / float(num_entries - 1) * days_span)
		
		# Calculate timestamp by subtracting days from current time
		# Using seconds since epoch is more reliable
		var timestamp := now_unix - (days_ago * 86400)  # 86400 seconds in a day
		var normalized_date := Time.get_datetime_dict_from_unix_time(timestamp)
		
		# Progress from oldest (1.0) to newest (0.0)
		var progress := float(days_ago) / float(days_span)
		
		# Slight improvements over time (muscle gain, fat loss)
		var improvement := (1.0 - progress) * 2.0
		
		# Random daily fluctuation
		var arms_var := (randf() - 0.5) * 1.2
		var chest_var := (randf() - 0.5) * 1.5
		var waist_var := (randf() - 0.5) * 1.2
		var thigh_var := (randf() - 0.5) * 1.2
		var weight_var := (randf() - 0.5) * 0.8
		
		# Weekly pattern (slight weekend variations)
		var day_of_week = normalized_date.weekday
		var weekend_factor := 0.0
		if day_of_week in [6, 7]:  # Saturday or Sunday
			weekend_factor = (randf() - 0.5) * 0.5
		
		var measurement := Measurement.new()
		measurement.timestamp = timestamp
		measurement.arms = base_arms + improvement + arms_var + weekend_factor
		measurement.chest = base_chest + improvement * 0.5 + chest_var + weekend_factor * 0.5
		measurement.waist = base_waist - improvement * 0.8 + waist_var + weekend_factor * 0.3
		measurement.thigh = base_thigh + improvement * 0.3 + thigh_var + weekend_factor * 0.3
		measurement.weight = base_weight - improvement * 0.3 + weight_var + weekend_factor * 0.2
		
		# Ensure values stay positive and reasonable
		measurement.arms = max(measurement.arms, 20.0)
		measurement.chest = max(measurement.chest, 70.0)
		measurement.waist = max(measurement.waist, 50.0)
		measurement.thigh = max(measurement.thigh, 30.0)
		measurement.weight = max(measurement.weight, 40.0)
		
		# Add the measurement (this will save it as an individual file)
		add(measurement)
	
	print("MeasurementManager: Seeded %d example measurements spanning 3 months" % items.size())
