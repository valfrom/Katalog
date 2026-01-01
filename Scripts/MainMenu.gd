extends Control

const MENU_ITEMS := ["New Game", "Continue", "Options", "Exit"]

var selected_index: int = 0

@onready var menu_buttons: Array[Button] = [
        %NewGameButton,
        %ContinueButton,
        %OptionsButton,
        %ExitButton,
]
@onready var options_dialog: AcceptDialog = %OptionsDialog

func _ready():
        _update_continue_state()
        _update_menu_labels()
        for button in menu_buttons:
                button.pressed.connect(_on_button_pressed.bind(button))
        _focus_current()

func _unhandled_input(event: InputEvent) -> void:
        if event.is_action_pressed("ui_up"):
                _move_selection(-1)
                get_viewport().set_input_as_handled()
        elif event.is_action_pressed("ui_down"):
                _move_selection(1)
                get_viewport().set_input_as_handled()
        elif event.is_action_pressed("ui_left"):
                _move_selection(-1)
                get_viewport().set_input_as_handled()
        elif event.is_action_pressed("ui_right"):
                _move_selection(1)
                get_viewport().set_input_as_handled()
        elif event.is_action_pressed("ui_accept"):
                _activate_selection()
                get_viewport().set_input_as_handled()

func _move_selection(delta: int) -> void:
        if menu_buttons.is_empty():
                return
        var attempts := menu_buttons.size()
        while attempts > 0:
                selected_index = (selected_index + delta + menu_buttons.size()) % menu_buttons.size()
                attempts -= 1
                if !menu_buttons[selected_index].disabled:
                        break
        _update_menu_labels()
        _focus_current()

func _focus_current() -> void:
        if selected_index >= 0 and selected_index < menu_buttons.size():
                menu_buttons[selected_index].grab_focus()

func _update_menu_labels() -> void:
        _update_continue_state()
        for i in menu_buttons.size():
                var base_text := MENU_ITEMS[i]
                var button := menu_buttons[i]
                var arrowed_text := base_text
                if i == selected_index:
                        arrowed_text = "< %s >" % base_text
                button.text = arrowed_text
                button.modulate = Color.WHITE if !button.disabled else Color(1, 1, 1, 0.6)

func _update_continue_state() -> void:
        var has_save := GameManager.saved_scene_path != ""
        %ContinueButton.disabled = !has_save

func _activate_selection() -> void:
        match selected_index:
                0:
                        _start_new_game()
                1:
                        _continue_game()
                2:
                        _open_options()
                3:
                        get_tree().quit()

func _on_button_pressed(button: Button) -> void:
        var button_index := menu_buttons.find(button)
        if button_index != -1:
                selected_index = button_index
                _update_menu_labels()
                _activate_selection()

func _start_new_game() -> void:
        GameManager.score = 0
        GameManager.saved_scene_path = ""
        GameManager.pending_level_scene = ""
        GameManager.restore_player_position = false
        SceneTransition.load_scene("res://Scenes/Maps/Map_01.tscn")

func _continue_game() -> void:
        if GameManager.saved_scene_path == "":
                        return
        GameManager.mark_restore_player_position()
        SceneTransition.load_scene(GameManager.saved_scene_path)

func _open_options() -> void:
        options_dialog.popup_centered()
