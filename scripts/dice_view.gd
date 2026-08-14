class_name DiceView
extends Node2D

const SIZE := 64.0
const PIP_RADIUS := 5.0

var value: int = 1

## 눈금 값별 점 배치(0~1 정규화 좌표)
const PIP_LAYOUTS := {
	1: [Vector2(0.5, 0.5)],
	2: [Vector2(0.25, 0.25), Vector2(0.75, 0.75)],
	3: [Vector2(0.25, 0.25), Vector2(0.5, 0.5), Vector2(0.75, 0.75)],
	4: [Vector2(0.25, 0.25), Vector2(0.75, 0.25), Vector2(0.25, 0.75), Vector2(0.75, 0.75)],
	5: [Vector2(0.25, 0.25), Vector2(0.75, 0.25), Vector2(0.5, 0.5), Vector2(0.25, 0.75), Vector2(0.75, 0.75)],
	6: [Vector2(0.25, 0.2), Vector2(0.75, 0.2), Vector2(0.25, 0.5), Vector2(0.75, 0.5), Vector2(0.25, 0.8), Vector2(0.75, 0.8)],
}

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(SIZE, SIZE)), Color(1, 1, 1), true)
	draw_rect(Rect2(Vector2.ZERO, Vector2(SIZE, SIZE)), Color(0.2, 0.2, 0.2), false, 3.0)
	for pip in PIP_LAYOUTS.get(value, []):
		draw_circle(pip * SIZE, PIP_RADIUS, Color(0.2, 0.2, 0.2))

func show_value(v: int) -> void:
	value = v
	queue_redraw()

## 짧게 눈금이 바뀌는 애니메이션을 재생한 뒤 final_value로 멈춘다
func play_roll(final_value: int) -> void:
	for i in range(8):
		show_value(randi_range(1, 6))
		await get_tree().create_timer(0.05).timeout
	show_value(final_value)
