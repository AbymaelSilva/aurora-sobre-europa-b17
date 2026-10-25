extends RefCounted

const ENEMY_COUNT := 48
const SECTOR_COUNT := 16
const GROUP_SIZE := 4
const MAX_EFFECTIVE_ATTACKERS := 8
const SEED := 1945
const PASS_PERIOD := 50.0
const GROUP_STAGGER := 1.4

static func variant_for(index: int, seed_value: int = SEED) -> String:
	return "bf109g" if (index + seed_value) % 2 == 0 else "fw190a"
