class_name OptionEntryMenu
extends Menu

signal option_selected(value)

@onready var prompt_label: Label = %Prompt
@onready var options_container: FlowContainer = %VFOptionsContainer
@onready var cancel_button: Button = %CancelButton
@onready var deselect_button: Button = %DeselectButton

## Optional: assign a custom Button-derived scene for option entries.
## If left empty, plain Buttons are created.
@export var option_button_scene: PackedScene

var _options: Array = []       # normalized: [{"label": String, "value": Variant}, ...]
var _prompt_text: String = ""
var _current_value = null


func set_options_data(options: Array, current_value = null, prompt: String = "") -> void:
	_options = _normalize_options(options)
	_current_value = current_value
	_prompt_text = prompt


func _normalize_options(options: Array) -> Array:
	var normalized: Array = []
	for opt in options:
		if opt is Dictionary:
			var value = opt.get("value", opt.get("label"))
			var label = str(opt.get("label", value))
			normalized.append({"label": label, "value": value})
		else:
			normalized.append({"label": str(opt), "value": opt})
	return normalized


func _ready() -> void:
	cancel_button.pressed.connect(_on_cancel_pressed)
	deselect_button.pressed.connect(_on_deselect_pressed)


func _on_open() -> void:
	prompt_label.text = _prompt_text
	_rebuild_option_buttons()


func _rebuild_option_buttons() -> void:
	for child in options_container.get_children():
		child.queue_free()

	for opt in _options:
		var btn: Button = option_button_scene.instantiate() if option_button_scene else Button.new()
		btn.text = opt.label
		btn.custom_minimum_size = Vector2(400, 200)
		if opt.value == _current_value:
			btn.theme_type_variation = &"SelectedOptionButton"  # style this in your theme, optional
		btn.pressed.connect(_on_option_pressed.bind(opt.value))
		
		# Color the button if it matches any key in MUSCLE_COLORS or MEASUREMENTS_COLORS
		_color_option_button(btn, opt.label)
		
		options_container.add_child(btn)


func _color_option_button(button: Button, option_label: String) -> void:
	# Check if the option label matches any key in MUSCLE_COLORS or MEASUREMENTS_COLORS
	var color: Color = Color.WHITE
	var found := false
	
	# Check MUSCLE_COLORS
	if MuscleDict.MUSCLE_COLORS.has(option_label):
		color = MuscleDict.MUSCLE_COLORS[option_label]
		found = true
	# Check MEASUREMENTS_COLORS
	elif MuscleDict.MEASUREMENTS_COLORS.has(option_label):
		color = MuscleDict.MEASUREMENTS_COLORS[option_label]
		found = true
	
	# If no match found, don't apply any color
	if not found:
		return
	
	# Set alpha to 200 (0-255 range, so 200/255 ≈ 0.78)
	color.a = 200.0 / 255.0
	
	# Create a new stylebox and copy existing properties if available
	var existing_stylebox := button.get_theme_stylebox("normal")
	var stylebox: StyleBoxFlat
	
	if existing_stylebox is StyleBoxFlat:
		# If it's already a StyleBoxFlat, duplicate it
		stylebox = existing_stylebox.duplicate()
	else:
		# Otherwise create a new one with default settings
		stylebox = StyleBoxFlat.new()
		stylebox.corner_radius_top_left = 4
		stylebox.corner_radius_top_right = 4
		stylebox.corner_radius_bottom_left = 4
		stylebox.corner_radius_bottom_right = 4
	
	# Only change the background color
	stylebox.bg_color = color
	
	# Apply the modified stylebox
	button.add_theme_stylebox_override("normal", stylebox)
	button.add_theme_stylebox_override("hover", stylebox)
	button.add_theme_stylebox_override("pressed", stylebox)


func _on_option_pressed(value) -> void:
	option_selected.emit(value)


func _on_cancel_pressed() -> void:
	request_close()
	
func _on_deselect_pressed() -> void:
	option_selected.emit(null)
