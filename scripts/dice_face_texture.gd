class_name DiceFaceTexture
extends RefCounted

const SIZE := 128

## 눈금 값별 점(핍) 배치(0~1 정규화 좌표)
const PIP_LAYOUTS := {
	1: [Vector2(0.5, 0.5)],
	2: [Vector2(0.28, 0.28), Vector2(0.72, 0.72)],
	3: [Vector2(0.25, 0.25), Vector2(0.5, 0.5), Vector2(0.75, 0.75)],
	4: [Vector2(0.28, 0.28), Vector2(0.72, 0.28), Vector2(0.28, 0.72), Vector2(0.72, 0.72)],
	5: [Vector2(0.25, 0.25), Vector2(0.75, 0.25), Vector2(0.5, 0.5), Vector2(0.25, 0.75), Vector2(0.75, 0.75)],
	6: [Vector2(0.28, 0.2), Vector2(0.72, 0.2), Vector2(0.28, 0.5), Vector2(0.72, 0.5), Vector2(0.28, 0.8), Vector2(0.72, 0.8)],
}

## 눈금 값에 해당하는 주사위 면 텍스처를 만든다
static func make(value: int) -> ImageTexture:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	img.fill(Color(0.95, 0.95, 0.92))
	var radius := SIZE * 0.09
	for pip in PIP_LAYOUTS[value]:
		_draw_dot(img, pip * SIZE, radius)
	return ImageTexture.create_from_image(img)

static func _draw_dot(img: Image, center: Vector2, radius: float) -> void:
	var min_x := int(max(0, center.x - radius))
	var max_x := int(min(SIZE - 1, center.x + radius))
	var min_y := int(max(0, center.y - radius))
	var max_y := int(min(SIZE - 1, center.y + radius))
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			if Vector2(x, y).distance_to(center) <= radius:
				img.set_pixel(x, y, Color(0.15, 0.15, 0.15))
