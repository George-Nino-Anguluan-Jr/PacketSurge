# LessonData.gd
class_name LessonData
extends Resource

@export var lesson_id: String = ""
@export var title: String = ""
@export var category: String = ""
@export var icon_text: String = "[ ]"
@export var prerequisites: Array[String] = []

# Ordering within the Academy (0 = appended after ordered entries)
@export var order: int = 0

# Section shown in the Academy sidebar (e.g. "Python Basics")
@export var section: String = ""

# Progression: what mastering this lesson unlocks (previously the
# hardcoded PROGRESSION_CHAIN in ProgressManager.gd)
@export var unlocks_tower: String = ""  # e.g. "tower_array"
@export var unlocks_level: int = 0      # e.g. 1 (0 = no level)

# Visualization scene for Step 2
# Assign the matching .tscn file here per lesson
@export var visualization_scene: PackedScene = null

@export_multiline var concept_text: String = ""
@export_multiline var real_world_example: String = ""
@export_multiline var guided_example: String = ""
@export_multiline var recap_text: String = ""

@export var challenge_instruction: String = ""
@export var challenge_blocks: Array[String] = []
@export var correct_sequence: Array[String] = []
@export var challenge_hint: String = ""

# Code editor mode — if set, shows a coding editor instead of block puzzle
@export_multiline var challenge_code: String = ""
@export_multiline var code_template: String = ""
@export_multiline var expected_output: String = ""

@export var practice_question: String = ""
@export var practice_options: Array[String] = []
@export var practice_correct_index: int = 0
@export var practice_explanation: String = ""
