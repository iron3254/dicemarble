class_name BoardView
extends Node2D

const GRID_SPAN := 7 # 8칸(0~7) 배치를 위한 좌표 범위 — 보드 구조와 맞물려 있어 여긴 건드리지 않는 게 안전함

## 보드 디자인 — Inspector에서 바로 바꿀 수 있음
@export var tile_size: float = 52.0
@export var tile_gap: float = 4.0
@export var token_color: Color = Color(0.1, 0.1, 0.1)
@export var token_size_ratio: float = 0.4

@export_group("칸 색상")
@export var start_color: Color = Color(1.0, 0.85, 0.2)
@export var corner_color: Color = Color(1.0, 0.55, 0.2)
@export var stat_color: Color = Color(0.55, 0.75, 1.0)
@export var event_color: Color = Color(0.55, 0.9, 0.55)
@export var random_color: Color = Color(0.8, 0.6, 1.0)
@export var skill_color: Color = Color(1.0, 0.6, 0.75)

const ICON_PATHS := {
	BoardData.CellType.START: "res://assets/icons/cell_start.svg",
	BoardData.CellType.CORNER: "res://assets/icons/cell_corner.svg",
	BoardData.CellType.STAT: "res://assets/icons/cell_stat.svg",
	BoardData.CellType.EVENT: "res://assets/icons/cell_event.svg",
	BoardData.CellType.RANDOM: "res://assets/icons/cell_random.svg",
	BoardData.CellType.SKILL: "res://assets/icons/cell_skill.svg",
}

var board_data: BoardData
var token: ColorRect

func setup(data: BoardData) -> void:
	board_data = data
	_draw_cells()
	_create_token()

func _cell_color(cell_type: BoardData.CellType) -> Color:
	match cell_type:
		BoardData.CellType.START: return start_color
		BoardData.CellType.CORNER: return corner_color
		BoardData.CellType.STAT: return stat_color
		BoardData.CellType.EVENT: return event_color
		BoardData.CellType.RANDOM: return random_color
		BoardData.CellType.SKILL: return skill_color
	return Color.WHITE

func _draw_cells() -> void:
	for i in range(board_data.TOTAL_CELLS):
		var cell := ColorRect.new()
		cell.size = Vector2(tile_size, tile_size)
		cell.position = _grid_to_pixel(_index_to_grid(i))
		cell.color = _cell_color(board_data.get_cell_type(i))
		add_child(cell)

		var icon := TextureRect.new()
		icon.texture = load(ICON_PATHS[board_data.get_cell_type(i)])
		icon.size = Vector2(tile_size, tile_size) * 0.62
		icon.position = Vector2(tile_size, tile_size) * (0.5 - 0.31)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cell.add_child(icon)

		var label := Label.new()
		label.text = str(i)
		label.position = Vector2(2, 0)
		label.add_theme_font_size_override("font_size", 10)
		cell.add_child(label)

func _create_token() -> void:
	token = ColorRect.new()
	token.size = Vector2(tile_size, tile_size) * token_size_ratio
	token.color = token_color
	add_child(token)
	move_token(0)

## 플레이어 토큰을 index 칸 위치로 즉시 옮긴다
func move_token(index: int) -> void:
	var cell_pos := _grid_to_pixel(_index_to_grid(index))
	token.position = cell_pos + Vector2(tile_size, tile_size) * 0.3

## start_index에서 steps칸만큼 한 칸씩 순서대로 이동하는 애니메이션을 재생한다
func animate_move(start_index: int, steps: int) -> void:
	for i in range(1, steps + 1):
		var index := wrapi(start_index + i, 0, board_data.TOTAL_CELLS)
		var cell_pos := _grid_to_pixel(_index_to_grid(index))
		var target := cell_pos + Vector2(tile_size, tile_size) * 0.3
		var tween := create_tween()
		tween.tween_property(token, "position", target, 0.12)
		await tween.finished

func _grid_to_pixel(grid: Vector2i) -> Vector2:
	return Vector2(grid.x, grid.y) * (tile_size + tile_gap)

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
