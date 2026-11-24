
extends Control

# =========================================================
# GRIDTRAIL - 100 LEVEL PUZZLE GAME
# =========================================================

const TOTAL_LEVELS = 100
const LEVELS_PER_STAGE = 20

const BG_COLOR = Color("#10111d")
const EMPTY_COLOR = Color("#272a3c")
const PATH_COLOR = Color("#7545d6")
const START_COLOR = Color("#087f5b")
const FINISH_COLOR = Color("#087ca5")
const OBSTACLE_COLOR = Color("#11131b")
const WHITE = Color("#ffffff")
const MUTED = Color("#aaa6c2")
const GOLD = Color("#f5c451")

var current_level = 1
var unlocked_level = 1

var grid_size = 5
var checkpoint_count = 5
var obstacle_count = 0

var route = []
var playable_path = []
var path = []

var number_positions = {}
var obstacle_cells = {}

var tiles = []
var board: GridContainer

var status_label: Label
var progress_label: Label
var timer_label: Label

# Stopwatch
var elapsed_time = 0.0
var timer_running = false
var best_time = -1.0

# Player statistics
var move_count = 0
var completed_stars = 0
var new_record = false

var next_number = 2
var dragging = false
var completed = false

var tile_size = 60
var tile_gap = 6

var save_file = ConfigFile.new()


# =========================================================
# START
# =========================================================

func _ready():
	load_progress()
	show_main_menu()


# =========================================================
# STOPWATCH
# =========================================================

func _process(delta):
	if timer_running and not completed:
		elapsed_time += delta
		update_timer_display()


func format_time(seconds: float) -> String:
	var total_seconds = int(seconds)
	var minutes = int(total_seconds / 60)
	var remaining_seconds = total_seconds % 60

	var milliseconds = int(
		(seconds - float(total_seconds)) * 100
	)

	return "%02d:%02d.%02d" % [
		minutes,
		remaining_seconds,
		milliseconds
	]


func update_timer_display():
	if timer_label == null:
		return

	var best_text = "--:--.--"

	if best_time >= 0:
		best_text = format_time(best_time)

	timer_label.text = "TIME  %s     BEST  %s" % [
		format_time(elapsed_time),
		best_text
	]


# =========================================================
# SAVE AND LOAD
# =========================================================

func load_progress():
	var result = save_file.load(
        "user://gridtrail_progress.cfg"
	)

	if result == OK:
		unlocked_level = int(
			save_file.get_value(
				"progress",
				"unlocked_level",
				1
			)
		)

	unlocked_level = clampi(
		unlocked_level,
		1,
		TOTAL_LEVELS
	)


func save_progress():
	save_file.set_value(
		"progress",
		"unlocked_level",
		unlocked_level
	)

	save_file.save(
        "user://gridtrail_progress.cfg"
	)


func load_best_time(level: int) -> float:
	return float(
		save_file.get_value(
			"records",
			str(level),
			-1.0
		)
	)


func save_best_time(level: int, seconds: float):
	save_file.set_value(
		"records",
		str(level),
		seconds
	)

	save_file.save(
        "user://gridtrail_progress.cfg"
	)


# =========================================================
# SCREEN MANAGEMENT
# =========================================================

func clear_screen():
	for child in get_children():
		remove_child(child)
		child.queue_free()

	tiles.clear()
	board = null

	status_label = null
	progress_label = null
	timer_label = null


func create_background():
	var background = ColorRect.new()

	background.color = BG_COLOR

	background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	background.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(background)


func create_label(
	label_text: String,
	position: Vector2,
	label_size: Vector2,
	font_size: int,
	color: Color = WHITE
) -> Label:

	var label = Label.new()

	label.text = label_text
	label.position = position
	label.size = label_size

	label.add_theme_font_size_override(
		"font_size",
		font_size
	)

	label.add_theme_color_override(
		"font_color",
		color
	)

	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	add_child(label)

	return label


func create_button(
	button_text: String,
	position: Vector2,
	button_size: Vector2,
	font_size: int = 20
) -> Button:

	var button = Button.new()

	button.text = button_text
	button.position = position
	button.size = button_size

	button.add_theme_font_size_override(
		"font_size",
		font_size
	)

	button.add_theme_color_override(
		"font_color",
		WHITE
	)

	var normal = StyleBoxFlat.new()
	normal.bg_color = Color("#272a3c")
	normal.set_corner_radius_all(10)
	normal.set_border_width_all(1)
	normal.border_color = Color("#55516e")

	var hover = StyleBoxFlat.new()
	hover.bg_color = Color("#40345e")
	hover.set_corner_radius_all(10)
	hover.set_border_width_all(1)
	hover.border_color = Color("#9972e8")

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)

	add_child(button)

	return button


