class_name DialogView
extends Control

## 제목 + 본문 + 선택지 버튼을 띄우고, 플레이어가 고른 선택지 번호를 돌려주는 범용 창
## (이벤트, 버프 선택, 막 클리어 안내, 게임 오버 등에 사용)

signal _option_picked(index: int)

var _title: Label
var _body: Label
var _options_box: VBoxContainer

func _ready() -> void:
	UiKit.fill(self)
	visible = false
	add_child(UiKit.dim())

	var center := CenterContainer.new()
	UiKit.fill(center)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(640, 0)
	var style := UiKit.box(Color(0.12, 0.12, 0.16), 14, Color(0.85, 0.7, 0.35), 3)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	_title = UiKit.label("", 30, Color(1.0, 0.85, 0.4))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)

	_body = UiKit.wrap_label("", 18)
	_body.custom_minimum_size = Vector2(584, 0)
	box.add_child(_body)

	_options_box = VBoxContainer.new()
	_options_box.add_theme_constant_override("separation", 8)
	box.add_child(_options_box)

## 창을 띄우고 선택될 때까지 기다린 뒤 고른 번호를 반환한다. disabled[i]가 true면 그 선택지는 못 고름
func ask(title: String, body: String, options: Array, disabled: Array = []) -> int:
	_title.text = title
	_body.text = body
	_body.visible = body != ""
	for child in _options_box.get_children():
		_options_box.remove_child(child)
		child.queue_free()
	for i in range(options.size()):
		var b := UiKit.button(options[i], 18)
		b.custom_minimum_size = Vector2(0, 44)
		UiKit.color_button(b, Color(0.25, 0.3, 0.42))
		b.disabled = i < disabled.size() and disabled[i]
		b.pressed.connect(_on_option_pressed.bind(i))
		_options_box.add_child(b)
	visible = true
	var picked: int = await _option_picked
	visible = false
	return picked

## 버튼의 pressed 처리 도중에 그 버튼을 지우지 않도록, 신호를 한 프레임 뒤로 미뤄서 보낸다
func _on_option_pressed(index: int) -> void:
	_option_picked.emit.call_deferred(index)
