class_name PlayerToken
extends RefCounted

## 현재 보드 칸 인덱스(0 ~ BoardData.TOTAL_CELLS - 1)
var board_index: int = 0
## 출발칸을 완주한 횟수
var lap_count: int = 0

## steps만큼 이동하고, 이동 경로에서 지나친 꼭짓점 칸 인덱스 목록을 반환한다
## (출발칸을 다시 지나가면 lap_count가 1 증가한다)
func move(steps: int, board_data: BoardData) -> Array[int]:
	var passed_corners: Array[int] = []
	var start := board_index
	for i in range(1, steps + 1):
		var cell_index := wrapi(start + i, 0, board_data.TOTAL_CELLS)
		if board_data.is_corner(cell_index):
			passed_corners.append(cell_index)
	if start + steps >= board_data.TOTAL_CELLS:
		lap_count += 1
	board_index = wrapi(start + steps, 0, board_data.TOTAL_CELLS)
	return passed_corners
