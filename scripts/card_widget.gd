class_name CardWidget
extends Button

## 카드 한 장을 보여주는 버튼(손패·보상·상점·덱 보기에서 공통으로 사용)

const CARD_SIZE := Vector2(124, 176)
const TYPE_COLORS := {
	CardData.CardType.ATTACK: Color(0.55, 0.22, 0.2),
	CardData.CardType.DEFENSE: Color(0.18, 0.32, 0.55),
	CardData.CardType.SPECIAL: Color(0.4, 0.26, 0.55),
	CardData.CardType.CURSE: Color(0.22, 0.2, 0.22),
}
const EXCLUSIVE_BORDER := Color(1.0, 0.85, 0.35)

## footer: 카드 아래에 붙는 추가 문구(상점 가격 등)
func setup(card: Dictionary, hp_instead_of_mana: bool = false, footer: String = "") -> void:
	custom_minimum_size = CARD_SIZE
	var base: Color = TYPE_COLORS[card["type"]]
	var border := EXCLUSIVE_BORDER if card.get("exclusive", false) else base.lightened(0.35)
	add_theme_stylebox_override("normal", UiKit.box(base, 10, border))
	add_theme_stylebox_override("hover", UiKit.box(base.lightened(0.15), 10, Color.WHITE, 3))
	add_theme_stylebox_override("pressed", UiKit.box(base.darkened(0.1), 10, Color.WHITE, 3))
	add_theme_stylebox_override("disabled", UiKit.box(base.darkened(0.45), 10, border.darkened(0.5)))
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 2)
	UiKit.fill(box)
	box.offset_left = 8
	box.offset_right = -8
	box.offset_top = 6
	box.offset_bottom = -6
	add_child(box)

	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(top)
	var cost_label := UiKit.label(CardData.cost_text(card, hp_instead_of_mana), 12, Color(0.75, 0.9, 1.0))
	cost_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(cost_label)
	top.add_child(UiKit.label(CardData.tier_text(card), 11, Color(1, 1, 1, 0.6)))

	var name_label := UiKit.wrap_label(CardData.display_name(card), 17)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)

	var type_label := UiKit.label("%s · %s" % [CardData.type_name(card["type"]), card["tag"]], 11, Color(1, 1, 1, 0.6))
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(type_label)

	var desc_label := UiKit.wrap_label(CardData.description(card), 12, Color(1, 1, 0.9))
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(desc_label)

	if footer != "":
		var footer_label := UiKit.label(footer, 14, Color(1.0, 0.85, 0.3))
		footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(footer_label)

## 쓸 수 없는 카드는 비활성화하고 글자까지 어둡게 한다
func set_playable(playable: bool) -> void:
	disabled = not playable
	modulate = Color.WHITE if playable else Color(0.7, 0.7, 0.7)
