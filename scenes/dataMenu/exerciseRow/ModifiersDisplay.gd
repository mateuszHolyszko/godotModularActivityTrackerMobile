extends HBoxContainer

@onready var modifier_pick_button: ModifierPickButton = %ModifierPickButton

@onready var rect_posture: TextureRect = %TextRectPosture
@onready var rect_involvement: TextureRect = %TextRectInvolvement
@onready var rect_foot_pos: TextureRect = %TextRectFootPlcmt

# Map modifier values to SVG file paths
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

func _ready() -> void:
	# Connect to the modifier pick button's value_changed signal
	if modifier_pick_button:
		modifier_pick_button.value_changed.connect(_on_modifiers_changed)
		modifier_pick_button.on_set.connect(_on_modifiers_changed)
		# Initialize display with current modifiers
		_update_display(modifier_pick_button.get_modifiers())

func _on_modifiers_changed(new_modifiers: Array[String]) -> void:
	"""
	Handle when modifiers are changed in the pick button.
	"""
	_update_display(new_modifiers)

func _update_display(modifiers: Array[String]) -> void:
	"""
	Update the display based on the provided modifiers.
	"""
	# Clear all displays first
	clear_all_textures()
	
	# Track which categories we've displayed
	var displayed_categories = {}
	
	# Process each modifier
	for modifier in modifiers:
		var category = Exercise.get_modifier_category(modifier)
		
		match category:
			"posture":
				displayed_categories["posture"] = true
				_set_texture(rect_posture, modifier)
			
			"involvement":
				displayed_categories["involvement"] = true
				_set_texture(rect_involvement, modifier)
			
			"foot_placement":
				displayed_categories["foot_placement"] = true
				_set_texture(rect_foot_pos, modifier)

func _set_texture(texture_rect: TextureRect, modifier: String) -> void:
	"""
	Set the texture for a specific modifier.
	"""
	if not texture_rect:
		return
	
	# Check if we have an icon for this modifier
	if modifier in MODIFIER_ICONS:
		var icon_path = MODIFIER_ICONS[modifier]
		if ResourceLoader.exists(icon_path):
			texture_rect.texture = load(icon_path)
			texture_rect.visible = true
		else:
			# If icon doesn't exist, hide the texture rect
			texture_rect.visible = false
	else:
		# If no icon mapping, hide the texture rect
		texture_rect.visible = false

func clear_all_textures() -> void:
	"""
	Clear all texture rects.
	"""
	if rect_posture:
		rect_posture.texture = null
		rect_posture.visible = false
	if rect_involvement:
		rect_involvement.texture = null
		rect_involvement.visible = false
	if rect_foot_pos:
		rect_foot_pos.texture = null
		rect_foot_pos.visible = false

# Public methods for external control

func set_modifiers(modifiers: Array[String]) -> void:
	"""
	Set the modifiers to display (without changing the pick button).
	"""
	_update_display(modifiers)

func get_modifiers() -> Array[String]:
	"""
	Get the current modifiers from the pick button.
	"""
	if modifier_pick_button:
		return modifier_pick_button.get_modifiers()
	return []

# Optional: Add tooltips
func _setup_tooltips(modifiers: Array[String]) -> void:
	"""
	Setup tooltips for the texture rects.
	"""
	for modifier in modifiers:
		var category = Exercise.get_modifier_category(modifier)
		var tooltip_text = category.capitalize() + ": " + modifier.replace("_", " ").capitalize()
		
		match category:
			"posture":
				if rect_posture:
					rect_posture.tooltip_text = tooltip_text
			"involvement":
				if rect_involvement:
					rect_involvement.tooltip_text = tooltip_text
			"foot_placement":
				if rect_foot_pos:
					rect_foot_pos.tooltip_text = tooltip_text