# =========================================================
# MAIN MENU
# =========================================================

func show_main_menu():
	clear_screen()
	create_background()

	var screen = get_viewport_rect().size

	create_label(
		"GRIDTRAIL",
		Vector2(0, screen.y * 0.20),
		Vector2(screen.x, 80),
		52
	)

	create_label(
		"CONNECT • SOLVE • WIN",
		Vector2(0, screen.y * 0.20 + 75),
		Vector2(screen.x, 40),
		16,
		MUTED
	)

	var play_button = create_button(
		"PLAY",
		Vector2(screen.x / 2 - 120, screen.y * 0.48),
		Vector2(240, 60),
		24
	)

	play_button.pressed.connect(
		func():
			start_level(unlocked_level)
	)

	var levels_button = create_button(
		"LEVEL SELECT",
		Vector2(screen.x / 2 - 120, screen.y * 0.48 + 80),
		Vector2(240, 55),
		20
	)

	levels_button.pressed.connect(show_level_select)

	create_label(
		"UNLOCKED: %d / %d" % [
			unlocked_level,
			TOTAL_LEVELS
		],
		Vector2(0, screen.y * 0.48 + 155),
		Vector2(screen.x, 35),
		16,
		MUTED
	)


# =========================================================
# LEVEL SELECT
# =========================================================

func show_level_select():
	clear_screen()
	create_background()

	var screen = get_viewport_rect().size

	create_label(
		"SELECT LEVEL",
		Vector2(0, 30),
		Vector2(screen.x, 60),
		34
	)

	var columns = 10
	var button_size = 48
	var gap = 10

	var total_width = (
		columns * button_size +
		(columns - 1) * gap
	)

	var start_x = (screen.x - total_width) / 2
	var start_y = 120

	for level in range(1, TOTAL_LEVELS + 1):

		var row = int((level - 1) / columns)
		var column = (level - 1) % columns

		var position = Vector2(
			start_x + column * (button_size + gap),
			start_y + row * (button_size + gap)
		)

		var level_button = create_button(
			str(level),
			position,
			Vector2(button_size, button_size),
			17
		)

		if level <= unlocked_level:

			level_button.disabled = false

			level_button.pressed.connect(
				start_level.bind(level)
			)

			if level == current_level:
				level_button.modulate = Color("#b99aff")

		else:

			level_button.disabled = true
			level_button.modulate = Color("#555566")

	var back_button = create_button(
		"BACK",
		Vector2(screen.x / 2 - 100, screen.y - 65),
		Vector2(200, 45),
		18
	)

	back_button.pressed.connect(show_main_menu)


# =========================================================
# LEVEL CONFIGURATION
# =========================================================

func configure_level(level: int):

	var stage = int(
		(level - 1) / LEVELS_PER_STAGE
	)

	var local_level = (level - 1) % LEVELS_PER_STAGE

	grid_size = 5 + stage

	checkpoint_count = mini(
		5 + stage,
		9
	)

	obstacle_count = int(
		round(
			float(local_level) / 19.0 *
			float(grid_size - 3)
		)
	)

	# UPDATED TILE SIZE
	tile_size = 72 - (stage * 7)

	tile_gap = 6


func get_difficulty_name() -> String:

	var stage = int(
		(current_level - 1) / LEVELS_PER_STAGE
	)

	match stage:
		0:
			return "EASY"
		1:
			return "NORMAL"
		2:
			return "HARD"
		3:
			return "EXPERT"
		4:
			return "MASTER"

	return "UNKNOWN"


# =========================================================
# GENERATE DIFFERENT ROUTE PATTERNS
# =========================================================

