class_name DisplayExerciseMods
extends Control

@export var exercise: Exercise:
	set(value):
		exercise = value
		_update_display()

@onready var modality_tex_rect: TextureRect = %ModalityTextRect
@onready var posture_tex_rect: TextureRect = %PostureTextRect
@onready var involvement_tex_rect: TextureRect = %InvolvementTextRect
@onready var foot_placement_tex_rect: TextureRect = %FootPlacement

# References to parent containers 
@onready var modality_container: Control = %ModalityContainer
@onready var posture_container: Control = %PostureContainer
@onready var involvement_container: Control = %InvolvementContainer
@onready var foot_placement_container: Control = %FootPlacementContainer

@onready var background: ColorRect = %Background

# Map modifier values to SVG file paths (you'll fill these in)
const MODIFIER_ICONS: Dictionary = {
	# Posture
	"flat": "res://assets/icons/modifiers/flat.svg",
	"incline": "res://assets/icons/modifiers/incline.svg",
	"decline": "res://assets/icons/modifiers/decline.svg",
	# Involvement
	"unilateral": "res://assets/icons/involvement/unilateral.svg",
	"bilateral": "res://assets/icons/involvement/bilateral.svg",
	# Foot placement
	"feet_elevated": "res://assets/icons/foot_placement/feet_elevated.svg",
	"feet_wide": "res://assets/icons/foot_placement/feet_wide.svg",
	"feet_narrow": "res://assets/icons/foot_placement/feet_narrow.svg",
}

# Map modality values to SVG file paths
const MODALITY_ICONS: Dictionary = {
	"barbell": "res://assets/icons/modality/barbell.svg",
	"dumbbell": "res://assets/icons/modality/dummbell.svg",
	"kettlebell": "res://assets/icons/modality/kettlebell.svg",
	"machines": "res://assets/icons/modality/machine.svg",
	"cable": "res://assets/icons/modality/cable.svg",
	"calisthenics": "res://assets/icons/modality/calisthenic.svg",
	"bands": "res://assets/icons/modality/bands.svg",
}

func _ready() -> void:
	_update_display()

func _update_display() -> void:
	if not exercise:
		_hide_all_containers()
		return
		
	# Update color
	background.color = MuscleDict.get_color( exercise.target_muscle )
	
	# Handle modality
	if exercise.modality != "" and exercise.modality in MODALITY_ICONS:
		var icon_path = MODALITY_ICONS[exercise.modality]
		if ResourceLoader.exists(icon_path):
			modality_tex_rect.texture = load(icon_path)
			modality_tex_rect.visible = true
			modality_container.visible = true
		else:
			modality_container.visible = false
	else:
		modality_container.visible = false
	
	# Track which modifier categories we've displayed
	var displayed_modifiers = {}
	
	# Handle each modifier category
	for modifier in exercise.modifiers:
		var category = Exercise.get_modifier_category(modifier)
		
		match category:
			"posture":
				displayed_modifiers["posture"] = true
				if modifier in MODIFIER_ICONS:
					var icon_path = MODIFIER_ICONS[modifier]
					if ResourceLoader.exists(icon_path):
						posture_tex_rect.texture = load(icon_path)
						posture_tex_rect.visible = true
						posture_container.visible = true
					else:
						posture_container.visible = false
			
			"involvement":
				displayed_modifiers["involvement"] = true
				if modifier in MODIFIER_ICONS:
					var icon_path = MODIFIER_ICONS[modifier]
					if ResourceLoader.exists(icon_path):
						involvement_tex_rect.texture = load(icon_path)
						involvement_tex_rect.visible = true
						involvement_container.visible = true
					else:
						involvement_container.visible = false
			
			"foot_placement":
				displayed_modifiers["foot_placement"] = true
				if modifier in MODIFIER_ICONS:
					var icon_path = MODIFIER_ICONS[modifier]
					if ResourceLoader.exists(icon_path):
						foot_placement_tex_rect.texture = load(icon_path)
						foot_placement_tex_rect.visible = true
						foot_placement_container.visible = true
					else:
						foot_placement_container.visible = false
	
	# Hide any modifier containers that weren't displayed
	if not displayed_modifiers.has("posture"):
		posture_container.visible = false
	if not displayed_modifiers.has("involvement"):
		involvement_container.visible = false
	if not displayed_modifiers.has("foot_placement"):
		foot_placement_container.visible = false

func _hide_all_containers() -> void:
	modality_container.visible = false
	posture_container.visible = false
	involvement_container.visible = false
	foot_placement_container.visible = false

# Helper function to set exercise from code
func set_exercise(new_exercise: Exercise) -> void:
	exercise = new_exercise

# Optional: Add tooltip support to show the modifier/modality name on hover
func _ready_tooltips() -> void:
	if exercise:
		# You could add tooltips to show the names
		modality_tex_rect.tooltip_text = "Modality: " + exercise.modality if exercise.modality != "" else ""
		
		for modifier in exercise.modifiers:
			var category = Exercise.get_modifier_category(modifier)
			match category:
				"posture":
					posture_tex_rect.tooltip_text = "Posture: " + modifier
				"involvement":
					involvement_tex_rect.tooltip_text = "Involvement: " + modifier
				"foot_placement":
					foot_placement_tex_rect.tooltip_text = "Foot placement: " + modifier
