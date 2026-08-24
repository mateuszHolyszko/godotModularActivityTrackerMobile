class_name InsertPositionEntry
extends Menu

signal position_selected(index: int)

@onready var prompt_label: Label = %Prompt
@onready var options_container: VBoxContainer = %OptionsContainer
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var cancel_button: Button = %CancelButton

@onready var label_hb_template: HBoxContainer = %LabelHB_template
@onready var button_hb_template: HBoxContainer = %ButtonHB_template

@onready var tree_lines: Control = %TreeLines

# Optional limit markers - add these as child nodes in your scene
#@onready var limit_top: Node2D = %LimitTop  # Place at top of scroll area
#@onready var limit_bottom: Node2D = %LimitBottom  # Place at bottom of scroll area

var _options: Array[String] = []
var _prompt_text: String = ""


func set_options_data(options: Array, prompt: String = "") -> void:
	_options.clear()
	for option in options:
		_options.append(str(option))
	_prompt_text = prompt


func _ready() -> void:
	cancel_button.pressed.connect(_on_cancel_pressed)
	
	# Set up tree lines with limit nodes
	if tree_lines:
		tree_lines.set_scroll_container(scroll_container)
		
		# Set limit nodes if they exist
		#if limit_top:
		#	tree_lines.limit_top_node = limit_top
		#if limit_bottom:
		#	tree_lines.limit_bottom_node = limit_bottom


func _on_open() -> void:
	prompt_label.text = _prompt_text
	_rebuild_position_entries()


func _rebuild_position_entries() -> void:
	for child in options_container.get_children():
		child.queue_free()
	await get_tree().process_frame
	
	if tree_lines:
		tree_lines.clear_items()
	
	_add_insert_button(0)
	
	for index in _options.size():
		_add_option_label(index)
		_add_insert_button(index + 1)
	
	await get_tree().process_frame
	_update_tree_lines()


func _update_tree_lines() -> void:
	if not tree_lines:
		return
	
	tree_lines.clear_items()
	
	for child in options_container.get_children():
		if child is HBoxContainer:
			# Pass the HBoxContainer itself, not its first child
			tree_lines.add_item(child)
	
	tree_lines.queue_redraw()


func _add_option_label(index: int) -> void:
	var label_hb: HBoxContainer = label_hb_template.duplicate()
	label_hb.visible = true
	
	var label: Label = null
	for child in label_hb.get_children():
		if child is Label:
			label = child
			break
	
	if label:
		label.text = _options[index]
	
	options_container.add_child(label_hb)
	
	if tree_lines:
		call_deferred("_update_tree_lines_after_add")


func _add_insert_button(index: int) -> void:
	var button_hb: HBoxContainer = button_hb_template.duplicate()
	button_hb.visible = true
	
	var button: Button = null
	for child in button_hb.get_children():
		if child is Button:
			button = child
			break
	
	if button:
		button.text = "< Insert"
		if button.pressed.is_connected(_on_insert_button_pressed):
			button.pressed.disconnect(_on_insert_button_pressed)
		button.pressed.connect(_on_insert_button_pressed.bind(index))
	
	options_container.add_child(button_hb)


func _update_tree_lines_after_add() -> void:
	await get_tree().process_frame
	_update_tree_lines()


func _on_insert_button_pressed(index: int) -> void:
	position_selected.emit(index)


func _on_cancel_pressed() -> void:
	request_close()
