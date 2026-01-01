extends Control

@onready var hero_grid: GridContainer = %HeroGrid
@onready var info_label: Label = %Info

func _ready() -> void:
        _build_hero_buttons()

func _build_hero_buttons() -> void:
        for child in hero_grid.get_children():
                child.queue_free()

        for hero in GameManager.HERO_ROSTER:
                var button := Button.new()
                button.toggle_mode = true
                button.text = hero.get("name", "Hero") if GameManager.unlocked_heroes.has(hero["id"]) else "?"
                button.disabled = !GameManager.unlocked_heroes.has(hero["id"])
                button.custom_minimum_size = Vector2(180, 120)
                button.focus_mode = Control.FOCUS_ALL
                if hero.has("color"):
                        button.modulate = hero["color"] if GameManager.unlocked_heroes.has(hero["id"]) else Color(0.8, 0.8, 0.8)
                button.pressed.connect(func():
                        _select_hero(hero["id"])
                )
                hero_grid.add_child(button)

        if info_label:
                info_label.text = "Unlocked: %d / %d" % [GameManager.unlocked_heroes.size(), GameManager.HERO_ROSTER.size()]

func _select_hero(hero_id: String) -> void:
        GameManager.prepare_hero_run(hero_id)
        var target_scene := GameManager.pending_level_scene
        if target_scene == "":
                target_scene = GameManager.saved_scene_path
        if target_scene == "":
                return
        SceneTransition.load_scene(target_scene)
