class_name UiKit
extends RefCounted

## 코드로 UI를 만들 때 반복되는 스타일/라벨/버튼 생성을 모아둔 도우미

## 둥근 모서리 + 테두리가 있는 배경 스타일
static func box(color: Color, radius: int = 8, border: Color = Color(0, 0, 0, 0), border_width: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	if border.a > 0.0:
		style.border_color = border
		style.set_border_width_all(border_width)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style

static func label(text: String, font_size: int = 16, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l

## 폭이 정해진 곳에서 줄바꿈되는 라벨
static func wrap_label(text: String, font_size: int = 16, color: Color = Color.WHITE) -> Label:
	var l := label(text, font_size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

static func button(text: String, font_size: int = 18) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", font_size)
	return b

## 버튼 하나에 상태별(기본/마우스 올림/누름/비활성) 배경색을 한 번에 입힌다
static func color_button(b: Button, color: Color, radius: int = 8) -> void:
	b.add_theme_stylebox_override("normal", box(color, radius))
	b.add_theme_stylebox_override("hover", box(color.lightened(0.15), radius, Color.WHITE))
	b.add_theme_stylebox_override("pressed", box(color.darkened(0.15), radius, Color.WHITE))
	b.add_theme_stylebox_override("disabled", box(color.darkened(0.55), radius))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

## 컨트롤을 화면 전체 크기로 펼친다
static func fill(c: Control) -> void:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

## 반투명 검은 배경(뒤쪽 클릭을 막는 역할도 함)
static func dim(alpha: float = 0.65) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0, 0, 0, alpha)
	fill(r)
	return r
