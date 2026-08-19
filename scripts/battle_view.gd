class_name BattleView
extends Control

## 액션 버튼이 눌리면 선택된 옵션 Dictionary를 담아 발신
signal action_chosen(option: Dictionary)

@onready var enemy_avatar: ColorRect = $Background/EnemyAvatar
@onready var enemy_name_label: Label = $Background/EnemyNameLabel
@onready var enemy_hp_bar: ProgressBar = $Background/EnemyHpBar
@onready var enemy_hp_label: Label = $Background/EnemyHpLabel
@onready var player_avatar: ColorRect = $Background/PlayerAvatar
@onready var player_hp_bar: ProgressBar = $Background/PlayerHpBar
@onready var player_mana_bar: ProgressBar = $Background/PlayerManaBar
@onready var player_status_label: Label = $Background/PlayerStatusLabel
@onready var action_container: VBoxContainer = $Background/ActionContainer
@onready var dice_3d_view: Dice3DView = $Background/BattleDiceView
@onready var dice_roll_label: Label = $Background/DiceResultRow/DiceRollLabel
@onready var dice_stat_label: Label = $Background/DiceResultRow/DiceStatLabel
@onready var turn_label: Label = $Background/TurnLabel

## 턴이 바뀌었을 때 잠깐 멈춰서 구분되게 보여줄 시간(초)
const TURN_PAUSE := 0.7
## 전투 승리 시 회복되는 HP
const VICTORY_HEAL := 5
## 승패가 갈린 뒤 결과 팝업을 보여주고 화면을 닫기까지 대기 시간(초)
const RESULT_PAUSE := 0.9

var _stats: PlayerStats
var _enemy: EnemyData

func _ready() -> void:
	visible = false

## 전투를 진행하고 승리하면 true, 패배하면 false를 반환한다
func start_battle(stats: PlayerStats, enemy: EnemyData) -> bool:
	_stats = stats
	_enemy = enemy
	visible = true
	dice_roll_label.text = ""
	dice_stat_label.text = ""
	_update_status()
	_pop_result(enemy_avatar, "등장!", enemy.enemy_name, Color(1, 1, 1))

	while true:
		await _show_turn("내 턴")
		await _player_attack_phase()
		_update_status()
		if _enemy.hp <= 0:
			_stats.hp = min(_stats.max_hp, _stats.hp + VICTORY_HEAL)
			_update_status()
			_pop_result(enemy_avatar, "승리!", "%s 처치" % _enemy.enemy_name, Color(1.0, 0.85, 0.3))
			_pop_result(player_avatar, "+%d" % VICTORY_HEAL, "체력 회복", Color(0.3, 1.0, 0.4))
			await get_tree().create_timer(RESULT_PAUSE).timeout
			visible = false
			return true

		await _show_turn("상대 턴")
		await _enemy_attack_phase()
		_stats.mana = min(_stats.mana_max, _stats.mana + 1)
		_update_status()
		if _stats.hp <= 0:
			## Day5 폴리싱 전까지는 패배해도 HP를 회복해 게임이 막히지 않게 한다
			_pop_result(player_avatar, "기절...", "HP 회복 후 계속", Color(1.0, 0.5, 0.5))
			await get_tree().create_timer(RESULT_PAUSE).timeout
			_stats.hp = _stats.max_hp
			visible = false
			return false

	return false # 이 지점에는 도달하지 않음(while true 내부에서 항상 반환됨). 정적 분석기용.

## 한 번 호출될 때마다 "한 턴"에 해당하며, 버튼을 하나 고르면 바로 다음 턴으로 넘어간다
## (기본 공격은 전투당이 아니라 턴당 1회 — 매 턴 다시 사용 가능)
func _player_attack_phase() -> void:
	var options: Array[Dictionary] = [{
		"label": "기본 공격 (마력 소모 없음)",
		"kind": "basic",
		"cost": 0,
		"power": 0,
		"disabled": false,
	}]
	for card in _stats.skill_cards:
		if card["category"] == GameContent.SkillCategory.ATTACK:
			options.append({
				"label": "%s (마력 %d, 위력 +%d)" % [card["name"], card["cost"], card["power"]],
				"kind": "skill",
				"cost": card["cost"],
				"power": card["power"],
				"disabled": _stats.mana < card["cost"],
			})

	var chosen := await _choose_action(options)
	if chosen["kind"] == "skill":
		_stats.mana -= chosen["cost"]

	var roll := await dice_3d_view.roll()
	_show_dice_result(roll, _stats.attack)
	var damage: int = roll + _stats.attack + chosen["power"]
	_enemy.hp = max(0, _enemy.hp - damage)
	_lunge(player_avatar, Vector2(55, 0))
	_flash(enemy_avatar)
	_pop_result(enemy_avatar, "-%d" % damage, "주사위%d +공격%d +위력%d" % [roll, _stats.attack, chosen["power"]], Color(1.0, 0.4, 0.3))

