class_name BattleView
extends Control

## 액션 버튼이 눌리면 선택된 옵션 Dictionary를 담아 발신
signal action_chosen(option: Dictionary)

@onready var enemy_name_label: Label = $Background/EnemyNameLabel
@onready var enemy_hp_label: Label = $Background/EnemyHpLabel
@onready var player_status_label: Label = $Background/PlayerStatusLabel
@onready var battle_log_label: Label = $Background/BattleLogLabel
@onready var action_container: VBoxContainer = $Background/ActionContainer

var _stats: PlayerStats
var _enemy: EnemyData

func _ready() -> void:
	visible = false

## 전투를 진행하고 승리하면 true, 패배하면 false를 반환한다
func start_battle(stats: PlayerStats, enemy: EnemyData) -> bool:
	_stats = stats
	_enemy = enemy
	visible = true
	battle_log_label.text = ""
	_log("%s 등장! (HP %d)" % [enemy.enemy_name, enemy.hp])
	_update_status()

	while true:
		await _player_attack_phase()
		_update_status()
		if _enemy.hp <= 0:
			_log("%s 처치! 전투 승리" % _enemy.enemy_name)
			visible = false
			return true

		await _enemy_attack_phase()
		_stats.mana = min(_stats.mana_max, _stats.mana + 1)
		_update_status()
		if _stats.hp <= 0:
			## Day5 폴리싱 전까지는 패배해도 HP를 회복해 게임이 막히지 않게 한다
			_log("쓰러졌다... HP를 회복하고 계속 진행합니다")
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

	var roll := Dice.roll()
	var damage: int = roll + _stats.attack + chosen["power"]
	_enemy.hp = max(0, _enemy.hp - damage)
	_log("%s → 주사위 %d + 공격 %d + 위력 %d = %d 피해" % [chosen["label"], roll, _stats.attack, chosen["power"], damage])

## 기본 방어도 전투당이 아니라 턴당 1회 — 매 턴 다시 사용 가능
func _enemy_attack_phase() -> void:
	var enemy_roll := Dice.roll()
	var enemy_damage: int = enemy_roll + _enemy.attack
	_log("%s의 공격! (주사위 %d + 공격 %d = %d)" % [_enemy.enemy_name, enemy_roll, _enemy.attack, enemy_damage])

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

	var roll := Dice.roll()
	var mitigation: int = roll + _stats.defense + chosen["power"]
	var final_damage: int = max(0, enemy_damage - mitigation)
	_stats.hp = max(0, _stats.hp - final_damage)
	_log("%s → 주사위 %d + 방어 %d + 경감 %d = %d 경감 → 최종 피해 %d" % [chosen["label"], roll, _stats.defense, chosen["power"], mitigation, final_damage])

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
	player_status_label.text = "내 HP %d/%d · 마력 %d/%d" % [_stats.hp, _stats.max_hp, _stats.mana, _stats.mana_max]

func _log(message: String) -> void:
	battle_log_label.text += message + "\n"
