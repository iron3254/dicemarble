class_name MapData
extends RefCounted

## 한 막의 갈림길 지도. 아래(0번 줄)에서 위로 올라가며, 마지막에 보스 칸이 있다
## 규칙: 길로 이어진 칸으로만 갈 수 있고, 지나간 칸으로는 돌아갈 수 없다

enum NodeType { BATTLE, SHOP, EVENT, BOSS }

const COLUMNS := 4
## 시작점에서 출발하는 길 개수(길이 서로 합쳐지거나 갈라지며 갈림길이 생김)
const PATH_COUNT := 3
## 첫 줄(전투 고정)과 보스 직전 줄(상점 고정)을 뺀 칸의 종류 가중치
const TYPE_WEIGHTS := {NodeType.BATTLE: 5, NodeType.EVENT: 3, NodeType.SHOP: 2}

## 보스 칸을 뺀 일반 칸 줄 수(= 이 막에서 지나는 칸 수)
var rows: int
## 각 칸: {"row": 줄, "col": 열, "type": NodeType, "next": 이어진 다음 칸 인덱스 목록}
var nodes: Array = []
var boss_index := -1

func _init(p_rows: int) -> void:
	rows = p_rows
	_generate()

func _generate() -> void:
	var grid := {}
	## 줄마다 이미 그어진 길(Vector2i(출발 열, 도착 열)) — 길이 서로 X자로 엇갈리지 않게 검사용
	var edges_by_row := {}
	var start_cols := range(COLUMNS)
	start_cols.shuffle()
	for p in range(PATH_COUNT):
		var col: int = start_cols[p % COLUMNS]
		for row in range(rows):
			var index := _get_or_add(grid, row, col)
			if row == rows - 1:
				break
			if not edges_by_row.has(row):
				edges_by_row[row] = []
			var next_col := _pick_next_col(edges_by_row[row], col)
			_link(index, _get_or_add(grid, row + 1, next_col))
			edges_by_row[row].append(Vector2i(col, next_col))
			col = next_col

	boss_index = nodes.size()
	nodes.append({"row": rows, "col": -1, "type": NodeType.BOSS, "next": []})
	for i in range(boss_index):
		if nodes[i]["row"] == rows - 1:
			_link(i, boss_index)
	_assign_types()

func _get_or_add(grid: Dictionary, row: int, col: int) -> int:
	var key := Vector2i(row, col)
	if not grid.has(key):
		grid[key] = nodes.size()
		nodes.append({"row": row, "col": col, "type": NodeType.BATTLE, "next": []})
	return grid[key]

func _link(from_index: int, to_index: int) -> void:
	var next: Array = nodes[from_index]["next"]
	if not next.has(to_index):
		next.append(to_index)

## 왼쪽 위/위/오른쪽 위 중에서, 이미 있는 길과 X자로 엇갈리지 않는 칸을 고른다
func _pick_next_col(row_edges: Array, col: int) -> int:
	var candidates: Array = []
	for next_col in [col - 1, col, col + 1]:
		if next_col < 0 or next_col >= COLUMNS:
			continue
		var crosses := false
		for e in row_edges:
			if (e.x < col and e.y > next_col) or (e.x > col and e.y < next_col):
				crosses = true
				break
		if not crosses:
			candidates.append(next_col)
	if candidates.is_empty():
		return col
	return candidates.pick_random()

func _assign_types() -> void:
	for node in nodes:
		if node["type"] == NodeType.BOSS:
			continue
		if node["row"] == 0:
			node["type"] = NodeType.BATTLE
		elif node["row"] == rows - 1 and rows >= 3:
			node["type"] = NodeType.SHOP
		else:
			node["type"] = _weighted_type()

func _weighted_type() -> NodeType:
	var total := 0
	for t in TYPE_WEIGHTS:
		total += TYPE_WEIGHTS[t]
	var r := randi_range(1, total)
	for t in TYPE_WEIGHTS:
		r -= TYPE_WEIGHTS[t]
		if r <= 0:
			return t
	return NodeType.BATTLE

## 막을 시작할 때 고를 수 있는 칸들(일반 칸이 없는 최종막은 바로 보스)
func start_choices() -> Array:
	if rows == 0:
		return [boss_index]
	var result: Array = []
	for i in range(nodes.size()):
		if nodes[i]["row"] == 0:
			result.append(i)
	return result

static func type_name(type: NodeType) -> String:
	match type:
		NodeType.BATTLE: return "전투"
		NodeType.SHOP: return "상점"
		NodeType.EVENT: return "이벤트"
		NodeType.BOSS: return "보스"
	return "?"
