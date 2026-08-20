class_name MeasurementEntry
extends RefCounted

## A single, atomic measurement: one type, one value, one timestamp.
## e.g. {type: "weight", value: 78.4, timestamp: 1755676800}

var type: String = ""
var value: float = 0.0
var timestamp: int = 0

static func create(p_type: String, p_value: float, p_timestamp: int) -> MeasurementEntry:
	var e := MeasurementEntry.new()
	e.type = p_type
	e.value = p_value
	e.timestamp = p_timestamp
	return e

func to_dict() -> Dictionary:
	return {
		"type": type,
		"value": value,
		"timestamp": timestamp
	}

static func from_dict(data: Dictionary) -> MeasurementEntry:
	if not data.has("type") or not data.has("value") or not data.has("timestamp"):
		return null
	var e := MeasurementEntry.new()
	e.type = str(data["type"])
	e.value = float(data["value"])
	e.timestamp = int(data["timestamp"])
	return e
