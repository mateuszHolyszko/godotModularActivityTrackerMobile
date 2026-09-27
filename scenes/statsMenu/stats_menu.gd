extends Menu

@onready var plotter: Plotter = %Plotter

func _ready() -> void:
	# --- Bench Press ---
	# Weekly sessions, 2024-06-11 → 2024-07-30.
	var bench_dates := PackedFloat32Array([
		1718064000.0,  # 2024-06-11
		1718668800.0,  # 2024-06-18
		1719273600.0,  # 2024-06-25
		1719878400.0,  # 2024-07-02
		1720483200.0,  # 2024-07-09
		1721088000.0,  # 2024-07-16
		1721692800.0,  # 2024-07-23
		1722297600.0,  # 2024-07-30
	])

	var bench_values := PackedFloat32Array([
		60.0,
		62.5,
		65.0,
		65.0,
		67.5,
		70.0,
		72.5,
		75.0,
	])

	# --- Squat ---
	# Deliberately different date set:
	#   - starts one week later than bench
	#   - skips 2024-07-09 (missed session)
	#   - overlaps bench on 2024-06-25, 2024-07-16, 2024-07-23, 2024-07-30
	var squat_dates := PackedFloat32Array([
		1718668800.0,  # 2024-06-18  (overlap)
		1719273600.0,  # 2024-06-25  (overlap)
		1719878400.0,  # 2024-07-02  (bench only this week)
		# 1720483200.0  <- 2024-07-09 skipped (missed session)
		1721088000.0,  # 2024-07-16  (overlap)
		1721692800.0,  # 2024-07-23  (overlap)
		1722297600.0,  # 2024-07-30  (overlap)
	])

	var squat_values := PackedFloat32Array([
		95.0,
		100.0,
		102.5,
		110.0,
		115.0,
		117.5,
	])

	plotter.add_plot(
		"Bench Press",
		Color.RED,
		bench_dates,
		bench_values
	)

	plotter.add_plot(
		"Squat",
		Color.DODGER_BLUE,
		squat_dates,
		squat_values
	)
