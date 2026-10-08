class_name Dice
extends RefCounted

## 번개 문양 면: 이 면이 나오면 숫자 값은 0이지만 적에게 뇌문 1을 부여한다(기획서 '문양 주사위')
const THUNDER_FACE := "번개"

## 주사위 종류별 면 목록
## - 기본 주사위: D4, D6, D12, D20
## - 면 개수보다 적은 수로 이루어진 주사위: D6_16(1과 6만 새겨진 6면체)
## - 문양 주사위: D6_THUNDER(두 면이 번개 문양)
const FACES := {
	"D4": [1, 2, 3, 4],
	"D6": [1, 2, 3, 4, 5, 6],
	"D12": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
	"D20": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20],
	"D6_16": [1, 6, 1, 6, 1, 6],
	"D6_THUNDER": [1, 2, 3, 4, THUNDER_FACE, THUNDER_FACE],
}

const DISPLAY_NAMES := {
	"D4": "D4",
	"D6": "D6",
	"D12": "D12",
	"D20": "D20",
	"D6_16": "1·6 주사위",
	"D6_THUNDER": "번개 주사위",
}

## 1~6 사이의 눈금을 반환한다(일반 6면체)
static func roll() -> int:
	return randi_range(1, 6)

## kind 종류의 주사위를 굴려 나온 면(숫자 또는 문양)을 반환한다
static func roll_face(kind: String) -> Variant:
	var faces: Array = FACES[kind]
	return faces.pick_random()

## 면의 숫자 값(문양 면은 0)
static func face_value(face: Variant) -> int:
	if face is int:
		return face
	return 0

static func is_thunder(face: Variant) -> bool:
	return face is String and face == THUNDER_FACE

## 3D 주사위는 1~6 정육면체만 있어서, 일반 D6만 3D로 굴리고 나머지는 숫자 굴림 연출로 보여준다
static func uses_3d(kind: String) -> bool:
	return kind == "D6"

static func display_name(kind: String) -> String:
	return DISPLAY_NAMES.get(kind, kind)
