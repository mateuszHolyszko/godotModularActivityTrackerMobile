extends Node

# MUSCLE DICTIONARY AUTOLOADED

const MUSCLE_COLORS := {
	"Chest": Color8(255, 102, 102),
	"Back": Color8(255, 178, 102),
	"Quads": Color8(153, 255, 51),
	"Hamstrings": Color8(51, 255, 51),
	"Glutes": Color8(51, 255, 153),
	"Shoulders": Color8(102, 102, 255),
	"Biceps": Color8(102, 255, 255),
	"Triceps": Color8(102, 178, 255),
	"Abs": Color8(178, 102, 255),
	"Calves": Color8(255, 102, 255),
	"Forearms": Color8(255, 102, 178)
}

const MEASUREMENTS_COLORS := {
	"weight": Color8(255, 255, 255),
	"chest": Color8(232, 56, 109),
	"arms": Color8(24, 107, 135),
	"waist": Color8(101, 43, 122),
	"thigh": Color8(62, 150, 79)
}

func get_color(muscle: String) -> Color:
	return MUSCLE_COLORS.get(muscle, Color.WHITE)

func get_all_muscles() -> Array:
	return MUSCLE_COLORS.keys()

func get_all_measurements() -> Array:
	return MEASUREMENTS_COLORS.keys()
