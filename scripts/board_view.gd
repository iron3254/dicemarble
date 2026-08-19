class_name BoardView
extends Node2D

const TILE_SIZE := 52.0
const TILE_GAP := 4.0
const GRID_SPAN := 7 # 8칸(0~7) 배치를 위한 좌표 범위

const CELL_COLORS := {
	BoardData.CellType.START: Color(1.0, 0.85, 0.2),
	BoardData.CellType.CORNER: Color(1.0, 0.55, 0.2),
	BoardData.CellType.STAT: Color(0.55, 0.75, 1.0),
	BoardData.CellType.EVENT: Color(0.55, 0.9, 0.55),
	BoardData.CellType.RANDOM: Color(0.8, 0.6, 1.0),
	BoardData.CellType.SKILL: Color(1.0, 0.6, 0.75),
}

var board_data: BoardData
var token: ColorRect

func setup(data: BoardData) -> void:
	board_data = data
	_draw_cells()
	_create_token()

func _draw_cells() -> void:
	for i in range(board_data.TOTAL_CELLS):
		var cell := ColorRect.new()
		cell.size = Vector2(TILE_SIZE, TILE_SIZE)
		cell.position = _grid_to_pixel(_index_to_grid(i))
		cell.color = CELL_COLORS[board_data.get_cell_type(i)]
		add_child(cell)

		var label := Label.new()
		label.text = "%d\n%s" % [i, BoardData.cell_type_name(board_data.get_cell_type(i))]
		label.position = Vector2(2, 2)
		label.add_theme_font_size_override("font_size", 10)
		cell.add_child(label)

func _create_token() -> void:
	token = ColorRect.new()
	token.size = Vector2(TILE_SIZE * 0.4, TILE_SIZE * 0.4)
	token.color = Color(0.1, 0.1, 0.1)
	add_child(token)
	move_token(0)

## 플레이어 토큰을 index 칸 위치로 즉시 옮긴다
func move_token(index: int) -> void:
	var cell_pos := _grid_to_pixel(_index_to_grid(index))
	token.position = cell_pos + Vector2(TILE_SIZE, TILE_SIZE) * 0.3

## start_index에서 steps칸만큼 한 칸씩 순서대로 이동하는 애니메이션을 재생한다
func animate_move(start_index: int, steps: int) -> void:
	for i in range(1, steps + 1):
		var index := wrapi(start_index + i, 0, board_data.TOTAL_CELLS)
		var cell_pos := _grid_to_pixel(_index_to_grid(index))
		var target := cell_pos + Vector2(TILE_SIZE, TILE_SIZE) * 0.3
		var tween := create_tween()
		tween.tween_property(token, "position", target, 0.12)
		await tween.finished

func _grid_to_pixel(grid: Vector2i) -> Vector2:
	return Vector2(grid.x, grid.y) * (TILE_SIZE + TILE_GAP)

## 보드 인덱스를 8x8 테두리 좌표로 변환한다(시계방향, 좌상단이 0번)
## BoardData의 꼭짓점 인덱스(0·7·14·21)와 정확히 일치하도록 계산한다
static func _index_to_grid(index: int) -> Vector2i:
	if index <= GRID_SPAN:
		return Vector2i(index, 0)
	elif index <= GRID_SPAN * 2:
		return Vector2i(GRID_SPAN, index - GRID_SPAN)
	elif index <= GRID_SPAN * 3:
		return Vector2i(GRID_SPAN - (index - GRID_SPAN * 2), GRID_SPAN)
	else:
		return Vector2i(0, GRID_SPAN - (index - GRID_SPAN * 3))
