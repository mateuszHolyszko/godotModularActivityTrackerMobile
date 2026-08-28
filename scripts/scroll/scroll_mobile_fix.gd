extends ScrollContainer

@export var scroll_container: BoxContainer 

func _ready() -> void:
	if scroll_container:
		_watch_subtree(scroll_container)

func _watch_subtree(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_PASS

	if not node.child_entered_tree.is_connected(_on_nested_child_added):
		node.child_entered_tree.connect(_on_nested_child_added)

	for child in node.get_children():
		_watch_subtree(child)

func _on_nested_child_added(node: Node) -> void:
	_watch_subtree(node)
