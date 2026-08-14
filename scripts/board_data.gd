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

## 한 변의 칸 수(그 변의 시작 꼭짓점 포함, 다음 꼭짓점은 제외)
const SIDE_LENGTH: int = 7
const TOTAL_CELLS: int = SIDE_LENGTH * 4

## 꼭짓점을 제외하고 한 변에 반복 배치할 사이드칸 순서(6칸: 스탯3/이벤트1/랜덤1/스킬1)
const SIDE_PATTERN: Array[CellType] = [
	CellType.STAT, CellType.STAT, CellType.EVENT,
	CellType.STAT, CellType.RANDOM, CellType.SKILL,
]

var cells: Array[CellType] = []

func _init() -> void:
	cells = _build_cells()

func _build_cells() -> Array[CellType]:
	var result: Array[CellType] = []
	for side in range(4):
		result.append(CellType.START if side == 0 else CellType.CORNER)
		result.append_array(SIDE_PATTERN)
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
