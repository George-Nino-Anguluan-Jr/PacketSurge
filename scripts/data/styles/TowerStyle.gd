# TowerStyle.gd
# Shared visual style resource for towers.
# Multiple TowerData resources can reference the same TowerStyle.
# Changing this .tres file updates all towers that reference it.

class_name TowerStyle
extends Resource

# ─── SHARED GEOMETRY ────────────────────────────────────
@export var base_height: float = 10.0          # Height of the 3D extrusion for base plates
@export var shadow_offset: Vector2 = Vector2(4, 6)       # Drop shadow offset
@export var shadow_scale: Vector2 = Vector2(1.0, 0.35)   # Squash ratio for shadows
@export var shadow_alpha: float = 0.3                     # Shadow opacity
@export var panel_dark: String = "#0D141C"                # Dark panel color (side faces)
@export var panel_mid: String = "#101720"                 # Mid panel color

# ─── OUTLINE & BLOOM ─────────────────────────────────────
@export var outline_width: float = 1.5
@export var outline_default: Color = Color.WHITE
@export var muzzle_offset: Vector2 = Vector2(0, -14)  # Base turret pivot offset

# ─── RECOIL & ANIMATION ──────────────────────────────────
@export var recoil_factor: float = 6.0           # Multiplier for recoil distance per type
@export var recoil_decay: float = 6.0            # Per-second decay rate
@export var shoot_flash_decay: float = 4.0       # Flash decay speed
@export var placement_scale_time: float = 0.35   # Placement tween duration
@export var upgrade_scale_time: float = 0.15     # Upgrade tween duration

# ─── RANGE VISUALIZATION ─────────────────────────────────
@export var range_circle_alpha: float = 0.06     # Translucent fill alpha when selected
@export var range_arc_alpha: float = 0.25        # Arc alpha when selected
@export var range_label_offset: float = 14.0     # Distance above range circle for label
