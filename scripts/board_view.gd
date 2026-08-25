class_name BoardView
extends Node2D

## 보드 디자인 — Inspector에서 바로 바꿀 수 있음(칸 크기는 한 변 7칸 기준값)
@export var tile_size: float = 52.0
@export var tile_gap: float = 4.0
@export var token_color: Color = Color(0.1, 0.1, 0.1)
@export var token_size_ratio: float = 0.3
@export var icon_size_ratio: float = 0.62

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

## tile_size가 딱 맞게 설계된 기준 변 길이. 보드가 이보다 커지면 칸을 비례해서 줄여 화면 크기를 유지한다
const BASE_SIDE_LENGTH := 7.0

var board_data: BoardData
var token: ColorRect
var _grid_span: int
var _cell_size: float
var _cell_gap: float
var _move_sound: AudioStreamPlayer

func _ready() -> void:
	_move_sound = AudioStreamPlayer.new()
	_move_sound.stream = load("res://assets/audio/piece_move.wav")
	add_child(_move_sound)

## 보드 데이터로 새로 그린다(이미 그려진 보드가 있으면 지우고 다시 그림 — 바퀴마다 커진 보드로 교체할 때 사용)
func setup(data: BoardData) -> void:
	## _move_sound는 _ready()에서 만든 재생기라 보드를 다시 그릴 때 같이 지우면 안 됨
	for child in get_children():
		if child != _move_sound:
			child.free()

	board_data = data
	_grid_span = board_data.SIDE_LENGTH
	var scale_factor := BASE_SIDE_LENGTH / float(_grid_span)
	_cell_size = tile_size * scale_factor
	_cell_gap = tile_gap * scale_factor

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
		cell.size = Vector2(_cell_size, _cell_size)
		cell.position = _grid_to_pixel(_index_to_grid(i))
		cell.color = _cell_color(board_data.get_cell_type(i))
		add_child(cell)

		var icon := TextureRect.new()
		icon.texture = load(ICON_PATHS[board_data.get_cell_type(i)])
		## 이걸 꺼야 텍스처 원본 크기를 무시하고 아래 size 값을 실제로 따른다
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size = Vector2(_cell_size, _cell_size) * icon_size_ratio
		icon.position = Vector2(_cell_size, _cell_size) * (1.0 - icon_size_ratio) * 0.5
		cell.add_child(icon)

		var label := Label.new()
		label.text = str(i)
		label.position = Vector2(2, 0)
		label.add_theme_font_size_override("font_size", 10)
		cell.add_child(label)

func _create_token() -> void:
	token = ColorRect.new()
	token.size = Vector2(_cell_size, _cell_size) * token_size_ratio
	token.color = token_color
	add_child(token)
	move_token(0)

## 칸 아이콘이 중앙에 있으므로, 토큰은 아이콘을 가리지 않도록 칸 오른쪽 아래 구석에 배치한다
func _token_position_in_cell(index: int) -> Vector2:
	var cell_pos := _grid_to_pixel(_index_to_grid(index))
	return cell_pos + Vector2(_cell_size, _cell_size) - token.size - Vector2(3.0, 3.0)

## 플레이어 토큰을 index 칸 위치로 즉시 옮긴다
func move_token(index: int) -> void:
	token.position = _token_position_in_cell(index)

## start_index에서 steps칸만큼 한 칸씩 순서대로 이동하는 애니메이션을 재생한다
func animate_move(start_index: int, steps: int) -> void:
	for i in range(1, steps + 1):
		var index := wrapi(start_index + i, 0, board_data.TOTAL_CELLS)
		var target := _token_position_in_cell(index)
		_move_sound.play()
		var tween := create_tween()
		tween.tween_property(token, "position", target, 0.12)
		await tween.finished

func _grid_to_pixel(grid: Vector2i) -> Vector2:
	return Vector2(grid.x, grid.y) * (_cell_size + _cell_gap)

## 보드 인덱스를 정사각형 테두리 좌표로 변환한다(시계방향, 좌상단이 0번)
## BoardData의 꼭짓점 인덱스(0·SIDE_LENGTH·SIDE_LENGTH*2·SIDE_LENGTH*3)와 정확히 일치하도록 계산한다
func _index_to_grid(index: int) -> Vector2i:
	if index <= _grid_span:
		return Vector2i(index, 0)
	elif index <= _grid_span * 2:
		return Vector2i(_grid_span, index - _grid_span)
	elif index <= _grid_span * 3:
		return Vector2i(_grid_span - (index - _grid_span * 2), _grid_span)
	else:
		return Vector2i(0, _grid_span - (index - _grid_span * 3))
