
extends Control

# ==========================================
# GRIDTRAIL - YORQO
# Full Board Puzzle Prototype
# ==========================================

const GRID_SIZE = 5
const TILE_SIZE = 72
const TILE_GAP = 8

const COLOR_BACKGROUND = Color("#10111d")
const COLOR_EMPTY = Color("#272a3c")
const COLOR_PATH = Color("#7545d6")
const COLOR_START = Color("#087f5b")
const COLOR_FINISH = Color("#087ca5")
const COLOR_NUMBER = Color("#ffffff")
const COLOR_MUTED = Color("#a9a4c4")

var numbers = {
	0: 1,
	6: 2,
	12: 3,
	18: 4,
	24: 5
}

var board: GridContainer
var tiles: Array[Button] = []
var path: Array[int] = []

var next_number = 2
var dragging = false
var completed = false

var status_label: Label


func _ready():
	create_background()
	create_interface()
	create_board()
	update_status("Start at number 1")


# ==========================================
# BACKGROUND
# ==========================================

func create_background():

	var background = ColorRect.new()

	background.color = COLOR_BACKGROUND
	background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	background.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(background)


# ==========================================
# INTERFACE
# ==========================================

func create_interface():

	var title = Label.new()

	title.text = "GRIDTRAIL"
	title.position = Vector2(0, 35)
	title.size = Vector2(1280, 55)

	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	title.add_theme_color_override("font_color", COLOR_NUMBER)
	title.add_theme_font_size_override("font_size", 38)

	add_child(title)

	var subtitle = Label.new()

	subtitle.text = "CONNECT • SOLVE • WIN"
	subtitle.position = Vector2(0, 88)
	subtitle.size = Vector2(1280, 30)

	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	subtitle.add_theme_color_override("font_color", COLOR_MUTED)
	subtitle.add_theme_font_size_override("font_size", 15)

	add_child(subtitle)

	status_label = Label.new()

	status_label.position = Vector2(0, 165)
	status_label.size = Vector2(1280, 35)

	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	status_label.add_theme_font_size_override("font_size", 20)
	status_label.add_theme_color_override("font_color", COLOR_NUMBER)

	add_child(status_label)

	var restart_button = Button.new()

	restart_button.text = "RESTART"
	restart_button.position = Vector2(480, 660)
	restart_button.size = Vector2(140, 45)

	restart_button.pressed.connect(restart_game)

	add_child(restart_button)

	var undo_button = Button.new()

	undo_button.text = "UNDO"
	undo_button.position = Vector2(660, 660)
	undo_button.size = Vector2(140, 45)

	undo_button.pressed.connect(undo_move)

	add_child(undo_button)


# ==========================================
# CREATE GRID
# ==========================================

func create_board():

	board = GridContainer.new()

	board.columns = GRID_SIZE

	board.add_theme_constant_override("h_separation", TILE_GAP)
	board.add_theme_constant_override("v_separation", TILE_GAP)

	board.position = Vector2(436, 235)

	add_child(board)

	for index in range(GRID_SIZE * GRID_SIZE):

		var tile = Button.new()

		tile.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)

		tile.add_theme_font_size_override("font_size", 27)

		tile.add_theme_color_override("font_color", COLOR_NUMBER)
		tile.add_theme_color_override("font_hover_color", COLOR_NUMBER)
		tile.add_theme_color_override("font_pressed_color", COLOR_NUMBER)
		tile.add_theme_color_override("font_disabled_color", COLOR_NUMBER)

		tile.text = str(get_number(index)) if get_number(index) > 0 else ""

		board.add_child(tile)

		tiles.append(tile)

		tile.gui_input.connect(_on_tile_input.bind(index))

		update_tile(index)


# ==========================================
# NUMBER INFORMATION
# ==========================================

func get_number(index: int) -> int:

	return numbers.get(index, 0)


# ==========================================
# MOUSE AND TOUCH INPUT
# ==========================================

