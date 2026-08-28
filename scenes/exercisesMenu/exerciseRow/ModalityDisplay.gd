extends CenterContainer

@export var input_modality: OptionInputButton

@onready var text_rect_modality: TextureRect = %TextRectModality

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
	# Connect to the modality input button's value_changed signal
	if input_modality:
		input_modality.value_changed.connect(_on_modality_changed)
		# Initialize display with current modality
		_update_display(input_modality.current_value)

func _on_modality_changed(new_value) -> void:
	"""
	Handle when modality is changed in the input button.
	"""
	_update_display(new_value)

func _update_display(modality_value) -> void:
	"""
	Update the display based on the provided modality value.
	"""
	if not text_rect_modality:
		return
	
	# Clear the texture first
	text_rect_modality.texture = null
	text_rect_modality.visible = false
	
	# If no modality or empty string, hide the texture
	if not modality_value or modality_value.is_empty():
		return
	
	# Convert to string in case it comes as something else
	var modality_str = str(modality_value)
	
	# Check if we have an icon for this modality
	if modality_str in MODALITY_ICONS:
		var icon_path = MODALITY_ICONS[modality_str]
		if ResourceLoader.exists(icon_path):
			text_rect_modality.texture = load(icon_path)
			text_rect_modality.visible = true
			# Optional: Set tooltip
			text_rect_modality.tooltip_text = "Modality: " + modality_str.capitalize()
		else:
			# Icon file doesn't exist
			push_warning("Modality icon not found: %s" % icon_path)
			text_rect_modality.visible = false
	else:
		# No icon mapping for this modality
		text_rect_modality.visible = false

# Public methods for external control

func set_modality(modality_value: String) -> void:
	"""
	Set the modality to display (without changing the input button).
	"""
	_update_display(modality_value)

func get_modality() -> String:
	"""
	Get the current modality from the input button.
	"""
	if input_modality:
		return str(input_modality.current_value) if input_modality.current_value else ""
	return ""

func clear_display() -> void:
	"""
	Clear the modality display.
	"""
	if text_rect_modality:
		text_rect_modality.texture = null
		text_rect_modality.visible = false

# Optional: Connect to the input button's other signals if needed
func _on_modality_selected(value) -> void:
	"""
	Alternative signal handler if you use a different signal name.
	"""
	_update_display(value)

# Optional: Handle when modality is cleared/emptied
func _on_modality_cleared() -> void:
	"""
	Handle when modality is cleared.
	"""
	clear_display()
