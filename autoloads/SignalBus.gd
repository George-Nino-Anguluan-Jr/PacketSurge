# SignalBus.gd
# Global event bus — all systems communicate through here
extends Node

# ─── ACADEMY SIGNALS ───────────────────────────────────
signal lesson_started(lesson_id: String)
signal lesson_step_changed(step_index: int)
signal lesson_completed(lesson_id: String)
signal topic_mastered(topic_id: String)
signal topic_unlocked(topic_id: String)
signal code_challenge_submitted(challenge_id: String, passed: bool)

# ─── CAMPAIGN SIGNALS ──────────────────────────────────
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal enemy_reached_end(enemy_id: String)
signal enemy_defeated(enemy_id: String)
signal tower_placed(tower_id: String, grid_position: Vector2i)
signal tower_sold(tower_id: String)

# ─── MICRO CODING SIGNALS ──────────────────────────────
signal micro_coding_triggered(challenge_id: String)
signal micro_coding_completed(passed: bool)

# ─── ADAPTIVE AI SIGNALS ───────────────────────────────
signal difficulty_adjusted(new_level: String)
signal hint_requested(topic_id: String)

# ─── UI / NAVIGATION SIGNALS ───────────────────────────
signal scene_change_requested(scene_path: String)
signal hud_message_requested(message: String, duration: float)

# ─── PROGRESSION SIGNALS ───────────────────────────────
signal tower_unlocked(tower_id: String)
signal campaign_level_unlocked(level_number: int)
signal lesson_unlocked(lesson_id: String)
