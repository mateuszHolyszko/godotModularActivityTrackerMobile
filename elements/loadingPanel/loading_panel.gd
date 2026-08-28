extends Panel
class_name LoadingPanel

@export var prompt_text: String = "Loading"
@export var fade_out_duration: float = 0.25

@onready var prompt_label: Label = $VB/PromptLabel
@onready var spinner: LoadingSpinner = $VB/LoadingSpinner

var _fade_tween: Tween

func _ready() -> void:
	prompt_label.text = prompt_text

	hide()

func show_loading() -> void:	
	if _fade_tween:
		_fade_tween.kill()

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
