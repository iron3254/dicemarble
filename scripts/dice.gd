class_name Dice
extends RefCounted

## 주사위를 굴려 1~6 사이의 눈금을 반환한다
static func roll() -> int:
	return randi_range(1, 6)