## 기본 방어도 전투당이 아니라 턴당 1회 — 매 턴 다시 사용 가능
func _enemy_attack_phase() -> void:
	var enemy_roll := await dice_3d_view.roll()
	_show_dice_result(enemy_roll, _enemy.attack)
	var enemy_damage: int = enemy_roll + _enemy.attack
	_pop_result(enemy_avatar, "공격!", "주사위%d +공격%d = %d" % [enemy_roll, _enemy.attack, enemy_damage], Color(1.0, 0.6, 0.3))

	var options: Array[Dictionary] = [{
		"label": "기본 방어 (마력 소모 없음)",
		"kind": "basic",
		"cost": 0,
		"power": 0,
		"disabled": false,
	}]
	for card in _stats.skill_cards:
		if card["category"] == GameContent.SkillCategory.DEFENSE:
			options.append({
				"label": "%s (마력 %d, 경감 +%d)" % [card["name"], card["cost"], card["power"]],
				"kind": "skill",
				"cost": card["cost"],
				"power": card["power"],
				"disabled": _stats.mana < card["cost"],
			})

	var chosen := await _choose_action(options)
	if chosen["kind"] == "skill":
		_stats.mana -= chosen["cost"]

	var roll := await dice_3d_view.roll()
	_show_dice_result(roll, _stats.defense)
	var mitigation: int = roll + _stats.defense + chosen["power"]
	var final_damage: int = max(0, enemy_damage - mitigation)
	_stats.hp = max(0, _stats.hp - final_damage)
	_lunge(enemy_avatar, Vector2(-55, 0))
	if final_damage > 0:
		_flash(player_avatar)
		_pop_result(player_avatar, "-%d" % final_damage, "주사위%d +방어%d +경감%d" % [roll, _stats.defense, chosen["power"]], Color(1.0, 0.4, 0.3))
	else:
		_pop_result(player_avatar, "완전 방어!", "주사위%d +방어%d +경감%d" % [roll, _stats.defense, chosen["power"]], Color(0.4, 0.8, 1.0))

## 주사위 밑에 "굴린 값 + 스탯"을 큰 글씨로 표시한다
func _show_dice_result(roll: int, stat_value: int) -> void:
	dice_roll_label.text = str(roll)
	dice_stat_label.text = "+%d" % stat_value if stat_value != 0 else ""

## 턴 이름을 잠깐 크게 보여줘서 내 턴/상대 턴을 눈으로 구분하기 쉽게 한다
func _show_turn(text: String) -> void:
	turn_label.text = text
	await get_tree().create_timer(TURN_PAUSE).timeout

## 옵션 버튼들을 만들어 보여주고, 플레이어가 하나를 누를 때까지 기다린다
func _choose_action(options: Array[Dictionary]) -> Dictionary:
	for child in action_container.get_children():
		child.queue_free()
	for option in options:
		var button := Button.new()
		button.text = option["label"]
		button.disabled = option["disabled"]
		button.pressed.connect(_on_action_pressed.bind(option))
		action_container.add_child(button)
	var result: Dictionary = await action_chosen
	for child in action_container.get_children():
		child.queue_free()
	return result

func _on_action_pressed(option: Dictionary) -> void:
	action_chosen.emit(option)

func _update_status() -> void:
	enemy_name_label.text = _enemy.enemy_name
	enemy_hp_label.text = "HP %d / %d" % [_enemy.hp, _enemy.max_hp]
	enemy_hp_bar.max_value = _enemy.max_hp
	enemy_hp_bar.value = _enemy.hp

	player_status_label.text = "내 HP %d/%d · 마력 %d/%d" % [_stats.hp, _stats.max_hp, _stats.mana, _stats.mana_max]
	player_hp_bar.max_value = _stats.max_hp
	player_hp_bar.value = _stats.hp
	player_mana_bar.max_value = max(1, _stats.mana_max)
	player_mana_bar.value = _stats.mana

## 피해를 입은 쪽의 아바타를 짧게 붉게 번쩍여 타격감을 준다
func _flash(avatar: ColorRect) -> void:
	avatar.modulate = Color(1.0, 0.4, 0.4)
	var tween := create_tween()
	tween.tween_property(avatar, "modulate", Color(1, 1, 1), 0.3)

## 공격하는 쪽이 상대 방향으로 살짝 튀어나갔다가 돌아오는 모션
func _lunge(avatar: ColorRect, offset: Vector2) -> void:
	var original_pos := avatar.position
	var tween := create_tween()
	tween.tween_property(avatar, "position", original_pos + offset, 0.1)
	tween.tween_property(avatar, "position", original_pos, 0.15)

## 아바타 위에 결과(큰 글씨)와 스탯 계산 내역(작은 글씨)을 함께 띄웠다가 위로 떠오르며 사라지게 한다
func _pop_result(avatar: ColorRect, main_text: String, detail_text: String, color: Color) -> void:
	var container := VBoxContainer.new()
	container.position = avatar.position + Vector2(avatar.size.x * 0.5 - 60, -30)
	avatar.get_parent().add_child(container)

	var main_label := Label.new()
	main_label.text = main_text
	main_label.add_theme_color_override("font_color", color)
	main_label.add_theme_font_size_override("font_size", 40)
	container.add_child(main_label)

	var detail_label := Label.new()
	detail_label.text = detail_text
	detail_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	detail_label.add_theme_font_size_override("font_size", 16)
	container.add_child(detail_label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(container, "position:y", container.position.y - 60, 0.9)
	tween.tween_property(container, "modulate:a", 0.0, 0.9)
	tween.chain().tween_callback(container.queue_free)
