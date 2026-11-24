
extends Control

func _ready():
	print("GridTrail started successfully!")
	print("Day 2: Creating the puzzle grid")

	create_grid()


func create_grid():
	var board = GridContainer.new()

	board.columns = 5
	board.position = Vector2(440, 230)

	board.add_theme_constant_override("h_separation", 8)
	board.add_theme_constant_override("v_separation", 8)

	add_child(board)

	var numbers = [
		1, 0, 0, 0, 0,
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 2
	]

	for number in numbers:
		var tile = Button.new()

		if number == 0:
			tile.text = ""
		else:
			tile.text = str(number)

		tile.custom_minimum_size = Vector2(68, 68)
		tile.add_theme_font_size_override("font_size", 24)

		board.add_child(tile)
