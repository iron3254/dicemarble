class_name MenuView
extends Control

## 메인 메뉴: 캐릭터 선택과 캐릭터 구매(명성 사용)

signal character_chosen(character: Dictionary)

var _meta: MetaSave
var _fame_label: Label
var _card_row: HBoxContainer

func _ready() -> void:
	UiKit.fill(self)
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.11)
	UiKit.fill(bg)
	add_child(bg)

	var box := VBoxContainer.new()
	UiKit.fill(box)
	box.offset_top = 26
	box.offset_bottom = -20
	box.add_theme_constant_override("separation", 10)
	add_child(box)

	var title := UiKit.label("Dice Marble", 60, Color(1.0, 0.85, 0.35))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var subtitle := UiKit.label("확률과 전략이 공존하는 TRPG식 로그라이크 덱빌딩", 20, Color(1, 1, 1, 0.75))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)
	_fame_label = UiKit.label("", 20, Color(0.7, 0.9, 1.0))
	_fame_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_fame_label)

	var hint := UiKit.label("캐릭터를 골라 모험을 시작하세요", 18, Color(1, 1, 1, 0.6))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)

	_card_row = HBoxContainer.new()
	_card_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_card_row.add_theme_constant_override("separation", 16)
	_card_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_card_row)

func open(meta: MetaSave) -> void:
	_meta = meta
	visible = true
	_rebuild()

func _rebuild() -> void:
	_fame_label.text = "보유 명성: %d  (모험에서 번 골드만큼 쌓여요)" % _meta.fame
	for child in _card_row.get_children():
		_card_row.remove_child(child)
		child.queue_free()
	for c in CharacterData.CHARACTERS:
		_card_row.add_child(_make_character_panel(c))

func _make_character_panel(c: Dictionary) -> Control:
	var owned := _meta.is_owned(c["id"])
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(250, 400)
	var style := UiKit.box(Color(0.14, 0.14, 0.18), 12, c["color"] if owned else Color(0.35, 0.35, 0.4), 3)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	var icon := TextureRect.new()
	icon.texture = load("res://assets/icons/player_character.svg")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(0, 80)
	icon.modulate = c["color"] if owned else Color(0.3, 0.3, 0.3)
	box.add_child(icon)

	var name_label := UiKit.label(c["name"], 26, c["color"])
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)
	box.add_child(UiKit.wrap_label(c["desc"], 14, Color(1, 1, 1, 0.85)))
	box.add_child(UiKit.label(CharacterData.stat_text(c), 14, Color(0.7, 1.0, 0.75)))

	var item_text := "아이템: 없음"
	if c["item"] != "":
		item_text = "아이템: %s" % ItemData.item_name(c["item"])
	box.add_child(UiKit.wrap_label(item_text, 14, Color(1.0, 0.85, 0.5)))
	var card_names: Array = c["cards"].map(func(id): return CardData.CARDS[id]["name"])
	box.add_child(UiKit.wrap_label("전용 카드: %s" % ", ".join(card_names), 14, Color(1.0, 0.85, 0.5)))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)

	var b := UiKit.button("", 18)
	b.custom_minimum_size = Vector2(0, 46)
	if owned:
		b.text = "이 캐릭터로 시작"
		UiKit.color_button(b, c["color"].darkened(0.35))
		b.pressed.connect(func(): character_chosen.emit.call_deferred(c))
	elif _meta.purchasable.has(c["id"]):
		b.text = "구매 (명성 %d)" % c["price"]
		UiKit.color_button(b, Color(0.5, 0.4, 0.15))
		b.disabled = not _meta.can_buy(c)
		b.pressed.connect(func():
			_meta.buy(c)
			_rebuild.call_deferred())
	else:
		b.text = "잠김 — %s" % _unlock_hint(c["unlock_route"])
		b.add_theme_font_size_override("font_size", 13)
		UiKit.color_button(b, Color(0.25, 0.25, 0.28))
		b.disabled = true
	box.add_child(b)
	return panel

static func _unlock_hint(route: String) -> String:
	match route:
		"battle": return "전투 위주로 막을 깨면 해금"
		"event": return "이벤트 위주로 막을 깨면 해금"
		"shop": return "상점 위주로 막을 깨면 해금"
	return ""
