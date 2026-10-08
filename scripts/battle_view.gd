class_name BattleView
extends Control

## 카드 전투 화면. 공격 턴 → 방어 턴이 한 바퀴(=1턴)이고, 적이나 플레이어의 HP가 0이 될 때까지 반복한다
## - 공격 턴: 공격·특수 카드만 사용 가능. 피해 = 주사위 + 카드 값 + 힘
## - 방어 턴: 적이 공격을 예고하면 방어·특수 카드로 보호막을 쌓는다. 보호막 = 주사위 + 카드 값 + 방어
## - 보호막은 그 턴에만 유지된다

## 플레이어 입력(카드 클릭, 턴 종료, 포션 등)을 전투 진행 코루틴에 전달하는 신호
signal _player_input(kind: String, index: int)

@onready var title_label: Label = $Background/TitleLabel
@onready var player_label: Label = $Background/PlayerLabel
@onready var enemy_avatar: ColorRect = $Background/EnemyAvatar
@onready var enemy_icon: TextureRect = $Background/EnemyAvatar/CharacterIcon
@onready var enemy_name_label: Label = $Background/EnemyNameLabel
@onready var enemy_hp_bar: ProgressBar = $Background/EnemyHpBar
@onready var enemy_hp_label: Label = $Background/EnemyHpLabel
@onready var player_avatar: ColorRect = $Background/PlayerAvatar
@onready var player_icon: TextureRect = $Background/PlayerAvatar/CharacterIcon
@onready var player_hp_bar: ProgressBar = $Background/PlayerHpBar
@onready var player_mana_bar: ProgressBar = $Background/PlayerManaBar
@onready var player_status_label: Label = $Background/PlayerStatusLabel
@onready var dice_3d_view: Dice3DView = $Background/BattleDiceView
@onready var dice_roll_label: Label = $Background/DiceResultRow/DiceRollLabel
@onready var dice_skill_label: Label = $Background/DiceResultRow/DiceSkillLabel
@onready var dice_stat_label: Label = $Background/DiceResultRow/DiceStatLabel
@onready var turn_label: Label = $Background/TurnLabel
@onready var background: ColorRect = $Background

## 턴이 바뀌었을 때 잠깐 멈춰서 구분되게 보여줄 시간(초)
const TURN_PAUSE := 0.6
## 승패가 갈린 뒤 결과 팝업을 보여주고 화면을 닫기까지 대기 시간(초)
const RESULT_PAUSE := 1.0
## 매 턴(공격 턴 + 방어 턴 한 바퀴) 회복하는 기본 마나
const MANA_REGEN := 2

@export_group("결과 팝업 색상")
@export var neutral_color: Color = Color(1, 1, 1)
@export var damage_color: Color = Color(1.0, 0.4, 0.3)
@export var victory_color: Color = Color(1.0, 0.85, 0.3)
@export var heal_color: Color = Color(0.3, 1.0, 0.4)
@export var faint_color: Color = Color(1.0, 0.5, 0.5)
@export var enemy_attack_color: Color = Color(1.0, 0.6, 0.3)
@export var defend_color: Color = Color(0.4, 0.8, 1.0)
@export var thunder_color: Color = Color(1.0, 0.95, 0.4)
@export var poison_color: Color = Color(0.55, 1.0, 0.4)

@export_group("결과 팝업 크기/움직임")
@export var popup_main_font_size: int = 40
@export var popup_detail_font_size: int = 16
@export var popup_float_distance: float = 60.0
@export var popup_duration: float = 1.0

@export_group("타격 연출")
@export var flash_color: Color = Color(1.0, 0.4, 0.4)
@export var flash_duration: float = 0.3
@export var lunge_distance: float = 55.0

@export_group("턴 구분")
@export var player_turn_color: Color = Color(0.4, 0.6, 1.0)
@export var enemy_turn_color: Color = Color(1.0, 0.45, 0.4)
@export var inactive_dim_color: Color = Color(0.45, 0.45, 0.48)

var _stats: PlayerStats
var _enemy: EnemyData
## 공격/방어 별로 따로 관리하는 덱(뽑을 카드 더미)·버린 카드 더미·손패. 키: CardData.SIDE_ATTACK / SIDE_DEFENSE
var _draw_piles := {}
var _discard_piles := {}
var _hands := {}
var _mana := 0
var _shield := 0
var _temp_strength := 0
var _enemy_intent := 0
## 지금이 공격 턴인지 방어 턴인지(CardType.ATTACK / CardType.DEFENSE)
var _phase: CardData.CardType = CardData.CardType.ATTACK
var _discard_mode := false
var _input_enabled := false

