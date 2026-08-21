class_name BoardData
extends RefCounted

## 보드 칸의 종류
enum CellType {
	START,   ## 출발칸(보스 전투)
	CORNER,  ## 일반 꼭짓점칸(전투)
	STAT,    ## 스탯칸
	EVENT,   ## 이벤트칸(스토리 텍스트)
	RANDOM,  ## 랜덤칸(순수 수치 변동)
	SKILL,   ## 스킬칸
}

## 한 변의 칸 수(그 변의 시작 꼭짓점 포함, 다음 꼭짓점은 제외). 바퀴가 늘수록 커짐(생성자로 전달)
var SIDE_LENGTH: int
var TOTAL_CELLS: int

var cells: Array[CellType] = []

## side_length: 한 변의 칸 수(꼭짓점 포함). 기본 7칸 = 총 28칸
func _init(side_length: int = 7) -> void:
	SIDE_LENGTH = side_length
	TOTAL_CELLS = SIDE_LENGTH * 4
	cells = _build_cells()

## 꼭짓점(4개) 위치는 고정하고, 나머지 칸은 스탯:이벤트:랜덤:스킬 = 3:1:1:1 비율로 채운 뒤 무작위로 섞어서 배치한다
func _build_cells() -> Array[CellType]:
	var per_side := SIDE_LENGTH - 1
	var non_corner_total := per_side * 4

	var stat_count := int(round(non_corner_total * 0.5))
	var remaining := non_corner_total - stat_count
	var event_count := remaining / 3
	var random_count := remaining / 3
	var skill_count := remaining - event_count - random_count

	var side_cells: Array[CellType] = []
	for i in range(stat_count):
		side_cells.append(CellType.STAT)
	for i in range(event_count):
		side_cells.append(CellType.EVENT)
	for i in range(random_count):
		side_cells.append(CellType.RANDOM)
	for i in range(skill_count):
		side_cells.append(CellType.SKILL)
	side_cells.shuffle()

	var result: Array[CellType] = []
	var side_cell_index := 0
	for side in range(4):
		result.append(CellType.START if side == 0 else CellType.CORNER)
		for i in range(per_side):
			result.append(side_cells[side_cell_index])
			side_cell_index += 1
	return result

func get_cell_type(index: int) -> CellType:
	return cells[wrapi(index, 0, TOTAL_CELLS)]

func is_corner(index: int) -> bool:
	var type := get_cell_type(index)
	return type == CellType.START or type == CellType.CORNER

static func cell_type_name(type: CellType) -> String:
	match type:
		CellType.START: return "출발"
		CellType.CORNER: return "전투"
		CellType.STAT: return "스탯"
		CellType.EVENT: return "이벤트"
		CellType.RANDOM: return "랜덤"
		CellType.SKILL: return "스킬"
	return "?"
