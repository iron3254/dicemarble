class_name GameManager
extends Node2D

## 게임 전체 흐름: 메인 메뉴 → 캐릭터 선택 → 1막 → 2막 → 3막 → 최종막(악신) → 엔딩
## 각 막은 갈림길 지도에서 칸(전투/상점/이벤트)을 골라 위로 올라가고, 끝에서 보스를 만난다
## HP가 0이 되면 게임 오버 — 처음부터 다시 시작한다

## 막별로 지나는 칸 수(기획서 '레벨 밸런스': 1막 7칸, 2막 14칸, 3막 21칸, 최종막 0칸)
const ACT_CELLS := {1: 7, 2: 14, 3: 21, 4: 0}
const FINAL_ACT := 4

## 막을 클리어할 때마다 늘어나는 최대 HP(기획서: 스테이지 클리어 시 고정값 증가)
@export var act_clear_max_hp_bonus: int = 10
@export var normal_gold_min: int = 15
@export var normal_gold_max: int = 25
@export var boss_gold: int = 70
## 악신을 물리쳤을 때 추가로 얻는 명성
@export var victory_fame_bonus: int = 300
## 배경음악 크기(dB) — 효과음에 묻히지 않도록 기본으로 살짝 낮춤
@export var bgm_volume_db: float = -10.0

@export_group("팝업 색상")
@export var gain_color: Color = Color(0.3, 1.0, 0.4)
@export var loss_color: Color = Color(1.0, 0.4, 0.4)
@export var gold_color: Color = Color(1.0, 0.85, 0.3)
@export var card_color: Color = Color(0.75, 0.85, 1.0)

@onready var battle_view: BattleView = $UI/BattleView

var meta := MetaSave.new()
var stats: PlayerStats
var act := 1
var map_data: MapData
var current_node := -1
var visited: Array = []
## 이번 막에서 지나간 칸 종류별 횟수(캐릭터 해금에 사용)
var route_counts := {}

var dialog: DialogView
var card_picker: CardPickView
var shop_view: ShopView
var menu_view: MenuView
var map_view: MapView

var _screen_layer: CanvasLayer
var _overlay_layer: CanvasLayer
var _map_screen: Control
var _map_scroll: ScrollContainer
var _act_label: Label
var _progress_label: Label
var _info_label: Label
var _deck_button: Button
var _potion_button: Button
var _event_dice_panel: Control
var _event_dice: Dice3DView
var _event_dice_label: Label

func _ready() -> void:
	meta.load_data()
	$UI.layer = 1
	_build_ui()
	_start_bgm()
	_main_loop()

func _start_bgm() -> void:
	var bgm_player := AudioStreamPlayer.new()
	var stream: AudioStreamMP3 = load("res://assets/audio/bgm_board.mp3")
	stream.loop = true
	bgm_player.stream = stream
	bgm_player.volume_db = bgm_volume_db
	add_child(bgm_player)
	bgm_player.play()

# ─────────────────────────── 화면 구성 ───────────────────────────

func _build_ui() -> void:
	## 화면 층: 0 = 메뉴/지도, 1 = 전투(main.tscn의 UI), 2 = 창(대화창, 카드 선택, 상점)
	_screen_layer = CanvasLayer.new()
	_screen_layer.layer = 0
	add_child(_screen_layer)
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.layer = 2
	add_child(_overlay_layer)

	_build_map_screen()
	menu_view = MenuView.new()
	_screen_layer.add_child(menu_view)

	shop_view = ShopView.new()
	_overlay_layer.add_child(shop_view)
	shop_view.changed.connect(update_side_panel)
	_build_event_dice()
	card_picker = CardPickView.new()
	_overlay_layer.add_child(card_picker)
	dialog = DialogView.new()
	_overlay_layer.add_child(dialog)

