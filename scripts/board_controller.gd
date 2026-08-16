extends Node2D

## 승리에 필요한 완주 바퀴 수
@export var win_laps: int = 3

var board_data: BoardData
var player: PlayerToken
var stats: PlayerStats

@onready var status_label: Label = $UI/StatusLabel
@onready var stats_label: Label = $UI/StatsLabel
@onready var log_label: Label = $UI/LogLabel
@onready var roll_button: Button = $UI/RollButton
@onready var board_view: BoardView = $BoardView
@onready var dice_view: DiceView = $DiceView
@onready var stat_choice_view: StatChoiceView = $UI/StatChoiceView
@onready var battle_view: BattleView = $UI/BattleView

func _ready() -> void:
	board_data = BoardData.new()
	player = PlayerToken.new()
	stats = PlayerStats.new()
	board_view.setup(board_data)
	roll_button.pressed.connect(take_turn)
	_update_status()

## 한 턴 진행: 주사위 애니메이션 → 이동 → 지나친 꼭짓점 처리 → 도착 칸 효과 → 승리 체크
func take_turn() -> void:
	roll_button.disabled = true
	var steps := Dice.roll()
	await dice_view.play_roll(steps)

	var passed_corners := player.move(steps, board_data)
	_log("주사위: %d" % steps)

	for corner_index in passed_corners:
		await _resolve_corner(corner_index)

	if not board_data.is_corner(player.board_index):
		_resolve_cell(board_data.get_cell_type(player.board_index), player.board_index)

	_update_status()

	if player.lap_count >= win_laps:
		_log("%d바퀴 완주! 승리!" % win_laps)
	else:
		roll_button.disabled = false

## 이동 경로에서 지나친 꼭짓점칸을 처리한다(출발칸이면 스탯 선택 후 보스 전투, 아니면 일반 전투)
func _resolve_corner(index: int) -> void:
	var cell_type := board_data.get_cell_type(index)
	var is_boss := cell_type == BoardData.CellType.START
	if is_boss:
		_log("출발칸 통과! 올릴 스탯을 선택하세요")
		var chosen: PlayerStats.StatType = await stat_choice_view.ask()
		stats.add_stat(chosen, 1)
		_log("%s +1 (출발 보너스)" % stats.stat_name(chosen))
		_update_status()

	_log("%d번 꼭짓점 통과 → %s 전투 발생" % [index, "보스" if is_boss else "일반"])
	var enemy := EnemyData.create_boss() if is_boss else EnemyData.create_normal(index)
	var won: bool = await battle_view.start_battle(stats, enemy)
	if won:
		var reward_stat: PlayerStats.StatType = PlayerStats.ALL_STATS.pick_random()
		stats.add_stat(reward_stat, 1)
		_log("전투 승리! %s +1" % stats.stat_name(reward_stat))
	_update_status()

## 도착한 칸의 종류에 따라 효과를 적용한다
func _resolve_cell(cell_type: BoardData.CellType, index: int) -> void:
	match cell_type:
		BoardData.CellType.STAT:
			var stat_type: PlayerStats.StatType = PlayerStats.ALL_STATS.pick_random()
			stats.add_stat(stat_type, 1)
			_log("%d번 스탯칸 도착 → %s +1" % [index, stats.stat_name(stat_type)])
		BoardData.CellType.EVENT:
			var card: Dictionary = GameContent.draw_event_card()
			stats.add_stat(card["stat"], card["amount"])
			_log("%d번 이벤트칸 도착 → %s (%s %+d)" % [index, card["name"], stats.stat_name(card["stat"]), card["amount"]])
		BoardData.CellType.RANDOM:
			var effect: Dictionary = GameContent.roll_random_effect()
			stats.add_stat(effect["stat"], effect["amount"])
			_log("%d번 랜덤칸 도착 → %s (%s %+d)" % [index, effect["name"], stats.stat_name(effect["stat"]), effect["amount"]])
		BoardData.CellType.SKILL:
			var skill: Dictionary = GameContent.draw_skill_card()
			stats.skill_cards.append(skill)
			_log("%d번 스킬칸 도착 → %s 획득" % [index, skill["name"]])
	_update_status()

func _update_status() -> void:
	status_label.text = "위치: %d칸 / 바퀴: %d" % [player.board_index, player.lap_count]
	stats_label.text = stats.summary()
	board_view.move_token(player.board_index)

func _log(message: String) -> void:
	log_label.text += message + "\n"
