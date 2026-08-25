class_name SkillListPopup
extends Control

@onready var list_container: VBoxContainer = $Panel/ScrollContainer/ListContainer
@onready var empty_label: Label = $Panel/EmptyLabel
@onready var close_button: Button = $Panel/CloseButton
@onready var dim: ColorRect = $Dim

func _ready() -> void:
	visible = false
	close_button.pressed.connect(close)
	dim.gui_input.connect(_on_dim_input)

func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close()

## 보유한 스킬카드 목록을 채워서 팝업을 연다
func open(skill_cards: Array) -> void:
	for child in list_container.get_children():
		child.free()

	empty_label.visible = skill_cards.is_empty()
	for card in skill_cards:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		list_container.add_child(row)

		var icon := TextureRect.new()
		icon.texture = load(card["icon"])
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(40, 40)
		row.add_child(icon)

		var label := Label.new()
		var category_name := "공격" if card["category"] == GameContent.SkillCategory.ATTACK else "방어"
		label.text = "%s [%s] 마력 %d / 위력 +%d" % [card["name"], category_name, card["cost"], card["power"]]
		label.add_theme_font_size_override("font_size", 20)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(label)

	visible = true

func close() -> void:
	visible = false