func _build_map_screen() -> void:
	_map_screen = Control.new()
	UiKit.fill(_map_screen)
	_screen_layer.add_child(_map_screen)
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.1, 0.12)
	UiKit.fill(bg)
	_map_screen.add_child(bg)

	## 왼쪽: 막 정보와 범례
	var left := VBoxContainer.new()
	left.position = Vector2(24, 24)
	left.size = Vector2(250, 600)
	left.add_theme_constant_override("separation", 8)
	_map_screen.add_child(left)
	_act_label = UiKit.label("", 34, Color(1.0, 0.85, 0.4))
	left.add_child(_act_label)
	_progress_label = UiKit.wrap_label("", 16, Color(1, 1, 1, 0.8))
	_progress_label.custom_minimum_size = Vector2(250, 0)
	left.add_child(_progress_label)
	left.add_child(UiKit.label("범례", 18, Color(1, 1, 1, 0.6)))
	var map_colors := MapView.new()
	for t in [MapData.NodeType.BATTLE, MapData.NodeType.EVENT, MapData.NodeType.SHOP, MapData.NodeType.BOSS]:
		var row := HBoxContainer.new()
		var swatch := ColorRect.new()
		swatch.color = map_colors.type_color(t)
		swatch.custom_minimum_size = Vector2(22, 22)
		row.add_child(swatch)
		row.add_child(UiKit.label(" " + MapData.type_name(t) + " — " + _type_hint(t), 14))
		left.add_child(row)
	map_colors.free()
	var rules := UiKit.wrap_label("\n· 아래에서 위로(↑) 진행\n· 깜빡이는 칸 중 하나를 고르세요\n· 이어진 길로만 갈 수 있고\n  지나간 칸은 되돌아갈 수 없어요\n· HP가 0이 되면 처음부터!", 14, Color(1, 1, 1, 0.65))
	rules.custom_minimum_size = Vector2(250, 0)
	left.add_child(rules)

	## 가운데: 스크롤되는 지도
	_map_scroll = ScrollContainer.new()
	_map_scroll.position = Vector2(300, 10)
	_map_scroll.size = Vector2(500, 628)
	_map_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_map_screen.add_child(_map_scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_scroll.add_child(center)
	map_view = MapView.new()
	center.add_child(map_view)

	## 오른쪽: 플레이어 정보와 버튼
	var right := VBoxContainer.new()
	right.position = Vector2(830, 24)
	right.size = Vector2(300, 600)
	right.add_theme_constant_override("separation", 10)
	_map_screen.add_child(right)
	_info_label = UiKit.wrap_label("", 18)
	_info_label.custom_minimum_size = Vector2(300, 0)
	right.add_child(_info_label)
	_deck_button = UiKit.button("덱 보기", 18)
	UiKit.color_button(_deck_button, Color(0.25, 0.32, 0.5))
	_deck_button.custom_minimum_size = Vector2(0, 42)
	_deck_button.pressed.connect(_show_deck)
	right.add_child(_deck_button)
	_potion_button = UiKit.button("포션 사용", 18)
	UiKit.color_button(_potion_button, Color(0.25, 0.5, 0.3))
	_potion_button.custom_minimum_size = Vector2(0, 42)
	_potion_button.pressed.connect(_use_potion_on_map)
	right.add_child(_potion_button)
	var item_button := UiKit.button("아이템 보기", 18)
	UiKit.color_button(item_button, Color(0.45, 0.35, 0.18))
	item_button.custom_minimum_size = Vector2(0, 42)
	item_button.pressed.connect(_show_items)
	right.add_child(item_button)

## 이벤트 판정용 3D 주사위 창
func _build_event_dice() -> void:
	_event_dice_panel = Control.new()
	UiKit.fill(_event_dice_panel)
	_event_dice_panel.visible = false
	_overlay_layer.add_child(_event_dice_panel)
	_event_dice_panel.add_child(UiKit.dim(0.6))
	_event_dice = Dice3DView.new()
	_event_dice.position = Vector2(426, 150)
	_event_dice.size = Vector2(300, 300)
	_event_dice_panel.add_child(_event_dice)
	_event_dice_label = UiKit.label("", 40, Color(1.0, 0.85, 0.4))
	_event_dice_label.position = Vector2(426, 460)
	_event_dice_label.size = Vector2(300, 60)
	_event_dice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_event_dice_panel.add_child(_event_dice_label)

static func _type_hint(t: MapData.NodeType) -> String:
	match t:
		MapData.NodeType.BATTLE: return "적과 싸운다"
		MapData.NodeType.EVENT: return "무슨 일이 생길까?"
		MapData.NodeType.SHOP: return "카드·포션·강화"
		MapData.NodeType.BOSS: return "막의 마지막 적"
	return ""

# ─────────────────────────── 전체 흐름 ───────────────────────────

func _main_loop() -> void:
	while true:
		_map_screen.visible = false
		menu_view.open(meta)
		var character: Dictionary = await menu_view.character_chosen
		menu_view.visible = false
		await _play_run(character)

## 모험 한 판(1막 ~ 최종막)
func _play_run(character: Dictionary) -> void:
	stats = PlayerStats.new()
	stats.setup(character)
	act = 1
	_map_screen.visible = true
	_start_act()
	await dialog.ask("Dice Marble",
		"최초의 국가가 세워진 지 4242년.\n크고 작은 전쟁이 끊이지 않는 대륙에 인류를 멸망시키려는 악신이 깨어났다.\n\n미지를 쫓는 탐험가 %s는 세 개의 땅을 지나 악신에게 맞서기로 한다." % character["name"],
		["모험 시작"])
	while act <= FINAL_ACT:
		var alive := await _play_act()
		if not alive:
			await _game_over()
			return
		act += 1
		if act <= FINAL_ACT:
			_start_act()
	await _victory()

func _start_act() -> void:
	map_data = MapData.new(ACT_CELLS[act])
	current_node = -1
	visited = []
	route_counts = {"battle": 0, "event": 0, "shop": 0}
	_refresh_map([])

## 한 막을 진행한다. 보스를 잡으면 true, 쓰러지면 false
func _play_act() -> bool:
	var act_title := "최종막" if act == FINAL_ACT else "%d막" % act
	var act_desc := "악신이 기다리는 하늘섬에 도착했다.\n이번 싸움에서 이기면 세상에 평화가 찾아온다." if act == FINAL_ACT \
		else "이번 막에서는 %d칸을 지나 보스를 만난다.\n길을 잘 골라 덱을 강하게 만들자." % ACT_CELLS[act]
	await dialog.ask(act_title, act_desc, ["출발"])
	while true:
		var choices: Array = map_data.start_choices() if current_node < 0 else map_data.nodes[current_node]["next"]
		_refresh_map(choices)
		var index: int = await map_view.node_chosen
		current_node = index
		visited.append(index)
		_refresh_map([])
		var node: Dictionary = map_data.nodes[index]
		var alive: bool = await _resolve_node(node)
		if not alive:
			return false
		if node["type"] == MapData.NodeType.BOSS:
			await _act_clear()
			return true
	return false # 이 지점에는 도달하지 않음. 정적 분석기용.

## 칸 종류에 맞는 일을 진행하고, 끝난 뒤 살아있으면 true
func _resolve_node(node: Dictionary) -> bool:
	match node["type"]:
		MapData.NodeType.BATTLE:
			route_counts["battle"] += 1
			var won: bool = await _fight(EnemyData.create_normal(act))
			if not won:
				return false
		MapData.NodeType.BOSS:
			var won_boss: bool = await _fight(EnemyData.create_boss(act))
			if not won_boss:
				return false
		MapData.NodeType.SHOP:
			route_counts["shop"] += 1
			await shop_view.open(stats, act, card_picker)
		MapData.NodeType.EVENT:
			route_counts["event"] += 1
			await EventRunner.run(self)
	update_side_panel()
	return _check_alive()

## 이벤트 등으로 HP가 0이 됐을 때 목걸이가 있으면 부활
func _check_alive() -> bool:
	if stats.hp > 0:
		return true
	if stats.try_revive():
		popup("목걸이가 부서지며 부활!", gain_color)
		update_side_panel()
		return true
	return false

func _fight(enemy: EnemyData) -> bool:
	var won: bool = await battle_view.start_battle(stats, enemy, act)
	update_side_panel()
	if not won:
		return false
	if not enemy.is_boss:
		var gold := randi_range(normal_gold_min, normal_gold_max) + (act - 1) * 5
		stats.gain_gold(gold)
		popup("골드 +%d" % gold, gold_color)
		update_side_panel()
		await offer_card_reward("전투 승리! 카드 1장을 고르세요")
	return true

func _act_clear() -> void:
	stats.max_hp += act_clear_max_hp_bonus
	stats.hp = stats.max_hp
	if act == FINAL_ACT:
		return
	var gold := boss_gold * act
	stats.gain_gold(gold)
	update_side_panel()
	await dialog.ask("%d막 클리어!" % act,
		"보스를 쓰러뜨렸다!\n\n· 최대 HP +%d, HP 전부 회복\n· 골드 +%d" % [act_clear_max_hp_bonus, gold],
		["보상 받기"])
	await choose_buff("보스 보상: 버프 1개를 고르세요")
	await offer_card_reward("보스 보상: 카드 1장을 고르세요")
	var unlocked := meta.unlock_by_route(route_counts)
	if not unlocked.is_empty():
		await dialog.ask("새 캐릭터 해금!",
			"이번 막에서 고른 길 덕분에 '%s'을(를) 메인 메뉴에서 구매할 수 있게 되었다! (명성 %d)" % [unlocked["name"], unlocked["price"]],
			["확인"])

func _game_over() -> void:
	meta.fame += stats.gold_earned
	meta.save_data()
	await dialog.ask("게임 오버",
		"%d막에서 쓰러졌다...\nHP가 0이 되어 처음부터 다시 시작해야 한다.\n\n이번 모험으로 명성 +%d (보유 %d)" % [act, stats.gold_earned, meta.fame],
		["메인 메뉴로"])

func _victory() -> void:
	var fame := stats.gold_earned + victory_fame_bonus
	meta.fame += fame
	meta.save_data()
	await dialog.ask("엔딩",
		"악신이 쓰러졌다!\n\n모험을 하며 성장한 %s는 인류를 멸망시키려던 악신을 물리치고 세상에 평화를 가져왔다.\n그리고 다시, 미지를 향한 모험을 계속한다.\n\n명성 +%d (보유 %d)" % [stats.character["name"], fame, meta.fame],
		["메인 메뉴로"])

# ─────────────────────────── 보상/덱 도우미 (이벤트에서도 사용) ───────────────────────────

## 카드 3장 중 1장을 고르게 한다(건너뛰기 가능)
func offer_card_reward(title: String) -> void:
	var cards := CardData.draw_reward_cards(act, 3, stats.favored_tags())
	var picked := await card_picker.pick(title, cards, "건너뛰기", stats.hp_instead_of_mana())
	if picked >= 0:
		stats.deck.append(cards[picked])
		popup("%s 획득!" % CardData.display_name(cards[picked]), card_color)
	update_side_panel()

## 랜덤 버프 3개 중 1개를 고르게 한다
func choose_buff(title: String) -> void:
	var buffs := BuffData.pick_three(stats)
	var options: Array = buffs.map(func(b): return "%s — %s" % [b["name"], b["desc"]])
	var picked := await dialog.ask(title, "", options)
	popup(BuffData.apply(buffs[picked], stats), gain_color)
	update_side_panel()

func remove_card_from_deck(title: String) -> void:
	var indices := stats.removable_indices()
	var cards: Array = indices.map(func(i): return stats.deck[i])
	var picked := await card_picker.pick(title, cards, "취소", stats.hp_instead_of_mana())
	if picked >= 0:
		popup("%s 제거" % CardData.display_name(stats.deck[indices[picked]]), card_color)
		stats.deck.remove_at(indices[picked])
	update_side_panel()

func upgrade_card_in_deck(title: String, special: bool) -> void:
	var indices := stats.special_upgradable_indices() if special else stats.upgradable_indices()
	var cards: Array = indices.map(func(i): return stats.deck[i])
	var picked := await card_picker.pick(title, cards, "취소", stats.hp_instead_of_mana())
	if picked < 0:
		return
	var card: Dictionary = stats.deck[indices[picked]]
	if special:
		CardData.special_upgrade(card)
	else:
		CardData.upgrade(card)
	popup("%s 강화!" % CardData.display_name(card), card_color)
	update_side_panel()

## 이벤트 판정용으로 3D 주사위(D6)를 굴려서 결과를 반환한다
func roll_event_dice() -> int:
	_event_dice_label.text = ""
	_event_dice_panel.visible = true
	var value: int = await _event_dice.roll()
	_event_dice_label.text = "%d!" % value
	await get_tree().create_timer(0.9).timeout
	_event_dice_panel.visible = false
	return value

# ─────────────────────────── 지도 화면 ───────────────────────────

func _refresh_map(available: Array) -> void:
	map_view.show_map(map_data, available, visited)
	update_side_panel()
	_scroll_to_current.call_deferred(available)

## 지금 고를 수 있는 칸이 화면 가운데 오도록 지도를 스크롤한다
func _scroll_to_current(available: Array) -> void:
	await get_tree().process_frame
	var target_y := map_view.custom_minimum_size.y
	if not available.is_empty():
		target_y = map_view.node_center(available[0]).y
	elif current_node >= 0:
		target_y = map_view.node_center(current_node).y
	_map_scroll.scroll_vertical = int(target_y - _map_scroll.size.y * 0.5)

func update_side_panel() -> void:
	if stats == null or map_data == null:
		return
	_act_label.text = "최종막" if act == FINAL_ACT else "%d막" % act
	var passed := 0
	if current_node >= 0:
		passed = min(map_data.rows, map_data.nodes[current_node]["row"] + 1)
	_progress_label.text = "지나온 칸 %d / %d\n끝에서 보스가 기다린다" % [passed, map_data.rows] if map_data.rows > 0 \
		else "악신과의 최종 결전"

	var items_text := ", ".join(stats.items.map(func(id): return ItemData.item_name(id)))
	var mana_line := "카드에 마나 대신 HP 소모" if stats.hp_instead_of_mana() \
		else "마나 %d (매 턴 +%d)" % [stats.mana_stat, BattleView.MANA_REGEN + stats.mana_regen_bonus]
	_info_label.text = "[%s]\n\nHP %d / %d\n골드 %d\n\n힘 %d · 방어 %d\n%s\n\n덱 %d장\n포션 %d / %d\n아이템: %s" % [
		stats.character["name"], stats.hp, stats.max_hp, stats.gold,
		stats.strength, stats.defense, mana_line,
		stats.deck.size(), stats.potions, PlayerStats.MAX_POTIONS, items_text if items_text != "" else "없음",
	]
	_deck_button.text = "덱 보기 (%d장)" % stats.deck.size()
	_potion_button.text = "포션 사용 (+%d HP)" % stats.potion_heal_amount()
	_potion_button.disabled = stats.potions <= 0 or stats.hp >= stats.max_hp

func _show_deck() -> void:
	await card_picker.pick("내 덱 (%d장)" % stats.deck.size(), stats.deck, "닫기", stats.hp_instead_of_mana(), [], [], false)

func _use_potion_on_map() -> void:
	var healed := stats.use_potion()
	popup("HP +%d" % healed, gain_color)
	update_side_panel()

func _show_items() -> void:
	var lines: Array[String] = []
	for id in stats.items:
		var item: Dictionary = ItemData.ITEMS[id]
		lines.append("■ %s (%s)\n   %s" % [item["name"], item["kind"], item["desc"]])
	lines.append("■ 체력 회복 포션 × %d\n   최대 HP의 %d%% 회복" % [stats.potions, int(round((ItemData.POTION_HEAL_RATIO + stats.character.get("potion_bonus", 0.0)) * 100))])
	await dialog.ask("아이템", "\n\n".join(lines), ["닫기"])

## 화면 오른쪽에 글자를 띄웠다가 위로 떠오르며 사라지게 한다
func popup(text: String, color: Color) -> void:
	var label := UiKit.label(text, 30, color)
	label.position = Vector2(830, 300 + randf_range(-20, 20))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay_layer.add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 60, 1.3)
	tween.tween_property(label, "modulate:a", 0.0, 1.3)
	tween.chain().tween_callback(label.queue_free)
