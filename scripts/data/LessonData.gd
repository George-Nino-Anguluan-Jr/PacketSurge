# LessonData.gd
class_name LessonData
extends Resource

@export var lesson_id: String = ""
@export var title: String = ""
@export var category: String = ""
@export var icon_text: String = "[ ]"
@export var prerequisites: Array[String] = []

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

@export var practice_question: String = ""
@export var practice_options: Array[String] = []
@export var practice_correct_index: int = 0
@export var practice_explanation: String = ""
