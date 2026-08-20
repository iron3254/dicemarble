extends Node2D

## 승리에 필요한 완주 바퀴 수
@export var win_laps: int = 3
## 한 바퀴를 완주할 때마다 늘어나는 최대 HP
@export var lap_max_hp_bonus: int = 10

@export_group("팝업 효과 디자인")
@export var gain_color: Color = Color(0.3, 1.0, 0.4)
@export var loss_color: Color = Color(1.0, 0.4, 0.4)
@export var skill_color: Color = Color(1.0, 0.85, 0.3)
@export var popup_font_size: int = 32
@export var popup_float_distance: float = 50.0
@export var popup_duration: float = 1.1

var board_data: BoardData
var player: PlayerToken
var stats: PlayerStats

@onready var status_label: Label = $UI/StatusLabel
@onready var stats_label: Label = $UI/StatsLabel
@onready var roll_button: Button = $UI/RollButton
@onready var board_view: BoardView = $BoardView
@onready var dice_3d_view: Dice3DView = $UI/Dice3DView
@onready var stat_choice_view: StatChoiceView = $UI/StatChoiceView
@onready var battle_view: BattleView = $UI/BattleView
@onready var big_hp_label: Label = $UI/BigHpLabel
@onready var big_hp_bar: ProgressBar = $UI/BigHpBar
@onready var big_attack_label: Label = $UI/BigAttackLabel
@onready var big_defense_label: Label = $UI/BigDefenseLabel
@onready var big_mana_label: Label = $UI/BigManaLabel
@onready var big_skill_label: Label = $UI/BigSkillLabel
@onready var win_label: Label = $UI/WinLabel

func _ready() -> void:
	board_data = BoardData.new()
	player = PlayerToken.new()
	stats = PlayerStats.new()
	board_view.setup(board_data)
	roll_button.pressed.connect(take_turn)
	_update_status()

## 한 턴 진행: 3D 주사위를 굴려 이동 → 지나친 꼭짓점 처리 → 도착 칸 효과 → 승리 체크
func take_turn() -> void:
	roll_button.disabled = true
	var steps := await dice_3d_view.roll()

	var start_index := player.board_index
	var passed_corners := player.move(steps, board_data)
	await board_view.animate_move(start_index, steps)
	_update_status()

	for corner_index in passed_corners:
		await _resolve_corner(corner_index)

	if not board_data.is_corner(player.board_index):
		_resolve_cell(board_data.get_cell_type(player.board_index), player.board_index)

	_update_status()

	if player.lap_count >= win_laps:
		win_label.text = "%d바퀴 완주! 승리!" % win_laps
	else:
		roll_button.disabled = false

## 출발선 보스를 잡았을 때: 최대 HP를 늘리고 HP를 전부 회복시킨다
func _on_boss_defeated() -> void:
	stats.max_hp += lap_max_hp_bonus
	stats.hp = stats.max_hp
	_update_status()
	_float_popup(big_hp_label.position + Vector2(0.0, -44.0),
		"최대 HP +%d, 전부 회복!" % lap_max_hp_bonus, gain_color)

## 이동 경로에서 지나친 꼭짓점칸을 처리한다(출발칸이면 스탯 선택 후 보스 전투, 아니면 일반 전투)
func _resolve_corner(index: int) -> void:
	var cell_type := board_data.get_cell_type(index)
	var is_boss := cell_type == BoardData.CellType.START
	if is_boss:
		var chosen: PlayerStats.StatType = await stat_choice_view.ask()
		stats.add_stat(chosen, 1)
		_show_stat_gain(chosen, 1)
		_update_status()

	var enemy := EnemyData.create_boss(player.lap_count, win_laps) if is_boss else EnemyData.create_normal(index)
	var won: bool = await battle_view.start_battle(stats, enemy)
	if won:
		var reward_stat: PlayerStats.StatType = PlayerStats.ALL_STATS.pick_random()
		stats.add_stat(reward_stat, 1)
		_show_stat_gain(reward_stat, 1)
		if is_boss:
			_on_boss_defeated()
	else:
		## 패배 페널티: 승리 보상(랜덤 스탯 +1)과 정반대로 랜덤 스탯 -1
		var penalty_stat: PlayerStats.StatType = PlayerStats.ALL_STATS.pick_random()
		stats.add_stat(penalty_stat, -1)
		_show_stat_gain(penalty_stat, -1)
	_update_status()

## 도착한 칸의 종류에 따라 효과를 적용한다
func _resolve_cell(cell_type: BoardData.CellType, index: int) -> void:
	match cell_type:
		BoardData.CellType.STAT:
			var stat_type: PlayerStats.StatType = PlayerStats.ALL_STATS.pick_random()
			stats.add_stat(stat_type, 1)
			_show_stat_gain(stat_type, 1)
		BoardData.CellType.EVENT:
			var card: Dictionary = GameContent.draw_event_card()
			stats.add_stat(card["stat"], card["amount"])
			_show_stat_gain(card["stat"], card["amount"])
		BoardData.CellType.RANDOM:
			var effect: Dictionary = GameContent.roll_random_effect()
			stats.add_stat(effect["stat"], effect["amount"])
			_show_stat_gain(effect["stat"], effect["amount"])
		BoardData.CellType.SKILL:
			var owned_names := stats.skill_cards.map(func(card): return card["name"])
			var skill: Dictionary = GameContent.draw_skill_card(owned_names)
			stats.skill_cards.append(skill)
			_show_skill_gain(skill["name"])
	_update_status()

## 스탯 변화량("공격 +1" 등)을 해당 큰 스탯 표시 옆에 크게 띄웠다가 위로 떠오르며 사라지게 한다
func _show_stat_gain(stat_type: PlayerStats.StatType, amount: int) -> void:
	var anchor_label: Label = big_attack_label
	match stat_type:
		PlayerStats.StatType.DEFENSE: anchor_label = big_defense_label
		PlayerStats.StatType.MANA: anchor_label = big_mana_label

	_float_popup(anchor_label.position + Vector2(0.0, -44.0),
		"%s %+d" % [stats.stat_name(stat_type), amount],
		gain_color if amount > 0 else loss_color)

## 스킬카드 획득을 스킬카드 표시 옆에 크게 띄웠다가 위로 떠오르며 사라지게 한다
func _show_skill_gain(skill_name: String) -> void:
	_float_popup(big_skill_label.position + Vector2(0.0, -40.0), "%s 획득!" % skill_name, skill_color)

func _float_popup(start_pos: Vector2, text: String, color: Color) -> void:
	var popup := Label.new()
	popup.text = text
	popup.add_theme_color_override("font_color", color)
	popup.add_theme_font_size_override("font_size", popup_font_size)
	popup.position = start_pos
	$UI.add_child(popup)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", start_pos.y - popup_float_distance, popup_duration)
	tween.tween_property(popup, "modulate:a", 0.0, popup_duration)
	tween.chain().tween_callback(popup.queue_free)

func _update_status() -> void:
	status_label.text = "위치: %d칸 / 바퀴: %d" % [player.board_index, player.lap_count]
	stats_label.text = stats.summary()
	board_view.move_token(player.board_index)

	big_hp_label.text = "HP %d / %d" % [stats.hp, stats.max_hp]
	big_hp_bar.max_value = stats.max_hp
	big_hp_bar.value = stats.hp
	big_attack_label.text = "공격 %d" % stats.attack
	big_defense_label.text = "방어 %d" % stats.defense
	big_mana_label.text = "마력 %d / %d" % [stats.mana, stats.mana_max]
	big_skill_label.text = "스킬카드 %d장" % stats.skill_cards.size()