func generate_level():

	route.clear()
	playable_path.clear()

	number_positions.clear()
	obstacle_cells.clear()

	var rng = RandomNumberGenerator.new()

	# Each level gets its own deterministic seed.
	rng.seed = current_level * 7919 + 12345

	# Choose different route directions.
	# 0 = Horizontal snake
	# 1 = Vertical snake

	var route_type = rng.randi_range(0, 1)

	# Randomly mirror and reverse the route.
	var flip_horizontal = rng.randi_range(0, 1) == 1
	var flip_vertical = rng.randi_range(0, 1) == 1
	var reverse_route = rng.randi_range(0, 1) == 1

	var base_route = []

	# Build horizontal snake.

	if route_type == 0:

		for row in range(grid_size):

			if row % 2 == 0:

				for column in range(grid_size):
					base_route.append(
						Vector2i(column, row)
					)

			else:

				for column in range(grid_size - 1, -1, -1):
					base_route.append(
						Vector2i(column, row)
					)

	# Build vertical snake.

	else:

		for column in range(grid_size):

			if column % 2 == 0:

				for row in range(grid_size):
					base_route.append(
						Vector2i(column, row)
					)

			else:

				for row in range(grid_size - 1, -1, -1):
					base_route.append(
						Vector2i(column, row)
					)

	# Transform the route.
	# These transformations keep every move adjacent.

	for coordinate in base_route:

		var x = coordinate.x
		var y = coordinate.y

		if flip_horizontal:
			x = grid_size - 1 - x

		if flip_vertical:
			y = grid_size - 1 - y

		route.append(
			y * grid_size + x
		)

	# Reverse the complete route when selected.

	if reverse_route:
		route.reverse()

	# Select playable cells.

	var total_cells = grid_size * grid_size

	var playable_count = (
		total_cells - obstacle_count
	)

	for i in range(playable_count):
		playable_path.append(route[i])

	# Remaining cells are blocked obstacles.

	for i in range(playable_count, total_cells):
		obstacle_cells[route[i]] = true

	# =====================================================
	# RANDOM CHECKPOINT POSITIONS
	# =====================================================

	# First and last cells are always checkpoints.
	# Other checkpoints are placed at different positions.

	var checkpoint_indices = []

	checkpoint_indices.append(0)

	var available_indices = []

	for i in range(1, playable_count - 1):
		available_indices.append(i)

	available_indices.shuffle()

	for i in range(checkpoint_count - 2):
		checkpoint_indices.append(
			available_indices[i]
		)

	checkpoint_indices.append(
		playable_count - 1
	)

	checkpoint_indices.sort()

	# Assign numbers according to route order.

	for i in range(checkpoint_indices.size()):

		var route_index = checkpoint_indices[i]

		var cell_index = playable_path[route_index]

		number_positions[cell_index] = i + 1


# =========================================================
# START LEVEL
# =========================================================

func start_level(level: int):

	if level < 1 or level > TOTAL_LEVELS:
		return

	if level > unlocked_level:
		return

	current_level = level

	configure_level(current_level)
	generate_level()

	path.clear()

	next_number = 2

	dragging = false
	completed = false

	elapsed_time = 0.0
	timer_running = false

	move_count = 0
	completed_stars = 0
	new_record = false

	best_time = load_best_time(current_level)

	show_game_screen()


# =========================================================
# GAME SCREEN
# =========================================================

func show_game_screen():

	clear_screen()
	create_background()

	var screen = get_viewport_rect().size

	create_label(
		"GRIDTRAIL",
		Vector2(0, 8),
		Vector2(screen.x, 45),
		28
	)

	create_label(
		"LEVEL %d  •  %s" % [
			current_level,
			get_difficulty_name()
		],
		Vector2(0, 52),
		Vector2(screen.x, 35),
		17,
		MUTED
	)

	status_label = create_label(
		"START AT NUMBER 1",
		Vector2(0, 88),
		Vector2(screen.x, 30),
		16,
		WHITE
	)

	progress_label = create_label(
		"",
		Vector2(0, 118),
		Vector2(screen.x, 28),
		14,
		MUTED
	)

	timer_label = create_label(
		"",
		Vector2(0, 145),
		Vector2(screen.x, 28),
		16,
		WHITE
	)

	update_timer_display()

	create_board()

	var button_y = screen.y - 65

	var undo_button = create_button(
		"UNDO",
		Vector2(screen.x * 0.12, button_y),
		Vector2(screen.x * 0.22, 45),
		15
	)

	undo_button.pressed.connect(undo_move)

	var restart_button = create_button(
		"RESTART",
		Vector2(screen.x * 0.39, button_y),
		Vector2(screen.x * 0.22, 45),
		15
	)

	restart_button.pressed.connect(restart_game)

	var levels_button = create_button(
		"LEVELS",
		Vector2(screen.x * 0.66, button_y),
		Vector2(screen.x * 0.22, 45),
		15
	)

	levels_button.pressed.connect(show_level_select)

	update_progress()


# =========================================================
# CREATE BOARD
# =========================================================

