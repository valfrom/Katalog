extends Control

@onready var hero_grid: GridContainer = %HeroGrid
@onready var description_label: Label = %HeroDescription
@onready var start_button: Button = %StartButton

var button_group := ButtonGroup.new()
var selected_index := 0

func _ready() -> void:
    _populate_heroes()
    _select_first_available()

func _populate_heroes() -> void:
    var heroes := GameManager.get_heroes()
    for i in range(heroes.size()):
        var button := Button.new()
        button.toggle_mode = true
        button.button_group = button_group
        button.custom_minimum_size = Vector2(120, 120)
        button.focus_mode = Control.FOCUS_ALL
        var unlocked := GameManager.is_hero_unlocked(i)
        button.disabled = !unlocked
        var hero_data: Dictionary = heroes[i]
        button.text = hero_data["name"] if unlocked else "?"
        if unlocked && hero_data.has("color"):
            button.modulate = hero_data["color"]
        var index := i
        button.pressed.connect(func(): _on_hero_selected(index))
        hero_grid.add_child(button)

func _select_first_available() -> void:
    var heroes := GameManager.get_heroes()
    for i in range(heroes.size()):
        if GameManager.is_hero_unlocked(i):
            _on_hero_selected(i)
            return
    start_button.disabled = true
    description_label.text = "No heroes unlocked yet!"

func _on_hero_selected(index: int) -> void:
    selected_index = index
    var hero := GameManager.get_heroes()[index]
    if GameManager.is_hero_unlocked(index):
        description_label.text = "Lead %s into the fight." % hero["name"]
        start_button.disabled = false
    else:
        description_label.text = "Locked hero"
        start_button.disabled = true

func _on_StartButton_pressed() -> void:
    GameManager.prepare_run(selected_index)
    if GameManager.pending_level_path != "":
        SceneTransition.load_scene(GameManager.pending_level_path)
