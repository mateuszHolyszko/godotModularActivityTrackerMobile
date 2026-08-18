extends Resource
class_name Measurement

@export var timestamp: int = 0
@export var arms: float = 0.0
@export var chest: float = 0.0
@export var waist: float = 0.0
@export var thigh: float = 0.0
@export var weight: float = 0.0

func to_dict() -> Dictionary:
	return {
		"timestamp": timestamp,
		"arms": arms,
		"chest": chest,
		"waist": waist,
		"thigh": thigh,
		"weight": weight,
	}

static func from_dict(d: Dictionary) -> Measurement:
	var m := Measurement.new()
	m.timestamp = int(d.get("timestamp", 0))
	m.arms = d.get("arms", 0.0)
	m.chest = d.get("chest", 0.0)
	m.waist = d.get("waist", 0.0)
	m.thigh = d.get("thigh", 0.0)
	m.weight = d.get("weight", 0.0)
	return m
