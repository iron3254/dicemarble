class_name ShopView
extends Control

## 상점: 카드 구매, 포션 구매, 카드 제거, 카드 강화(일반/특수)
## 골드를 쓰지 않고 그냥 떠나도 된다

signal _closed
signal changed

const OFFER_COUNT := 4
const REMOVE_PRICE := 60
const UPGRADE_PRICE := 50
const SPECIAL_UPGRADE_PRICE := 100
## 상점에서 특수강화 서비스가 나올 확률
const SPECIAL_UPGRADE_CHANCE := 0.35

var _stats: PlayerStats
var _picker: CardPickView
var _offers: Array = []
var _sold: Array = []
var _potion_bought := false
var _remove_used := false
var _upgrade_used := false
var _special_available := false
var _special_used := false

var _gold_label: Label
var _card_row: HBoxContainer
var _service_box: VBoxContainer

func _ready() -> void:
	UiKit.fill(self)
	visible = false
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.09, 0.08, 0.97)
	UiKit.fill(bg)
	add_child(bg)

	var box := VBoxContainer.new()
	UiKit.fill(box)
	box.offset_left = 40
	box.offset_right = -40
	box.offset_top = 24
	box.offset_bottom = -24
	box.add_theme_constant_override("separation", 14)
	add_child(box)

	var header := HBoxContainer.new()
	box.add_child(header)
	var title := UiKit.label("상점", 34, Color(1.0, 0.85, 0.4))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_gold_label = UiKit.label("", 26, Color(1.0, 0.85, 0.3))
	header.add_child(_gold_label)

	box.add_child(UiKit.label("카드 구매 (누르면 구매)", 18, Color(1, 1, 1, 0.7)))
	_card_row = HBoxContainer.new()
	_card_row.add_theme_constant_override("separation", 14)
	box.add_child(_card_row)

	box.add_child(UiKit.label("서비스", 18, Color(1, 1, 1, 0.7)))
	_service_box = VBoxContainer.new()
	_service_box.add_theme_constant_override("separation", 6)
	box.add_child(_service_box)

## 상점을 열고, 플레이어가 떠날 때까지 기다린다
func open(stats: PlayerStats, act: int, picker: CardPickView) -> void:
	_stats = stats
	_picker = picker
	_offers = CardData.draw_reward_cards(act, OFFER_COUNT, stats.favored_tags())
	_sold = []
	for i in range(_offers.size()):
		_sold.append(false)
	_potion_bought = false
	_remove_used = false
	_upgrade_used = false
	_special_used = false
	_special_available = randf() < SPECIAL_UPGRADE_CHANCE and not stats.special_upgradable_indices().is_empty()
	_rebuild()
	visible = true
	await _closed
	visible = false

func _rebuild() -> void:
	_gold_label.text = "골드 %d" % _stats.gold
	for child in _card_row.get_children():
		_card_row.remove_child(child)
		child.queue_free()
	for i in range(_offers.size()):
		var card: Dictionary = _offers[i]
		var price := CardData.price(card)
		var widget := CardWidget.new()
		widget.setup(card, _stats.hp_instead_of_mana(), "판매 완료" if _sold[i] else "%d 골드" % price)
		widget.set_playable(not _sold[i] and _stats.gold >= price)
		widget.pressed.connect(_buy_card.bind(i))
		_card_row.add_child(widget)

	for child in _service_box.get_children():
		_service_box.remove_child(child)
		child.queue_free()
	_add_service("체력 회복 포션 구매 (%d골드) — 보유 %d/%d" % [ItemData.POTION_PRICE, _stats.potions, PlayerStats.MAX_POTIONS],
		not _potion_bought and _stats.gold >= ItemData.POTION_PRICE and _stats.potions < PlayerStats.MAX_POTIONS, _buy_potion)
	_add_service("카드 제거 (%d골드)" % REMOVE_PRICE,
		not _remove_used and _stats.gold >= REMOVE_PRICE and not _stats.removable_indices().is_empty(), _remove_card)
	_add_service("카드 강화 (%d골드)" % UPGRADE_PRICE,
		not _upgrade_used and _stats.gold >= UPGRADE_PRICE and not _stats.upgradable_indices().is_empty(), _upgrade_card)
	if _special_available:
		_add_service("★ 전용 카드 특수 강화 (%d골드)" % SPECIAL_UPGRADE_PRICE,
			not _special_used and _stats.gold >= SPECIAL_UPGRADE_PRICE, _special_upgrade_card)
	_add_service("상점 떠나기", true, func(): _closed.emit.call_deferred(), Color(0.35, 0.35, 0.4))

func _add_service(text: String, enabled: bool, action: Callable, color: Color = Color(0.45, 0.35, 0.18)) -> void:
	var b := UiKit.button(text, 18)
	b.custom_minimum_size = Vector2(520, 40)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	UiKit.color_button(b, color)
	b.disabled = not enabled
	## 버튼을 누르는 도중 목록이 다시 그려지며 버튼이 지워지지 않도록 한 프레임 미룬다
	b.pressed.connect(func(): action.call_deferred())
	_service_box.add_child(b)

func _pay(amount: int) -> void:
	_stats.gold -= amount
	changed.emit()

func _buy_card(index: int) -> void:
	var price := CardData.price(_offers[index])
	if _sold[index] or _stats.gold < price:
		return
	_pay(price)
	_sold[index] = true
	_stats.deck.append(_offers[index])
	_rebuild.call_deferred()

func _buy_potion() -> void:
	_pay(ItemData.POTION_PRICE)
	_stats.potions += 1
	_potion_bought = true
	_rebuild()

func _remove_card() -> void:
	var indices := _stats.removable_indices()
	var index := await _pick_from_deck("제거할 카드를 고르세요", indices)
	if index < 0:
		return
	_pay(REMOVE_PRICE)
	_stats.deck.remove_at(index)
	_remove_used = true
	_rebuild()

func _upgrade_card() -> void:
	var index := await _pick_from_deck("강화할 카드를 고르세요 (고정값 +2 또는 비용 -1)", _stats.upgradable_indices())
	if index < 0:
		return
	_pay(UPGRADE_PRICE)
	CardData.upgrade(_stats.deck[index])
	_upgrade_used = true
	_rebuild()

func _special_upgrade_card() -> void:
	var index := await _pick_from_deck("특수 강화할 전용 카드를 고르세요 (고정값 +3, 비용 -1, 효과 +1)", _stats.special_upgradable_indices())
	if index < 0:
		return
	_pay(SPECIAL_UPGRADE_PRICE)
	CardData.special_upgrade(_stats.deck[index])
	_special_used = true
	_rebuild()

## 덱에서 indices에 해당하는 카드만 보여주고 고른 카드의 덱 인덱스를 반환한다(취소하면 -1)
func _pick_from_deck(title: String, indices: Array) -> int:
	var cards: Array = indices.map(func(i): return _stats.deck[i])
	var picked := await _picker.pick(title, cards, "취소", _stats.hp_instead_of_mana())
	if picked < 0:
		return -1
	return indices[picked]
