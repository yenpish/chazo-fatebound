extends CanvasLayer

@onready var boss_bar_texture: TextureRect = $BossBarTexture
@onready var progress_bar: ProgressBar = $ProgressBar

const BOSS_BAR_FULL: Texture2D = preload("res://assets/sprites/hp-bar-full-boss.png")
const BOSS_BAR_HALF: Texture2D = preload("res://assets/sprites/hp-bar-half-boss.png")
const BOSS_BAR_EMPTY: Texture2D = preload("res://assets/sprites/hp-bar-empty-boss.png")


func _ready() -> void:
	visible = false


func show_boss_bar(_boss_name: String, current_hp: int, max_hp: int) -> void:
	visible = true

	progress_bar.max_value = max_hp
	progress_bar.value = current_hp

	update_boss_hp(current_hp, max_hp)


func update_boss_hp(current_hp: int, max_hp: int) -> void:
	progress_bar.max_value = max_hp
	progress_bar.value = current_hp

	var hp_ratio: float = float(current_hp) / float(max_hp)

	if current_hp <= 0:
		boss_bar_texture.texture = BOSS_BAR_EMPTY
	elif hp_ratio <= 0.5:
		boss_bar_texture.texture = BOSS_BAR_HALF
	else:
		boss_bar_texture.texture = BOSS_BAR_FULL


func hide_boss_bar() -> void:
	visible = false
