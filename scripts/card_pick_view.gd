class_name CardPickView
extends Control

## 카드 여러 장을 펼쳐 보여주고 한 장을 고르게 하는 창
## (전투 보상 3장 중 1장, 카드 제거/강화 대상 선택, 덱 보기)

signal _picked(index: int)

var _title: Label
var _flow: HFlowContainer
var _skip_button: Button

func _ready() -> void:
	UiKit.fill(self)
	visible = false
	add_child(UiKit.dim(0.8))

	var margin := MarginContainer.new()
	UiKit.fill(margin)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	margin.add_child(box)

	_title = UiKit.label("", 28, Color(1.0, 0.85, 0.4))
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)

	_flow = HFlowContainer.new()
	_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_flow.alignment = FlowContainer.ALIGNMENT_CENTER
	_flow.add_theme_constant_override("h_separation", 12)
	_flow.add_theme_constant_override("v_separation", 12)
	scroll.add_child(_flow)

	_skip_button = UiKit.button("건너뛰기", 20)
	_skip_button.custom_minimum_size = Vector2(220, 46)
	_skip_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UiKit.color_button(_skip_button, Color(0.3, 0.3, 0.36))
	_skip_button.pressed.connect(_on_pressed.bind(-1))
	box.add_child(_skip_button)

## 카드를 고르면 그 번호, 건너뛰기(닫기)를 누르면 -1을 반환한다
## skip_text가 빈 문자열이면 반드시 한 장을 골라야 한다. selectable이 false면 보기 전용
func pick(title: String, cards: Array, skip_text: String = "건너뛰기", hp_instead_of_mana: bool = false,
		footers: Array = [], disabled: Array = [], selectable: bool = true) -> int:
	_title.text = title
	for child in _flow.get_children():
		_flow.remove_child(child)
		child.queue_free()
	for i in range(cards.size()):
		var widget := CardWidget.new()
		var footer: String = footers[i] if i < footers.size() else ""
		widget.setup(cards[i], hp_instead_of_mana, footer)
		if selectable:
			widget.set_playable(not (i < disabled.size() and disabled[i]))
			widget.pressed.connect(_on_pressed.bind(i))
		else:
			widget.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_flow.add_child(widget)
	_skip_button.text = skip_text
	_skip_button.visible = skip_text != ""
	visible = true
	var picked: int = await _picked
	visible = false
	return picked

func _on_pressed(index: int) -> void:
	_picked.emit.call_deferred(index)