func create_board():

	board = GridContainer.new()

	board.columns = grid_size

	board.add_theme_constant_override(
		"h_separation",
		tile_gap
	)

	board.add_theme_constant_override(
		"v_separation",
		tile_gap
	)

	var board_width = (
		grid_size * tile_size +
		(grid_size - 1) * tile_gap
	)

	var screen = get_viewport_rect().size

	board.position = Vector2(
		(screen.x - board_width) / 2,
		(screen.y - board_width) / 2 + 35
	)

	add_child(board)

	tiles.clear()

	for index in range(grid_size * grid_size):

		var tile = Button.new()

		tile.custom_minimum_size = Vector2(
			tile_size,
			tile_size
		)

		tile.size = Vector2(
			tile_size,
			tile_size
		)

		tile.focus_mode = Control.FOCUS_NONE

		tile.add_theme_font_size_override(
			"font_size",
			maxi(14, int(tile_size * 0.35))
		)

		tile.add_theme_color_override(
			"font_color",
			WHITE
		)

		tile.add_theme_color_override(
			"font_disabled_color",
			Color("#999999")
		)

		if obstacle_cells.has(index):

			tile.text = "X"
			tile.disabled = true

		else:

			var checkpoint = get_number(index)

			if checkpoint > 0:
				tile.text = str(checkpoint)
			else:
				tile.text = ""

		board.add_child(tile)
		tiles.append(tile)

		update_tile(index)

	update_all_tiles()


# =========================================================
# GET CHECKPOINT
# =========================================================

func get_number(index: int) -> int:

	if number_positions.has(index):
		return int(number_positions[index])

	return 0


# =========================================================
# MOUSE AND TOUCH INPUT
# =========================================================

func _input(event):

	if completed:
		return

	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_LEFT:

			if event.pressed:

				dragging = true

				var index = get_tile_at_position(
					get_global_mouse_position()
				)

				if index != -1:
					try_add_cell(index)

			else:

				dragging = false

	elif event is InputEventMouseMotion:

		if dragging:

			var index = get_tile_at_position(
				get_global_mouse_position()
			)

			if index != -1:
				try_add_cell(index)

	elif event is InputEventScreenTouch:

		if event.pressed:

			dragging = true

			var index = get_tile_at_position(
				event.position
			)

			if index != -1:
				try_add_cell(index)

		else:

			dragging = false

	elif event is InputEventScreenDrag:

		if dragging:

			var index = get_tile_at_position(
				event.position
			)

			if index != -1:
				try_add_cell(index)


func get_tile_at_position(position: Vector2) -> int:

	for i in range(tiles.size()):

		var tile = tiles[i]

		if tile.get_global_rect().has_point(position):
			return i

	return -1


# =========================================================
# ADD CELL
# =========================================================

func try_add_cell(index: int):

	if completed:
		return

	if index < 0 or index >= tiles.size():
		return

	if obstacle_cells.has(index):
		return

	if path.has(index):
		return

	# Start at number 1.

	if path.is_empty():

		if get_number(index) != 1:
			return

		path.append(index)

		timer_running = true
		move_count += 1

		update_all_tiles()
		update_progress()
		update_timer_display()

		return

	var previous_cell = path[
		path.size() - 1
	]

	if not is_adjacent(previous_cell, index):
		return

	var checkpoint = get_number(index)

	if checkpoint > 0:

		if checkpoint != next_number:
			return

		next_number += 1

	path.append(index)

	move_count += 1

	update_all_tiles()
	update_progress()
	update_timer_display()

	check_completion()


# =========================================================
# FOUR-DIRECTION MOVEMENT
# =========================================================

func is_adjacent(a: int, b: int) -> bool:

	var row_a = int(a / grid_size)
	var col_a = a % grid_size

	var row_b = int(b / grid_size)
	var col_b = b % grid_size

	return (
		abs(row_a - row_b) +
		abs(col_a - col_b)
	) == 1


# =========================================================
# TILE STYLING
# =========================================================

func make_tile_style(color: Color) -> StyleBoxFlat:

	var style = StyleBoxFlat.new()

	style.bg_color = color
	style.set_corner_radius_all(8)

	return style


func update_tile(index: int):

	if index < 0 or index >= tiles.size():
		return

	var tile = tiles[index]

	if obstacle_cells.has(index):

		tile.text = "X"

		tile.add_theme_stylebox_override(
			"normal",
			make_tile_style(OBSTACLE_COLOR)
		)

		return

	var checkpoint = get_number(index)

	if checkpoint > 0:
		tile.text = str(checkpoint)
	else:
		tile.text = ""

	var color = EMPTY_COLOR

	if path.has(index):
		color = PATH_COLOR

	if checkpoint == 1:
		color = START_COLOR

	if checkpoint == checkpoint_count:
		color = FINISH_COLOR

	if path.has(index) and checkpoint > 0:
		color = PATH_COLOR

	tile.add_theme_stylebox_override(
		"normal",
		make_tile_style(color)
	)

	tile.add_theme_stylebox_override(
		"hover",
		make_tile_style(color.lightened(0.15))
	)

	tile.add_theme_stylebox_override(
		"pressed",
		make_tile_style(color.darkened(0.15))
	)


