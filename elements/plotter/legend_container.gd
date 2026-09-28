class_name PlotterLegend
extends VBoxContainer

# Template row lives in the scene purely as a style reference and is
# never shown itself, only duplicated once per plot. Row layout:
#   $PlotLegendRowTemplate/ColorRect -> plot color swatch
#   $PlotLegendRowTemplate/Label     -> plot name
@onready var legend_entry_row_template: HBoxContainer = $PlotLegendRowTemplate

var rows: Array[HBoxContainer] = []


func _ready() -> void:
	# Hidden children are skipped by the VBoxContainer layout, so the
	# template takes up no space.
	legend_entry_row_template.visible = false


func rebuild(plots: Array[Plotter.PlotData]) -> void:
	_clear_rows()

	for plot in plots:
		var row := _make_row(plot)
		add_child(row)
		rows.append(row)


func _make_row(plot: Plotter.PlotData) -> HBoxContainer:
	var row: HBoxContainer = legend_entry_row_template.duplicate()
	row.visible = true

	var color_rect: ColorRect = row.get_node("ColorRect")
	var label: Label = row.get_node("Label")
	color_rect.color = plot.color
	label.text = plot.name

	return row


func _clear_rows() -> void:
	for row in rows:
		# Remove immediately (queue_free alone is deferred, so the old
		# rows would linger in the layout for the rest of the frame).
		remove_child(row)
		row.queue_free()
	rows.clear()
