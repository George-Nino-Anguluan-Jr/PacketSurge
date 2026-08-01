# EnemyStyle.gd
# Shared visual style resource for enemies.
# Multiple EnemyData resources can reference the same EnemyStyle.
# Changing this .tres file updates all enemies that reference it.

class_name EnemyStyle
extends Resource

# ─── SHARED GEOMETRY ────────────────────────────────────
@export var squash_ratio: float = 0.65          # 3D camera perspective squash
@export var bob_amplitude: float = 2.0          # Bobbing animation amplitude
@export var bob_speed: float = 3.0               # Bobbing animation speed
@export var shadow_alpha: float = 0.25          # Drop shadow opacity
@export var shadow_scale: Vector2 = Vector2(1.0, 0.35)

# ─── HEALTH BAR ──────────────────────────────────────────
@export var health_bar_width: float = 36.0
@export var health_bar_height: float = 5.0
@export var health_bar_offset: Vector2 = Vector2(0, -32)
@export var health_bg_color: Color = Color("#1A0A0A")
@export var health_border_alpha: float = 0.3
@export var health_outline: Color = Color("#FFFFFF", 0.3)
@export var health_full_color: Color = Color("#00FF88")
@export var health_mid_color: Color = Color("#FFB800")
@export var health_low_color: Color = Color("#FF3366")

# ─── STATUS EFFECTS ──────────────────────────────────────
@export var dot_indicator_color: Color = Color("#1ABC9C", 0.8)  # Teal for DoT
@export var dot_indicator_size: float = 3.0
@export var shield_bar_color: Color = Color("#00D4FF")
@export var shield_bar_offset: float = -3.0
@export var shield_bar_height: float = 2.0

# ─── FLASH ───────────────────────────────────────────────
@export var flash_duration: float = 0.15
@export var flash_color: Color = Color.WHITE