var _attack_sound: AudioStreamPlayer
var _defense_sound: AudioStreamPlayer
var _roll_sound: AudioStreamPlayer

## 아래 UI는 코드로 만든다(_build_extra_ui)
## 공격 패/방어 패 카드가 들어가는 줄. 키: CardData.SIDE_ATTACK / SIDE_DEFENSE
var _hand_boxes := {}
var _end_turn_button: Button
var _discard_button: Button
var _potion_button: Button
var _pile_label: Label
var _hint_label: Label
var _intent_label: Label
var _enemy_status_label: Label
var _shield_label: Label
var _dice2d_panel: ColorRect
var _dice2d_label: Label
var _dice2d_kind: Label

func _ready() -> void:
	visible = false
	_attack_sound = _make_sound("res://assets/audio/attack.wav")
	_defense_sound = _make_sound("res://assets/audio/defense.wav")
	_roll_sound = _make_sound("res://assets/audio/dice_roll.wav")
	if has_node("Background/ActionContainer"):
		$Background/ActionContainer.visible = false
	_build_extra_ui()

func _make_sound(path: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = load(path)
	add_child(player)
	return player

func _build_extra_ui() -> void:
	_shield_label = _add_label(Vector2(140, 100), Vector2(180, 28), 18, defend_color, HORIZONTAL_ALIGNMENT_RIGHT)
	_intent_label = _add_label(Vector2(832, 384), Vector2(240, 28), 22, enemy_attack_color, HORIZONTAL_ALIGNMENT_RIGHT)
	_enemy_status_label = _add_label(Vector2(832, 412), Vector2(240, 26), 18, thunder_color, HORIZONTAL_ALIGNMENT_RIGHT)
	_hint_label = _add_label(Vector2(340, 336), Vector2(472, 50), 16, Color(1, 1, 1, 0.85), HORIZONTAL_ALIGNMENT_CENTER)
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pile_label = _add_label(Vector2(340, 392), Vector2(472, 24), 15, Color(1, 1, 1, 0.6), HORIZONTAL_ALIGNMENT_CENTER)

	## 왼쪽 = 공격 패, 오른쪽 = 방어 패
	var hands_row := HBoxContainer.new()
	hands_row.position = Vector2(16, 420)
	hands_row.size = Vector2(930, 210)
	hands_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hands_row.add_theme_constant_override("separation", 40)
	background.add_child(hands_row)
	_hand_boxes[CardData.SIDE_ATTACK] = _add_hand_group(hands_row, "공격 패", damage_color)
	_hand_boxes[CardData.SIDE_DEFENSE] = _add_hand_group(hands_row, "방어 패", defend_color)

	_end_turn_button = _add_button("턴 종료", Vector2(960, 452), Vector2(172, 62), Color(0.65, 0.45, 0.15), 22)
	_end_turn_button.pressed.connect(func(): _send_input("end", -1))
	_discard_button = _add_button("카드 버리기", Vector2(960, 522), Vector2(172, 44), Color(0.35, 0.35, 0.4), 16)
	_discard_button.pressed.connect(func(): _send_input("discard_toggle", -1))
	_potion_button = _add_button("포션", Vector2(960, 574), Vector2(172, 44), Color(0.25, 0.5, 0.3), 16)
	_potion_button.pressed.connect(func(): _send_input("potion", -1))

	## D6가 아닌 주사위(D4/D12/D20/특수 주사위)를 굴릴 때 3D 주사위 자리에 보여줄 숫자 굴림판
	_dice2d_panel = ColorRect.new()
	_dice2d_panel.color = Color(0.13, 0.13, 0.16)
	_dice2d_panel.position = dice_3d_view.position
	_dice2d_panel.size = dice_3d_view.size
	_dice2d_panel.visible = false
	background.add_child(_dice2d_panel)
	_dice2d_kind = UiKit.label("", 18, Color(1, 1, 1, 0.6))
	_dice2d_kind.position = Vector2(0, 6)
	_dice2d_kind.size = Vector2(dice_3d_view.size.x, 24)
	_dice2d_kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dice2d_panel.add_child(_dice2d_kind)
	_dice2d_label = UiKit.label("", 64)
	_dice2d_label.position = Vector2(0, 30)
	_dice2d_label.size = Vector2(dice_3d_view.size.x, dice_3d_view.size.y - 30)
	_dice2d_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dice2d_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_dice2d_panel.add_child(_dice2d_label)

## "공격 패"/"방어 패" 제목과 카드 줄을 하나의 묶음으로 만들고, 카드 줄을 반환한다
func _add_hand_group(parent: Control, title: String, color: Color) -> HBoxContainer:
	var group := VBoxContainer.new()
	group.add_theme_constant_override("separation", 2)
	parent.add_child(group)
	group.add_child(UiKit.label(title, 16, color))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	## 카드가 0장이어도 자리 크기가 유지되도록 최소 크기를 잡아둔다
	row.custom_minimum_size = Vector2((CardWidget.CARD_SIZE.x + 6) * CardData.HAND_SIZE, CardWidget.CARD_SIZE.y)
	group.add_child(row)
	return row

func _add_label(pos: Vector2, label_size: Vector2, font_size: int, color: Color,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := UiKit.label("", font_size, color)
	l.position = pos
	l.size = label_size
	l.horizontal_alignment = align
	background.add_child(l)
	return l

func _add_button(text: String, pos: Vector2, button_size: Vector2, color: Color, font_size: int) -> Button:
	var b := UiKit.button(text, font_size)
	b.position = pos
	b.size = button_size
	UiKit.color_button(b, color)
	background.add_child(b)
	return b

## 버튼 처리 중에 손패 버튼이 지워지지 않도록 입력 신호는 한 프레임 미뤄서 보낸다
func _send_input(kind: String, index: int) -> void:
	if _input_enabled:
		_player_input.emit.call_deferred(kind, index)

# ─────────────────────────── 전투 진행 ───────────────────────────

## 전투를 진행하고 승리하면 true, 패배하면 false를 반환한다
func start_battle(stats: PlayerStats, enemy: EnemyData, act: int) -> bool:
	_stats = stats
	_enemy = enemy
	visible = true
	if act >= 4:
		title_label.text = "최종 결전"
	elif enemy.is_boss:
		title_label.text = "%d막 보스전" % act
	else:
		title_label.text = "%d막 전투" % act
	player_label.text = stats.character["name"]
	player_avatar.color = stats.character["color"].darkened(0.3)
	enemy_avatar.color = Color(0.55, 0.2, 0.25) if enemy.is_boss else Color(0.45, 0.28, 0.25)
	player_avatar.modulate = Color.WHITE
	enemy_avatar.modulate = Color.WHITE
	enemy_icon.texture = load(enemy.icon)
	enemy_icon.modulate = enemy.tint
	dice_roll_label.text = ""
	dice_skill_label.text = ""
	dice_stat_label.text = ""
	_dice2d_panel.visible = false

	## 덱을 공격 덱과 방어 덱으로 나눈다
	for side in [CardData.SIDE_ATTACK, CardData.SIDE_DEFENSE]:
		_draw_piles[side] = stats.deck.filter(func(c): return CardData.hand_side(c) == side)
		_draw_piles[side].shuffle()
		_discard_piles[side] = []
		_hands[side] = []
	_mana = stats.mana_stat
	_shield = 0
	_temp_strength = 0
	_enemy_intent = 0
	_discard_mode = false
	_refill_hands()
	_set_input(false)
	_pop_result(enemy_avatar, "등장!", "%s (공격 %s)" % [enemy.enemy_name, enemy.attack_text()], neutral_color)

	while true:
		## 공격 턴
		_phase = CardData.CardType.ATTACK
		await _show_turn("공격 턴", player_avatar, enemy_avatar, player_turn_color)
		_hint_label.text = "공격 패의 카드를 사용하세요.\n다 썼으면 [턴 종료]"
		await _player_phase()
		if _enemy.hp <= 0:
			return await _finish(true)
		if _stats.hp <= 0 and not _try_revive():
			return await _finish(false)
		_refill_hands()

		## 방어 턴
		_phase = CardData.CardType.DEFENSE
		await _show_turn("방어 턴", enemy_avatar, player_avatar, enemy_turn_color)
		await _roll_enemy_intent()
		_hint_label.text = "적이 %d 피해로 공격하려 한다!\n방어 패의 카드로 보호막을 쌓고 [턴 종료]" % _enemy_intent
		await _player_phase()
		if _enemy.hp <= 0:
			return await _finish(true)
		await _enemy_attack()
		if _stats.hp <= 0 and not _try_revive():
			return await _finish(false)

		await _end_of_round()
		if _enemy.hp <= 0:
			return await _finish(true)
		if _stats.hp <= 0 and not _try_revive():
			return await _finish(false)
	return false # 이 지점에는 도달하지 않음(while true 내부에서 항상 반환됨). 정적 분석기용.

## 플레이어가 [턴 종료]를 누를 때까지 카드 사용/버리기/포션 입력을 처리한다
func _player_phase() -> void:
	_discard_mode = false
	_set_input(true)
	while true:
		var args: Array = await _player_input
		var kind: String = args[0]
		if kind == "end":
			break
		_set_input(false)
		match kind:
			CardData.SIDE_ATTACK, CardData.SIDE_DEFENSE:
				var index: int = args[1]
				if _discard_mode:
					_discard_from_hand(kind, index)
				else:
					await _play_card(kind, index)
			"discard_toggle":
				_discard_mode = not _discard_mode
			"potion":
				var healed := _stats.use_potion()
				_pop_result(player_avatar, "+%d" % healed, "포션 사용", heal_color)
		_update_status()
		if _enemy.hp <= 0:
			return
		_set_input(true)
	_discard_mode = false
	_set_input(false)

func _finish(won: bool) -> bool:
	_set_input(false)
	_hint_label.text = ""
	_intent_label.text = ""
	if won:
		_pop_result(enemy_avatar, "승리!", "%s 처치" % _enemy.enemy_name, victory_color)
	else:
		_pop_result(player_avatar, "쓰러졌다...", "HP 0", faint_color)
	await get_tree().create_timer(RESULT_PAUSE).timeout
	visible = false
	return won

func _try_revive() -> bool:
	if not _stats.try_revive():
		return false
	_update_status()
	_pop_result(player_avatar, "부활!", "목걸이가 부서지며 HP %d로 일어났다" % _stats.hp, heal_color)
	return true

## 적이 이번 방어 턴에 줄 피해를 미리 굴려서 보여준다(예고)
func _roll_enemy_intent() -> void:
	var total := 0
	var parts: Array[String] = []
	var last_face: Variant = 0
	for i in range(_enemy.hits):
		last_face = await _roll(_enemy.dice)
		var value := Dice.face_value(last_face) + _enemy.attack
		total += value
		parts.append("주사위%s+%d" % [str(last_face), _enemy.attack])
	_enemy_intent = total
	_show_dice_result(last_face, 0, _enemy.attack)
	_intent_label.text = "공격 예고: %d" % total
	_pop_result(enemy_avatar, "공격 예고 %d" % total, " / ".join(parts), enemy_attack_color)

## 예고한 피해에서 보호막만큼 빼고 플레이어에게 피해를 준다. 보호막은 여기서 사라진다
func _enemy_attack() -> void:
	var final_damage: int = max(0, _enemy_intent - _shield)
	_lunge(enemy_avatar, Vector2(-lunge_distance, 0))
	if _shield > 0:
		_defense_sound.play()
	else:
		_attack_sound.play()
	_stats.take_damage(final_damage)
	if final_damage > 0:
		_flash(player_avatar)
		_pop_result(player_avatar, "-%d" % final_damage, "공격 %d - 보호막 %d" % [_enemy_intent, _shield], damage_color)
	else:
		_pop_result(player_avatar, "완전 방어!", "공격 %d - 보호막 %d" % [_enemy_intent, _shield], defend_color)
	_shield = 0
	_enemy_intent = 0
	_intent_label.text = ""
	_update_status()
	await get_tree().create_timer(0.6).timeout

## 한 턴(공격+방어)이 끝날 때: 저주 피해 → 독 피해 → 뇌문 감소 → 손패 보충 → 마나 회복
func _end_of_round() -> void:
	var curse_loss := 0
	for side in _hands:
		for card in _hands[side]:
			curse_loss += card.get("hp_loss_in_hand", 0)
	if curse_loss > 0:
		_stats.take_damage(curse_loss)
		_pop_result(player_avatar, "-%d" % curse_loss, "저주 카드 '불운'", faint_color)

	if _enemy.poison > 0:
		_enemy.hp = max(0, _enemy.hp - _enemy.poison)
		_flash(enemy_avatar)
		_pop_result(enemy_avatar, "-%d" % _enemy.poison, "독 피해", poison_color)
		_enemy.poison -= 1
	if _enemy.thunder > 0:
		_enemy.thunder -= 1

	_refill_hands()
	var mana_cap := _stats.mana_stat
	if _mana < mana_cap:
		_mana = min(mana_cap, _mana + MANA_REGEN + _stats.mana_regen_bonus)
	_update_status()
	await get_tree().create_timer(0.4).timeout

# ─────────────────────────── 카드 사용 ───────────────────────────

func _can_play(card: Dictionary) -> bool:
	if card.get("unplayable", false):
		return false
	match card["type"]:
		CardData.CardType.ATTACK:
			if _phase != CardData.CardType.ATTACK:
				return false
		CardData.CardType.DEFENSE:
			if _phase != CardData.CardType.DEFENSE:
				return false
	var cost: int = card["cost"]
	match CardData.cost_type_of(card, _stats.hp_instead_of_mana()):
		CardData.CostType.HP:
			## 체력으로 내는 카드는 쓰고 나서도 HP가 1 이상 남아야 한다
			return _stats.hp > cost
		CardData.CostType.GOLD:
			return _stats.gold >= cost
	return _mana >= cost

func _pay_cost(card: Dictionary) -> void:
	var cost: int = card["cost"]
	match CardData.cost_type_of(card, _stats.hp_instead_of_mana()):
		CardData.CostType.HP:
			_stats.take_damage(cost)
		CardData.CostType.GOLD:
			_stats.gold -= cost
		_:
			_mana -= cost

func _play_card(side: String, index: int) -> void:
	var card: Dictionary = _hands[side][index]
	if not _can_play(card):
		return
	_pay_cost(card)
	_hands[side].remove_at(index)
	_discard_piles[side].append(card)
	_refresh_hand()
	_update_status()
	match card["type"]:
		CardData.CardType.ATTACK:
			await _resolve_attack(card)
		CardData.CardType.DEFENSE:
			await _resolve_defense(card)
		_:
			_apply_card_effects(card)
			_pop_result(player_avatar, CardData.display_name(card), CardData.description(card).replace("\n", " · "), neutral_color)
	_update_status()

func _resolve_attack(card: Dictionary) -> void:
	var hits: int = card.get("hits", 1)
	for i in range(hits):
		var face: Variant = await _roll(card["dice"])
		var strength := _stats.strength + _temp_strength
		var thunder_bonus := _enemy.thunder
		var sword_bonus := 1 if _stats.has_item("trust_sword") and _enemy.thunder > 0 else 0
		var damage: int = Dice.face_value(face) + card["value"] + strength + thunder_bonus + sword_bonus
		_enemy.hp = max(0, _enemy.hp - damage)
		_show_dice_result(face, card["value"], strength)

		var detail := "주사위 %s + 카드 %d + 힘 %d" % [str(face), card["value"], strength]
		if thunder_bonus > 0:
			detail += " + 뇌문 %d" % thunder_bonus
		if sword_bonus > 0:
			detail += " + 신뢰검 1"
		_attack_sound.play()
		_play_attack_effect(card)
		_flash(enemy_avatar)
		_pop_result(enemy_avatar, "-%d" % damage, detail, damage_color)

		if Dice.is_thunder(face):
			_enemy.thunder += 1
		if card.get("lifesteal", false):
			var healed := _stats.heal(int(damage / 2.0))
			_pop_result(player_avatar, "+%d" % healed, "흡혈", heal_color)
		_update_status()
		if _enemy.hp <= 0:
			return
		if i < hits - 1:
			await get_tree().create_timer(0.3).timeout
	_apply_card_effects(card)

func _resolve_defense(card: Dictionary) -> void:
	var face: Variant = await _roll(card["dice"])
	var gain: int = Dice.face_value(face) + card["value"] + _stats.defense
	_shield += gain
	_show_dice_result(face, card["value"], _stats.defense)
	_defense_sound.play()
	_play_defense_effect(card)
	_pop_result(player_avatar, "보호막 +%d" % gain, "주사위 %s + 카드 %d + 방어 %d" % [str(face), card["value"], _stats.defense], defend_color)
	if Dice.is_thunder(face):
		_enemy.thunder += 1
	_apply_card_effects(card)

## 피해/보호막 외의 부가 효과(뇌문, 독, 회복, 카드 뽑기 등)
func _apply_card_effects(card: Dictionary) -> void:
	if card.has("thunder"):
		_enemy.thunder += card["thunder"]
		_pop_result(enemy_avatar, "뇌문 +%d" % card["thunder"], "공격받을 때 추가 피해", thunder_color)
	if card.has("poison"):
		var amount: int = card["poison"] + (1 if _stats.has_item("poison_gland") else 0)
		_enemy.poison += amount
		_pop_result(enemy_avatar, "독 +%d" % amount, "턴이 끝날 때 피해", poison_color)
	if card.get("poison_double", false):
		_enemy.poison *= 2
		_pop_result(enemy_avatar, "독 ×2", "독 %d" % _enemy.poison, poison_color)
	if card.has("heal"):
		var healed := _stats.heal(card["heal"])
		_pop_result(player_avatar, "+%d" % healed, "회복", heal_color)
	if card.has("temp_str"):
		_temp_strength += card["temp_str"]
	if card.has("draw"):
		## 지금 턴에 맞는 패(공격 턴이면 공격 패)로 뽑는다
		_draw_cards(CardData.SIDE_ATTACK if _phase == CardData.CardType.ATTACK else CardData.SIDE_DEFENSE, card["draw"])
	if card.has("mana_gain"):
		_mana += card["mana_gain"]
	_refresh_hand()
	_update_status()

func _discard_from_hand(side: String, index: int) -> void:
	_discard_piles[side].append(_hands[side][index])
	_hands[side].remove_at(index)

# ─────────────────────────── 덱/손패 ───────────────────────────

## side 덱(공격/방어)에서 count장을 뽑는다. 덱이 비면 같은 쪽 버린 카드 더미를 섞어서 다시 채운다
func _draw_cards(side: String, count: int) -> void:
	for i in range(count):
		if _draw_piles[side].is_empty():
			if _discard_piles[side].is_empty():
				return
			_draw_piles[side] = _discard_piles[side]
			_discard_piles[side] = []
			_draw_piles[side].shuffle()
		_hands[side].append(_draw_piles[side].pop_back())

## 턴 종료 시 공격 패·방어 패가 각각 3장 미만이면 3장이 될 때까지 뽑는다
func _refill_hands() -> void:
	for side in [CardData.SIDE_ATTACK, CardData.SIDE_DEFENSE]:
		if _hands[side].size() < CardData.HAND_SIZE:
			_draw_cards(side, CardData.HAND_SIZE - _hands[side].size())
	_refresh_hand()

func _set_input(enabled: bool) -> void:
	_input_enabled = enabled
	_refresh_hand()
	_update_status()

func _refresh_hand() -> void:
	for side in _hand_boxes:
		var box: HBoxContainer = _hand_boxes[side]
		for child in box.get_children():
			box.remove_child(child)
			child.queue_free()
		if not _hands.has(side):
			continue
		var hand: Array = _hands[side]
		for i in range(hand.size()):
			var widget := CardWidget.new()
			widget.setup(hand[i], _stats.hp_instead_of_mana())
			var playable := _input_enabled and (_discard_mode or _can_play(hand[i]))
			widget.set_playable(playable)
			widget.pressed.connect(_send_input.bind(side, i))
			box.add_child(widget)

# ─────────────────────────── 주사위 ───────────────────────────

## kind 주사위를 굴려 나온 면을 반환한다. D6는 3D 주사위, 나머지는 숫자가 빠르게 바뀌는 연출
func _roll(kind: String) -> Variant:
	if Dice.uses_3d(kind):
		_dice2d_panel.visible = false
		var value: int = await dice_3d_view.roll()
		return value
	_dice2d_panel.visible = true
	_dice2d_kind.text = Dice.display_name(kind)
	_roll_sound.play()
	var faces: Array = Dice.FACES[kind]
	for i in range(14):
		_dice2d_label.text = str(faces.pick_random())
		await get_tree().create_timer(0.045).timeout
	var face: Variant = Dice.roll_face(kind)
	_dice2d_label.text = str(face)
	await get_tree().create_timer(0.25).timeout
	return face

## 주사위 밑에 "굴린 값 + 카드 값 + 스탯"을 큰 글씨로 표시한다
func _show_dice_result(face: Variant, card_value: int, stat_value: int) -> void:
	dice_roll_label.text = str(face)
	dice_skill_label.text = "+%d" % card_value if card_value != 0 else ""
	dice_stat_label.text = "+%d" % stat_value if stat_value != 0 else ""

# ─────────────────────────── 화면 갱신 ───────────────────────────

func _update_status() -> void:
	if _enemy == null or _stats == null:
		return
	enemy_name_label.text = _enemy.enemy_name
	enemy_hp_label.text = "HP %d / %d" % [_enemy.hp, _enemy.max_hp]
	enemy_hp_bar.max_value = _enemy.max_hp
	enemy_hp_bar.value = _enemy.hp
	var status: Array[String] = []
	if _enemy.thunder > 0:
		status.append("뇌문 %d" % _enemy.thunder)
	if _enemy.poison > 0:
		status.append("독 %d" % _enemy.poison)
	_enemy_status_label.text = " · ".join(status)

	player_hp_bar.max_value = _stats.max_hp
	player_hp_bar.value = _stats.hp
	if _stats.hp_instead_of_mana():
		player_status_label.text = "HP %d/%d · 카드에 HP 소모" % [_stats.hp, _stats.max_hp]
		player_mana_bar.max_value = 1
		player_mana_bar.value = 0
	else:
		player_status_label.text = "HP %d/%d · 마나 %d/%d" % [_stats.hp, _stats.max_hp, _mana, _stats.mana_stat]
		player_mana_bar.max_value = max(1, _stats.mana_stat)
		player_mana_bar.value = _mana
	var strength_text := "힘 %d · 방어 %d" % [_stats.strength + _temp_strength, _stats.defense]
	_shield_label.text = ("보호막 %d · " % _shield if _shield > 0 else "") + strength_text
	_pile_label.text = "공격 덱 %d · 버림 %d   |   방어 덱 %d · 버림 %d   |   골드 %d" % [
		_draw_piles[CardData.SIDE_ATTACK].size(), _discard_piles[CardData.SIDE_ATTACK].size(),
		_draw_piles[CardData.SIDE_DEFENSE].size(), _discard_piles[CardData.SIDE_DEFENSE].size(), _stats.gold]

	_end_turn_button.disabled = not _input_enabled
	_discard_button.disabled = not _input_enabled
	_discard_button.text = "버리기 모드: 켜짐" if _discard_mode else "카드 버리기"
	_potion_button.text = "포션 사용 (%d)" % _stats.potions
	_potion_button.disabled = not _input_enabled or _stats.potions <= 0 or _stats.hp >= _stats.max_hp

## 턴 이름을 색깔 있게 보여주고, 이번 턴의 주인공 아바타는 밝게·상대는 살짝 어둡게 한다
func _show_turn(text: String, active_avatar: ColorRect, inactive_avatar: ColorRect, color: Color) -> void:
	turn_label.text = text
	turn_label.add_theme_color_override("font_color", color)
	active_avatar.modulate = Color(1, 1, 1)
	inactive_avatar.modulate = inactive_dim_color
	dice_3d_view.set_floor_color(color)
	await get_tree().create_timer(TURN_PAUSE).timeout
	inactive_avatar.modulate = Color(1, 1, 1)

# ─────────────────────────── 연출 ───────────────────────────

func _play_attack_effect(card: Dictionary) -> void:
	var offset := Vector2(lunge_distance, 0)
	if card.get("hits", 1) > 1:
		_effect_multi_slash(player_avatar, offset)
	elif card["dice"] == "D20":
		_effect_finishing_blow(player_avatar, offset, enemy_avatar)
	elif card["value"] >= 3:
		_effect_heavy_strike(player_avatar, offset, enemy_avatar)
	else:
		_lunge(player_avatar, offset)

func _play_defense_effect(card: Dictionary) -> void:
	if card["id"] == "dodge":
		_effect_dodge(player_avatar)
	elif card["dice"] == "D12" or card["dice"] == "D20":
		_effect_iron_wall(player_avatar)
	else:
		_effect_shield(player_avatar)

## 피해를 입은 쪽의 아바타를 짧게 붉게 번쩍여 타격감을 준다
func _flash(avatar: ColorRect) -> void:
	avatar.modulate = flash_color
	var tween := create_tween()
	tween.tween_property(avatar, "modulate", Color(1, 1, 1), flash_duration)

## 공격하는 쪽이 상대 방향으로 살짝 튀어나갔다가 돌아오는 모션
func _lunge(avatar: ColorRect, offset: Vector2) -> void:
	var original_pos := avatar.position
	var tween := create_tween()
	tween.tween_property(avatar, "position", original_pos + offset, 0.1)
	tween.tween_property(avatar, "position", original_pos, 0.15)

## 강타: 크게 튀어나가고, 맞는 쪽이 움찔하며 찌그러진다
func _effect_heavy_strike(actor: ColorRect, offset: Vector2, target: ColorRect) -> void:
	_lunge(actor, offset * 1.6)
	var original_scale := target.scale
	var tween := create_tween()
	tween.tween_property(target, "scale", original_scale * 0.8, 0.08)
	tween.tween_property(target, "scale", original_scale, 0.15)

## 연속 베기: 짧게 여러 번 튀어나갔다 돌아온다
func _effect_multi_slash(actor: ColorRect, offset: Vector2) -> void:
	var original_pos := actor.position
	var tween := create_tween()
	for i in range(3):
		tween.tween_property(actor, "position", original_pos + offset * 0.55, 0.05)
		tween.tween_property(actor, "position", original_pos, 0.05)

## 방패: 파란 방패막이 잠깐 나타났다 사라진다
func _effect_shield(actor: ColorRect) -> void:
	var shield := ColorRect.new()
	shield.color = Color(0.3, 0.8, 1.0, 0.55)
	shield.size = actor.size * 1.15
	shield.position = actor.position - (shield.size - actor.size) * 0.5
	actor.get_parent().add_child(shield)
	shield.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(shield, "modulate:a", 1.0, 0.1)
	tween.tween_property(shield, "modulate:a", 0.0, 0.35)
	tween.tween_callback(shield.queue_free)

## 회피: 위로 살짝 폴짝 뛰었다 내려온다
func _effect_dodge(actor: ColorRect) -> void:
	var original_pos := actor.position
	var tween := create_tween()
	tween.tween_property(actor, "position", original_pos + Vector2(0, -25), 0.08)
	tween.tween_property(actor, "position", original_pos, 0.12)

## 필살기: 강타보다 더 크게 튀어나가고, 노랗게 번쩍이며 상대가 더 크게 찌그러진다
func _effect_finishing_blow(actor: ColorRect, offset: Vector2, target: ColorRect) -> void:
	_lunge(actor, offset * 2.0)
	var flash_tween := create_tween()
	flash_tween.tween_property(actor, "modulate", Color(1.0, 0.9, 0.4), 0.06)
	flash_tween.tween_property(actor, "modulate", Color(1, 1, 1), 0.2)
	var original_scale := target.scale
	var tween := create_tween()
	tween.tween_property(target, "scale", original_scale * 0.7, 0.08)
	tween.tween_property(target, "scale", original_scale, 0.18)

## 철벽: 방패보다 더 크고 오래가는 회색 방벽이 나타났다 사라진다
func _effect_iron_wall(actor: ColorRect) -> void:
	var wall := ColorRect.new()
	wall.color = Color(0.6, 0.65, 0.7, 0.65)
	wall.size = actor.size * 1.3
	wall.position = actor.position - (wall.size - actor.size) * 0.5
	actor.get_parent().add_child(wall)
	wall.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(wall, "modulate:a", 1.0, 0.1)
	tween.tween_property(wall, "modulate:a", 0.0, 0.55)
	tween.tween_callback(wall.queue_free)

## 아바타 위에 결과(큰 글씨)와 계산 내역(작은 글씨)을 함께 띄웠다가 위로 떠오르며 사라지게 한다
func _pop_result(avatar: ColorRect, main_text: String, detail_text: String, color: Color) -> void:
	var container := VBoxContainer.new()
	container.position = avatar.position + Vector2(avatar.size.x * 0.5 - 90, -30 + randf_range(-12, 12))
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar.get_parent().add_child(container)

	var main_label := UiKit.label(main_text, popup_main_font_size, color)
	container.add_child(main_label)
	var detail_label := UiKit.label(detail_text, popup_detail_font_size, Color(1, 1, 1, 0.85))
	container.add_child(detail_label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(container, "position:y", container.position.y - popup_float_distance, popup_duration)
	tween.tween_property(container, "modulate:a", 0.0, popup_duration)
	tween.chain().tween_callback(container.queue_free)
