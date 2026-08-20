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
@onready var dice_skill_label: Label = $Background/DiceResultRow/DiceSkillLabel
@onready var dice_stat_label: Label = $Background/DiceResultRow/DiceStatLabel
@onready var turn_label: Label = $Background/TurnLabel

## 턴이 바뀌었을 때 잠깐 멈춰서 구분되게 보여줄 시간(초)
const TURN_PAUSE := 0.7
## 전투 승리 시 회복되는 HP
const VICTORY_HEAL := 5
## 승패가 갈린 뒤 결과 팝업을 보여주고 화면을 닫기까지 대기 시간(초)
const RESULT_PAUSE := 0.9

@export_group("결과 팝업 색상")
@export var neutral_color: Color = Color(1, 1, 1)
@export var damage_color: Color = Color(1.0, 0.4, 0.3)
@export var victory_color: Color = Color(1.0, 0.85, 0.3)
@export var heal_color: Color = Color(0.3, 1.0, 0.4)
@export var faint_color: Color = Color(1.0, 0.5, 0.5)
@export var enemy_attack_color: Color = Color(1.0, 0.6, 0.3)
@export var defend_color: Color = Color(0.4, 0.8, 1.0)

@export_group("결과 팝업 크기/움직임")
@export var popup_main_font_size: int = 40
@export var popup_detail_font_size: int = 16
@export var popup_float_distance: float = 60.0
@export var popup_duration: float = 0.9

@export_group("타격 연출")
@export var flash_color: Color = Color(1.0, 0.4, 0.4)
@export var flash_duration: float = 0.3
@export var lunge_distance: float = 55.0

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
	dice_skill_label.text = ""
	dice_stat_label.text = ""
	_update_status()
	_pop_result(enemy_avatar, "등장!", enemy.enemy_name, neutral_color)

	while true:
		await _show_turn("내 턴")
		await _player_attack_phase()
		_update_status()
		if _enemy.hp <= 0:
			_stats.hp = min(_stats.max_hp, _stats.hp + VICTORY_HEAL)
			_update_status()
			_pop_result(enemy_avatar, "승리!", "%s 처치" % _enemy.enemy_name, victory_color)
			_pop_result(player_avatar, "+%d" % VICTORY_HEAL, "체력 회복", heal_color)
			await get_tree().create_timer(RESULT_PAUSE).timeout
			visible = false
			return true

		await _show_turn("상대 턴")
		await _enemy_attack_phase()
		_stats.mana = min(_stats.mana_max, _stats.mana + 1)
		_update_status()
		if _stats.hp <= 0:
			## Day5 폴리싱 전까지는 패배해도 HP를 회복해 게임이 막히지 않게 한다
			_pop_result(player_avatar, "기절...", "HP 회복 후 계속", faint_color)
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
				"name": card["name"],
				"kind": "skill",
				"cost": card["cost"],
				"power": card["power"],
				"disabled": _stats.mana < card["cost"],
			})

	var chosen := await _choose_action(options)
	if chosen["kind"] == "skill":
		_stats.mana = max(0, _stats.mana - chosen["cost"])

	var roll := await dice_3d_view.roll()
	_show_dice_result(roll, _stats.attack, chosen["power"])
	var damage: int = roll + _stats.attack + chosen["power"]
	_enemy.hp = max(0, _enemy.hp - damage)
	if chosen["kind"] == "skill":
		_play_skill_effect(chosen["name"], player_avatar, Vector2(lunge_distance, 0), enemy_avatar)
	else:
		_lunge(player_avatar, Vector2(lunge_distance, 0))
	_flash(enemy_avatar)
	_pop_result(enemy_avatar, "-%d" % damage, "주사위%d +공격%d +위력%d" % [roll, _stats.attack, chosen["power"]], damage_color)

## 기본 방어도 전투당이 아니라 턴당 1회 — 매 턴 다시 사용 가능
func _enemy_attack_phase() -> void:
	var enemy_roll := await dice_3d_view.roll()
	_show_dice_result(enemy_roll, _enemy.attack)
	var enemy_damage: int = enemy_roll + _enemy.attack
	_pop_result(enemy_avatar, "공격!", "주사위%d +공격%d = %d" % [enemy_roll, _enemy.attack, enemy_damage], enemy_attack_color)

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
				"name": card["name"],
				"kind": "skill",
				"cost": card["cost"],
				"power": card["power"],
				"disabled": _stats.mana < card["cost"],
			})

	var chosen := await _choose_action(options)
	if chosen["kind"] == "skill":
		_stats.mana = max(0, _stats.mana - chosen["cost"])

	var roll := await dice_3d_view.roll()
	_show_dice_result(roll, _stats.defense, chosen["power"])
	var mitigation: int = roll + _stats.defense + chosen["power"]
	var final_damage: int = max(0, enemy_damage - mitigation)
	_stats.hp = max(0, _stats.hp - final_damage)
	_lunge(enemy_avatar, Vector2(-lunge_distance, 0))
	if chosen["kind"] == "skill":
		_play_skill_effect(chosen["name"], player_avatar, Vector2(-lunge_distance, 0))
	if final_damage > 0:
		_flash(player_avatar)
		_pop_result(player_avatar, "-%d" % final_damage, "주사위%d +방어%d +경감%d" % [roll, _stats.defense, chosen["power"]], damage_color)
	else:
		_pop_result(player_avatar, "완전 방어!", "주사위%d +방어%d +경감%d" % [roll, _stats.defense, chosen["power"]], defend_color)

