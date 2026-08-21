extends ScrollContainer

@export var scroll_container: VBoxContainer 

func _ready():
	# Set mouse_filter for all existing children
	_set_children_mouse_filter_pass()
	
	# Connect to the tree_entered signal to handle children added after ready
	scroll_container.child_entered_tree.connect(_on_child_added)
	
	#print( input_filter_target.current_value )
	#print( input_filter_bodyweight.current_value )

func _set_children_mouse_filter_pass():
	"""Sets MOUSE_FILTER_PASS for all current children of the VBoxContainer"""
	for child in scroll_container.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_PASS

func _on_child_added(node: Node):
	"""Called when a child is added to the VBoxContainer"""
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_PASS
		# Also handle if the child has children of its own (optional)
		_set_child_hierarchy_mouse_filter_pass(node)

func _set_child_hierarchy_mouse_filter_pass(parent: Node):
	"""Recursively set mouse_filter for all Control children in a hierarchy"""
	for child in parent.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_PASS
			# Recursively process grandchildren
			_set_child_hierarchy_mouse_filter_pass(child)
