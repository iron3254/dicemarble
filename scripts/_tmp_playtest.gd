extends SceneTree

var main: Node
var shot_dir := "C:/Users/USER/AppData/Local/Temp/claude/D--WorkSpace02-dicemarble/3bcd88fe-f480-444e-be47-4367bc498de4/scratchpad/playtest/"
var shot_count := 0

func _init() -> void:
	var dir := DirAccess.open("C:/Users/USER/AppData/Local/Temp/claude/D--WorkSpace02-dicemarble/3bcd88fe-f480-444e-be47-4367bc498de4/scratchpad/")
	if dir and not dir.dir_exists("playtest"):
		dir.make_dir("playtest")

	var scene: PackedScene = load("res://scenes/main.tscn")
	main = scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	seed(1234)
	print(">>> 플레이 시작")
	await _shot("00_start")

	var turn := 0
	var last_battle_shot_turn := -1
	while main.win_label.text == "" and turn < 80:
		turn += 1
		var pos_before: int = main.player.board_index
		var lap_before: int = main.player.lap_count
		var hp_before: int = main.stats.hp

		main.take_turn()
		var entered_battle := false
		while main.roll_button.disabled:
			if main.stat_choice_view.visible:
				main.stat_choice_view._select(PlayerStats.ALL_STATS.pick_random())
			if main.battle_view.visible:
				if not entered_battle:
					entered_battle = true
				var buttons: Array = main.battle_view.action_container.get_children()
				if buttons.size() > 0:
					# 마력 있으면 스킬(마지막 버튼, 보통 위력 제일 센 것) 우선 시도, 없으면 기본
					buttons[buttons.size() - 1].pressed.emit()
			await process_frame

		print("턴 %2d | 위치 %2d→%2d (바퀴 %d→%d) | 공격%d 방어%d 마력%d/%d HP%d/%d 스킬%d장%s" % [
			turn, pos_before, main.player.board_index, lap_before, main.player.lap_count,
			main.stats.attack, main.stats.defense, main.stats.mana, main.stats.mana_max,
			main.stats.hp, main.stats.max_hp, main.stats.skill_cards.size(),
			" [전투 발생]" if entered_battle else ""
		])

		if entered_battle and turn - last_battle_shot_turn > 3:
			last_battle_shot_turn = turn
			await _shot("battle_turn%02d" % turn)

		if main.stats.hp <= 5 and hp_before > 5:
			await _shot("lowhp_turn%02d" % turn)

		if main.player.lap_count > lap_before:
			await _shot("lap%d_turn%02d" % [main.player.lap_count, turn])

	await _shot("99_end")
	print(">>> 최종 결과: %s (총 %d턴)" % [main.win_label.text, turn])
	quit()

func _shot(name: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_texture().get_image()
	img.save_png(shot_dir + name + ".png")
	shot_count += 1
