class_name ModifierPickMenu
extends Menu

signal modifiers_confirmed(modifiers: Array[String])
signal modifiers_cancelled()

## Posture
@onready var posture_flat_btn: Button = %PostureFlatButton
@onready var posture_decline_btn: Button = %PostureDeclineButton
@onready var posture_incline_btn: Button = %PostureInclineButton

## Involvement
@onready var involvement_unilateral_btn: Button = %InvolvementUnilateralButton
@onready var involvement_bilateral_btn: Button = %InvolvementBilateralButton

## Foot placement
@onready var feet_placement_elevated_btn: Button = %FtPlcmtElevatedButton
@onready var feet_placement_narrow_btn: Button = %FtPlcmtNarrowButton
@onready var feet_placement_wide_btn: Button = %FtPlcmtWideButton

@onready var back_button: Button = %BackButton
@onready var confirm_button: Button = %ConfirmButton

# Current selected modifiers
var _current_modifiers: Array[String] = []

# Store the original modifiers for cancellation
var _original_modifiers: Array[String] = []

# Group all modifier buttons for easy management
var _modifier_buttons: Array[Button] = []

func _ready() -> void:
	# Collect all modifier buttons
	_modifier_buttons = [
		posture_flat_btn, posture_decline_btn, posture_incline_btn,
		involvement_unilateral_btn, involvement_bilateral_btn,
		feet_placement_elevated_btn, feet_placement_narrow_btn, feet_placement_wide_btn
	]
	
	# Setup toggle behavior for buttons
	for btn in _modifier_buttons:
		if btn:
			btn.toggle_mode = true
			btn.pressed.connect(_on_modifier_button_pressed.bind(btn))
	
	# Connect action buttons
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_pressed)
	
	# Initialize button states
	_update_button_states()

func set_current_modifiers(modifiers: Array[String]) -> void:
	"""
	Set the current modifiers to display in the menu.
	"""
	_current_modifiers = modifiers.duplicate()
	_original_modifiers = modifiers.duplicate()
	_update_button_states()

func _update_button_states() -> void:
	"""
	Update all button states based on current modifiers.
	"""
	# Clear all selections first
	for btn in _modifier_buttons:
		if btn:
			btn.button_pressed = false
	
	# Set the pressed state for active modifiers
	for modifier in _current_modifiers:
		var btn = _get_button_for_modifier(modifier)
		if btn:
			btn.button_pressed = true

func _get_button_for_modifier(modifier: String) -> Button:
	"""
	Get the button corresponding to a modifier value.
	"""
	match modifier:
		"flat": return posture_flat_btn
		"decline": return posture_decline_btn
		"incline": return posture_incline_btn
		"unilateral": return involvement_unilateral_btn
		"bilateral": return involvement_bilateral_btn
		"feet_elevated": return feet_placement_elevated_btn
		"feet_narrow": return feet_placement_narrow_btn
		"feet_wide": return feet_placement_wide_btn
	return null

func _get_modifier_for_button(btn: Button) -> String:
	"""
	Get the modifier value for a given button.
	"""
	if btn == posture_flat_btn: return "flat"
	if btn == posture_decline_btn: return "decline"
	if btn == posture_incline_btn: return "incline"
	if btn == involvement_unilateral_btn: return "unilateral"
	if btn == involvement_bilateral_btn: return "bilateral"
	if btn == feet_placement_elevated_btn: return "feet_elevated"
	if btn == feet_placement_narrow_btn: return "feet_narrow"
	if btn == feet_placement_wide_btn: return "feet_wide"
	return ""

func _on_modifier_button_pressed(btn: Button) -> void:
	"""
	Handle modifier button toggle.
	Only one button per category can be selected at a time.
	"""
	if not btn:
		return
	
	var modifier = _get_modifier_for_button(btn)
	if modifier.is_empty():
		return
	
	# Get the category of this modifier
	var category = Exercise.get_modifier_category(modifier)
	if category.is_empty():
		return
	
	# If button is being pressed (not unpressed)
	if btn.button_pressed:
		# Remove any existing modifier from the same category
		for existing_mod in _current_modifiers.duplicate():
			var existing_category = Exercise.get_modifier_category(existing_mod)
			if existing_category == category:
				_current_modifiers.erase(existing_mod)
				# Unpress the corresponding button
				var existing_btn = _get_button_for_modifier(existing_mod)
				if existing_btn and existing_btn != btn:
					existing_btn.button_pressed = false
		
		# Add the new modifier
		_current_modifiers.append(modifier)
	else:
		# If button is being unpressed, remove the modifier
		_current_modifiers.erase(modifier)

func _on_back_pressed() -> void:
	"""
	Cancel and close the menu without saving.
	"""
	modifiers_cancelled.emit()
	_close_menu()

func _on_confirm_pressed() -> void:
	"""
	Confirm the selected modifiers.
	"""
	# Validate: only one modifier per category
	var seen_categories = {}
	var valid = true
	for mod in _current_modifiers:
		var category = Exercise.get_modifier_category(mod)
		if category.is_empty():
			continue
		if seen_categories.has(category):
			# This shouldn't happen with our logic, but just in case
			push_error("ModifierPickMenu: Multiple modifiers in category '%s'" % category)
			valid = false
			break
		seen_categories[category] = true
	
	if valid:
		modifiers_confirmed.emit(_current_modifiers.duplicate())
		_close_menu()
	else:
		# Something went wrong, revert
		_current_modifiers = _original_modifiers.duplicate()
		_update_button_states()

func _close_menu() -> void:
	"""
	Close the menu.
	"""
	request_close()

func get_selected_modifiers() -> Array[String]:
	"""
	Get the currently selected modifiers.
	"""
	return _current_modifiers.duplicate()

# Optional: Reset to default state
func reset_to_defaults() -> void:
	"""
	Reset all selections to their default (none selected).
	"""
	_current_modifiers = []
	_update_button_states()
