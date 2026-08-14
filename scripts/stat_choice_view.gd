class_name StatChoiceView
extends Control

signal chosen(stat_type: PlayerStats.StatType)

@onready var attack_button: Button = $AttackButton
@onready var defense_button: Button = $DefenseButton
@onready var mana_button: Button = $ManaButton

func _ready() -> void:
	visible = false
	attack_button.pressed.connect(_select.bind(PlayerStats.StatType.ATTACK))
	defense_button.pressed.connect(_select.bind(PlayerStats.StatType.DEFENSE))
	mana_button.pressed.connect(_select.bind(PlayerStats.StatType.MANA))

func _select(stat_type: PlayerStats.StatType) -> void:
	visible = false
	chosen.emit(stat_type)

## 선택 버튼을 보여주고, 플레이어가 고를 때까지 기다렸다가 선택된 스탯을 반환한다
func ask() -> PlayerStats.StatType:
	visible = true
	return await chosen