## 주사위 밑에 "굴린 값 + 스킬 위력 + 스탯"을 큰 글씨로 표시한다(스킬 위력은 스킬을 썼을 때만)
func _show_dice_result(roll: int, stat_value: int, skill_power: int = 0) -> void:
	dice_roll_label.text = str(roll)
	dice_skill_label.text = "+%d" % skill_power if skill_power != 0 else ""
	dice_stat_label.text = "+%d" % stat_value if stat_value != 0 else ""

## 턴 이름을 잠깐 크게 보여줘서 내 턴/상대 턴을 눈으로 구분하기 쉽게 한다
func _show_turn(text: String) -> void:
	turn_label.text = text
	await get_tree().create_timer(TURN_PAUSE).timeout

## 스킬 이름 → 버튼에 붙일 아이콘 경로
const SKILL_ICON_PATHS := {
	"강타": "res://assets/icons/skill_heavy_strike.svg",
	"연속 베기": "res://assets/icons/skill_multi_slash.svg",
	"필살기": "res://assets/icons/skill_finishing_blow.svg",
	"방패 올리기": "res://assets/icons/skill_shield.svg",
	"회피": "res://assets/icons/skill_dodge.svg",
	"철벽": "res://assets/icons/skill_iron_wall.svg",
}

## 옵션 버튼들을 만들어 보여주고, 플레이어가 하나를 누를 때까지 기다린다
func _choose_action(options: Array[Dictionary]) -> Dictionary:
	for child in action_container.get_children():
		child.queue_free()
	for option in options:
		var button := Button.new()
		button.text = option["label"]
		button.disabled = option["disabled"]
		if option["kind"] == "skill" and SKILL_ICON_PATHS.has(option["name"]):
			button.icon = load(SKILL_ICON_PATHS[option["name"]])
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
	avatar.modulate = flash_color
	var tween := create_tween()
	tween.tween_property(avatar, "modulate", Color(1, 1, 1), flash_duration)

## 공격하는 쪽이 상대 방향으로 살짝 튀어나갔다가 돌아오는 모션
func _lunge(avatar: ColorRect, offset: Vector2) -> void:
	var original_pos := avatar.position
	var tween := create_tween()
	tween.tween_property(avatar, "position", original_pos + offset, 0.1)
	tween.tween_property(avatar, "position", original_pos, 0.15)

## 스킬 이름에 따라 서로 다른 연출을 재생한다(모르는 이름이면 기본 lunge로 대체)
func _play_skill_effect(skill_name: String, actor: ColorRect, offset: Vector2, target: ColorRect = null) -> void:
	match skill_name:
		"강타":
			_effect_heavy_strike(actor, offset, target)
		"연속 베기":
			_effect_multi_slash(actor, offset)
		"필살기":
			_effect_finishing_blow(actor, offset, target)
		"방패 올리기":
			_effect_shield(actor)
		"회피":
			_effect_dodge(actor)
		"철벽":
			_effect_iron_wall(actor)
		_:
			_lunge(actor, offset)

## 강타: 크게 튀어나가고, 맞는 쪽이 움찔하며 찌그러진다
func _effect_heavy_strike(actor: ColorRect, offset: Vector2, target: ColorRect) -> void:
	_lunge(actor, offset * 1.6)
	if target == null:
		return
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

## 방패 올리기: 파란 방패막이 잠깐 나타났다 사라진다
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
	if target == null:
		return
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

## 아바타 위에 결과(큰 글씨)와 스탯 계산 내역(작은 글씨)을 함께 띄웠다가 위로 떠오르며 사라지게 한다
func _pop_result(avatar: ColorRect, main_text: String, detail_text: String, color: Color) -> void:
	var container := VBoxContainer.new()
	container.position = avatar.position + Vector2(avatar.size.x * 0.5 - 60, -30)
	avatar.get_parent().add_child(container)

	var main_label := Label.new()
	main_label.text = main_text
	main_label.add_theme_color_override("font_color", color)
	main_label.add_theme_font_size_override("font_size", popup_main_font_size)
	container.add_child(main_label)

	var detail_label := Label.new()
	detail_label.text = detail_text
	detail_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	detail_label.add_theme_font_size_override("font_size", popup_detail_font_size)
	container.add_child(detail_label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(container, "position:y", container.position.y - popup_float_distance, popup_duration)
	tween.tween_property(container, "modulate:a", 0.0, popup_duration)
	tween.chain().tween_callback(container.queue_free)
