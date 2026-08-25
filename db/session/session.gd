extends Resource
class_name Session

@export var session_id: String = ""
@export var program: Program
@export var date: String = ""  # ISO format: YYYY-MM-DD
@export var duration: int = 0  # Duration in minutes
@export var body_weight: float = 0.0  # Body weight in kg

func to_dict() -> Dictionary:
	return {
		"session_id": session_id,
		"program_name": program.program_name if program else "",
		"date": date,
		"duration": duration,
		"body_weight": body_weight
	}

static func from_dict(d: Dictionary, program_manager) -> Session:
	var session := Session.new()

	session.session_id = str(d.get("session_id", ""))
	session.date = str(d.get("date", ""))
	session.duration = int(d.get("duration", 0))
	session.body_weight = float(d.get("body_weight", 0.0))

	var program_name := str(d.get("program_name", ""))
	if program_name != "":
		session.program = program_manager.get_program(program_name)

		if not session.program:
			push_warning("Session: program '%s' could not be resolved" % program_name)

	return session
