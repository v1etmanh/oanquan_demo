extends Node
# GameEnums — Autoload singleton, exposes all enums globally

enum StoneType {
	NORMAL  = 0,
	GOLD    = 1,
	DARK    = 2,
	QUAN    = 3,
	SPIRIT  = 4,
}

enum Phase {
	WAITING,
	SPREADING,
	CAPTURE_CONFIRM,
	CAPTURING,
	EFFECT_TRIGGER,
	TURN_END,
	GAME_OVER,
}

enum Direction {
	CLOCKWISE         = 1,
	COUNTER_CLOCKWISE = -1,
}

enum BuffType {
	SCORE_MULTIPLIER,
	EXTRA_TURN,
	SHIELD,
	STONE_VISION,
}
