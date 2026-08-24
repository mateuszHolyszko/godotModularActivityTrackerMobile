# TreeLines.gd
extends Control

@export var line_color := Color(0.4, 0.6, 0.9, 0.8)
@export var vertical_x: float = 20.0
@export var line_width: float = 2.0
@export var label_connector_length: float = 30.0
@export var button_connector_length: float = 30.0
@export var dotted_line_length: float = 5.0
@export var dotted_line_gap: float = 3.0

@export var limit_top_node: Node2D = null
@export var limit_bottom_node: Node2D = null

var items: Array = []
var scroll_container: ScrollContainer = null


func set_scroll_container(container: ScrollContainer) -> void:
	scroll_container = container
	if scroll_container:
		var v_scroll := scroll_container.get_v_scroll_bar()
		if v_scroll:
			v_scroll.value_changed.connect(_on_scroll_changed)


func add_item(control: Control) -> void:
	var item_pos := control.global_position - global_position
	
	# Determine if this control or any of its descendants is a Button
	var is_button := _contains_button(control)
	
	# Debug print to see what's being detected
	#print("add_item called with control: ", control.name, " is_button: ", is_button)
	
	items.append({
		"y": item_pos.y,
		"height": control.size.y,
		"width": control.size.x,
		"control": control,
		"is_button": is_button
	})
	queue_redraw()


func _contains_button(node: Node) -> bool:
	"""Check if the node or any of its descendants is a Button"""
	# Check if the node itself is a Button
	if node is Button:
		#print("Found Button directly: ", node.name)
		return true
	
	# Check all children recursively
	for child in node.get_children():
		#print("Checking child: ", child.name, " of type: ", child.get_class())
		if _contains_button(child):
			return true
	
	return false


func _contains_label(node: Node) -> bool:
	"""Check if the node or any of its descendants is a Label"""
	if node is Label:
		return true
	
	for child in node.get_children():
		if _contains_label(child):
			return true
	
	return false


func clear_items() -> void:
	items.clear()
	queue_redraw()


func _on_scroll_changed(value: float) -> void:
	for item in items:
		if item.get("control") and is_instance_valid(item.control):
			var item_pos = item.control.global_position - global_position
			item.y = item_pos.y
	queue_redraw()


func _get_clip_bounds() -> Dictionary:
	var top_y: float = -INF
	var bottom_y: float = INF
	
	if limit_top_node and is_instance_valid(limit_top_node):
		var top_pos := limit_top_node.global_position - global_position
		top_y = top_pos.y
	
	if limit_bottom_node and is_instance_valid(limit_bottom_node):
		var bottom_pos := limit_bottom_node.global_position - global_position
		bottom_y = bottom_pos.y
	
	if not limit_top_node and not limit_bottom_node and scroll_container:
		var scroll_rect := scroll_container.get_global_rect()
		var local_top := scroll_rect.position - global_position
		top_y = local_top.y
		bottom_y = local_top.y + scroll_rect.size.y
	
	return {"top": top_y, "bottom": bottom_y}


func _draw_dotted_line(from: Vector2, to: Vector2, color: Color, width: float, dash_length: float, gap_length: float) -> void:
	var distance := from.distance_to(to)
	var direction := (to - from).normalized()
	var total_dash_distance := dash_length + gap_length
	var drawn := 0.0
	
	while drawn < distance:
		var dash_start := from + direction * drawn
		var remaining := distance - drawn
		var current_dash_length = min(dash_length, remaining)
		var dash_end = dash_start + direction * current_dash_length
		
		draw_line(dash_start, dash_end, color, width)
		drawn += total_dash_distance


func _draw() -> void:
	if items.is_empty():
		return
	
	var bounds := _get_clip_bounds()
	var top_clip = bounds["top"]
	var bottom_clip = bounds["bottom"]
	
	var first_item_y = items[0]["y"] + (items[0]["height"] / 2)
	var last_item_y = items[-1]["y"] + (items[-1]["height"] / 2)
	
	var vertical_start_y = max(first_item_y, top_clip)
	var vertical_end_y = min(last_item_y, bottom_clip)
	
	if vertical_start_y >= vertical_end_y:
		return
	
	draw_line(
		Vector2(vertical_x, vertical_start_y), 
		Vector2(vertical_x, vertical_end_y), 
		line_color, 
		line_width
	)
	
	for item in items:
		var y_pos = item["y"] + (item["height"] / 2)
		var is_button = item.get("is_button", false)
		
		if y_pos >= top_clip and y_pos <= bottom_clip:
			var connector_len = button_connector_length if is_button else label_connector_length
			var element_x = vertical_x + connector_len
			
			var start_point := Vector2(vertical_x, y_pos)
			var end_point := Vector2(element_x, y_pos)
			
			if is_button:
				_draw_dotted_line(start_point, end_point, line_color, line_width, dotted_line_length, dotted_line_gap)
			else:
				draw_line(start_point, end_point, line_color, line_width)