func update_all_tiles():

	for i in range(tiles.size()):
		update_tile(i)


# =========================================================
# PROGRESS
# =========================================================

func update_progress():

	if progress_label == null:
		return

	progress_label.text = (
        "FILLED: %d / %d     MOVES: %d     NEXT: %d"
	) % [
		path.size(),
		playable_path.size(),
		move_count,
		next_number
	]


func update_status(message: String):

	if status_label != null:
		status_label.text = message


# =========================================================
# STARS
# =========================================================

func calculate_stars() -> int:

	var allowed_three_star_time = (
		playable_path.size() * 2.0
	)

	var allowed_two_star_time = (
		playable_path.size() * 4.0
	)

	if elapsed_time <= allowed_three_star_time:
		return 3

	elif elapsed_time <= allowed_two_star_time:
		return 2

	return 1


# =========================================================
# COMPLETION
# =========================================================

func check_completion():

	if path.size() != playable_path.size():
		return

	if next_number <= checkpoint_count:
		return

	completed = true
	dragging = false
	timer_running = false

	completed_stars = calculate_stars()

	new_record = false

	if best_time < 0 or elapsed_time < best_time:

		best_time = elapsed_time
		new_record = true

		save_best_time(
			current_level,
			best_time
		)

	if current_level < TOTAL_LEVELS:

		if current_level >= unlocked_level:
			unlocked_level = current_level + 1

		save_progress()

	update_status("LEVEL COMPLETED!")

	update_timer_display()

	show_completion_buttons()


# =========================================================
# COMPLETION SCREEN
# =========================================================

func show_completion_buttons():

	var screen = get_viewport_rect().size

	var stars_text = ""

	for i in range(completed_stars):
		stars_text += "★ "

	var result_text = "%s\nTIME: %s\nMOVES: %d" % [
		stars_text,
		format_time(elapsed_time),
		move_count
	]

	if new_record:
		result_text += "\nNEW PERSONAL BEST!"

	create_label(
		result_text,
		Vector2(0, screen.y - 230),
		Vector2(screen.x, 100),
		20,
		GOLD
	)

	var next_button = create_button(
		"NEXT LEVEL",
		Vector2(screen.x / 2 - 110, screen.y - 125),
		Vector2(220, 48),
		18
	)

	if current_level < TOTAL_LEVELS:

		next_button.pressed.connect(
			go_to_next_level
		)

	else:

		next_button.text = "FINISH"

		next_button.pressed.connect(
			show_final_victory
		)

	var levels_button = create_button(
		"LEVEL SELECT",
		Vector2(screen.x / 2 - 110, screen.y - 70),
		Vector2(220, 42),
		16
	)

	levels_button.pressed.connect(show_level_select)


# =========================================================
# NEXT LEVEL
# =========================================================

func go_to_next_level():

	if current_level < TOTAL_LEVELS:
		start_level(current_level + 1)
	else:
		show_final_victory()


# =========================================================
# FINAL VICTORY
# =========================================================

func show_final_victory():

	clear_screen()
	create_background()

	var screen = get_viewport_rect().size

	create_label(
		"YOU DID IT!",
		Vector2(0, screen.y * 0.25),
		Vector2(screen.x, 80),
		42
	)

	create_label(
		"ALL 100 LEVELS COMPLETED",
		Vector2(0, screen.y * 0.25 + 80),
		Vector2(screen.x, 45),
		19,
		GOLD
	)

	var menu_button = create_button(
		"MAIN MENU",
		Vector2(screen.x / 2 - 110, screen.y * 0.60),
		Vector2(220, 55),
		20
	)

	menu_button.pressed.connect(show_main_menu)


# =========================================================
# UNDO
# =========================================================

func undo_move():

	if completed:
		return

	if path.is_empty():
		return

	var removed_cell = path.pop_back()

	move_count = maxi(
		0,
		move_count - 1
	)

	var checkpoint = get_number(removed_cell)

	if checkpoint > 0:
		next_number = checkpoint

	if path.is_empty():
		timer_running = false

	update_all_tiles()
	update_progress()
	update_timer_display()

	update_status("CONTINUE YOUR PATH")


# =========================================================
# RESTART
# =========================================================

func restart_game():
	start_level(current_level)
