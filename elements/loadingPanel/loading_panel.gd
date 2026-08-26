extends Panel
class_name LoadingPanel

@export var prompt_text: String = "Loading"
@export var loading_container: Control
@export var fade_out_duration: float = 0.25

@onready var prompt_label: Label = $VB/PromptLabel
@onready var spinner: LoadingSpinner = $VB/LoadingSpinner

var _fade_tween: Tween

func _ready() -> void:
	prompt_label.text = prompt_text

	if loading_container:
		loading_container.resized.connect(_update_rect)

	hide()

func show_loading() -> void:
	if not loading_container:
		push_warning("LoadingPanel: No loading_container assigned.")
		return
	
	if _fade_tween:
		_fade_tween.kill()

	_update_rect()
	prompt_label.text = prompt_text
	modulate.a = 1.0
	show()
	spinner.show()

func hide_loading() -> void:
	if _fade_tween:
		_fade_tween.kill()

	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 0.0, fade_out_duration)
	_fade_tween.finished.connect(_on_fade_out_finished)

func _on_fade_out_finished() -> void:
	hide()
	spinner.hide()
	modulate.a = 1.0  # reset so next show_loading() is fully opaque

func _update_rect() -> void:
	var container_rect := loading_container.get_global_rect()
	var parent := get_parent() as Control
	if not parent:
		return
	var parent_rect := parent.get_global_rect()
	position = container_rect.position - parent_rect.position
	size = container_rect.size