func _on_tile_input(event: InputEvent, index: int):

	if completed:
		return

	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_LEFT:

			if event.pressed:

				dragging = true
				try_add_cell(index)

			else:

				dragging = false

	elif event is InputEventMouseMotion:

		if dragging:
			try_add_cell(index)

	elif event is InputEventScreenTouch:

		if event.pressed:

			dragging = true
			try_add_cell(index)

		else:

			dragging = false

	elif event is InputEventScreenDrag:

		if dragging:
			try_add_cell(index)


# ==========================================
# ADD CELL TO PATH
# ==========================================

func try_add_cell(index: int):

	if path.has(index):
		return

	if path.is_empty():

		if get_number(index) != 1:
			update_status("Start at number 1")
			return

		path.append(index)

		update_all_tiles()
		update_status("Connect number 2")

		return

	var previous_index = path[-1]

	if not is_adjacent(previous_index, index):
		return

	var number = get_number(index)

	if number > 0 and number != next_number:

		update_status("Connect number " + str(next_number))
		return

	path.append(index)

	if number > 0:
		next_number += 1

	update_all_tiles()

	if next_number > 5:
		check_completion()
	else:
		update_status(
			"Connect number " + str(next_number)
		)


# ==========================================
# FOUR-DIRECTION MOVEMENT
# ==========================================

func is_adjacent(a: int, b: int) -> bool:

	var row_a = int(a / GRID_SIZE)
	var col_a = a % GRID_SIZE

	var row_b = int(b / GRID_SIZE)
	var col_b = b % GRID_SIZE

	return abs(row_a - row_b) + abs(col_a - col_b) == 1


# ==========================================
# CHECK ALL SQUARES
# ==========================================

func check_completion():

	if path.size() == GRID_SIZE * GRID_SIZE:

		completed = true
		dragging = false

		update_status("YOU WIN! All 25 squares completed!")

	else:

		update_status(
			"Number 5 reached! Fill all " +
			str(GRID_SIZE * GRID_SIZE) +
            " squares before winning."
		)


# ==========================================
# TILE APPEARANCE
# ==========================================

func update_tile(index: int):

	var tile = tiles[index]
	var number = get_number(index)

	tile.add_theme_stylebox_override(
		"normal",
		create_tile_style(index)
	)

	tile.add_theme_stylebox_override(
		"hover",
		create_tile_style(index)
	)

	tile.add_theme_stylebox_override(
		"pressed",
		create_tile_style(index)
	)

	tile.add_theme_stylebox_override(
		"disabled",
		create_tile_style(index)
	)

	tile.add_theme_color_override("font_color", COLOR_NUMBER)
	tile.add_theme_color_override("font_disabled_color", COLOR_NUMBER)

	tile.text = str(number) if number > 0 else ""


func create_tile_style(index: int) -> StyleBoxFlat:

	var style = StyleBoxFlat.new()

	if path.has(index):

		style.bg_color = COLOR_PATH

	elif get_number(index) == 1:

		style.bg_color = COLOR_START

	elif get_number(index) == 5:

		style.bg_color = COLOR_FINISH

	else:

		style.bg_color = COLOR_EMPTY

	style.set_corner_radius_all(10)

	return style


func update_all_tiles():

	for index in range(tiles.size()):
		update_tile(index)


# ==========================================
# STATUS
# ==========================================

func update_status(message: String):

	status_label.text = message


# ==========================================
# UNDO
# ==========================================

func undo_move():

	if completed or path.is_empty():
		return

	var removed_index = path.pop_back()

	var number = get_number(removed_index)

	if number > 0:
		next_number = number

	dragging = false

	update_all_tiles()

	if path.is_empty():

		update_status("Start at number 1")

	else:

		update_status("Connect number " + str(next_number))


# ==========================================
# RESTART
# ==========================================

func restart_game():

	path.clear()

	next_number = 2

	dragging = false
	completed = false

	update_all_tiles()

	update_status("Start at number 1")
