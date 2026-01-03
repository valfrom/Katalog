extends Control

const MENU_OPTIONS := [
	"New Game",
	"Continue",
	"Options",
	"Exit",
]

@onready var current_option_label: Label = $MenuContainer/CurrentOption
@onready var status_label: Label = $MenuContainer/Status

var _current_index := 0

func _ready() -> void:
	_update_selection()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Down") or event.is_action_pressed("ui_down"):
		_select_next()
	elif event.is_action_pressed("Up") or event.is_action_pressed("ui_up"):
		_select_previous()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("Jump"):
		_activate_current_option()
	elif event.is_action_pressed("Left") or event.is_action_pressed("ui_left"):
		_select_previous()
	elif event.is_action_pressed("Right") or event.is_action_pressed("ui_right"):
		_select_next()

func _select_next() -> void:
	_current_index = (_current_index + 1) % MENU_OPTIONS.size()
	_update_selection()

func _select_previous() -> void:
	_current_index = (_current_index - 1 + MENU_OPTIONS.size()) % MENU_OPTIONS.size()
	_update_selection()

func _update_selection() -> void:
	var option_text = MENU_OPTIONS[_current_index]
	current_option_label.text = "< %s >" % option_text
	status_label.text = "Use < > or Left / Right to choose and press confirm"

func _activate_current_option() -> void:
	match MENU_OPTIONS[_current_index]:
		"New Game":
			_start_new_game()
		"Continue":
			_continue_game()
		"Options":
			_show_options_placeholder()
		"Exit":
			get_tree().quit()

func _start_new_game() -> void:
	GameManager.start_new_game()
	GameManager.prepare_hero_run(GameManager.current_hero_id)
	var target_scene := GameManager.pending_level_scene
	if target_scene.is_empty():
		target_scene = "res://Scenes/Maps/Map_01.tscn"
	SceneTransition.load_scene(target_scene)

func _continue_game() -> void:
	var target_scene = GameManager.saved_scene_path
	if target_scene.is_empty():
		target_scene = "res://Scenes/Maps/Map_01.tscn"
	SceneTransition.load_scene(target_scene)

func _show_options_placeholder() -> void:
	status_label.text = "Options are coming soon"
