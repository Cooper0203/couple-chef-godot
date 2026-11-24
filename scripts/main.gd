
extends Control

var score: int = 0
var ingredients: int = 0
var cooked_meals: int = 0
var time_left: int = 90
var game_over: bool = false

var score_label: Label
var timer_label: Label
var ingredient_label: Label
var meal_label: Label
var status_label: Label
var prepare_button: Button
var cook_button: Button
var serve_button: Button
var game_timer: Timer


func _ready() -> void:
    build_game()
    start_timer()
    refresh_ui()


func build_game() -> void:
    var background = ColorRect.new()
    background.color = Color("#25334a")
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(background)

    var margin = MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 28)
    margin.add_theme_constant_override("margin_right", 28)
    margin.add_theme_constant_override("margin_top", 24)
    margin.add_theme_constant_override("margin_bottom", 24)
    add_child(margin)

    var layout = VBoxContainer.new()
    layout.add_theme_constant_override("separation", 14)
    margin.add_child(layout)

    var title = Label.new()
    title.text = "🍳 COUPLE CHEF"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 38)
    layout.add_child(title)

    var subtitle = Label.new()
    subtitle.text = "Work together and serve delicious meals!"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 20)
    layout.add_child(subtitle)

    var stats = HBoxContainer.new()
    stats.add_theme_constant_override("separation", 20)
    layout.add_child(stats)

    score_label = make_label("Score: 0")
    timer_label = make_label("Time: 90")
    stats.add_child(score_label)
    stats.add_child(timer_label)

    var kitchen_title = make_label("YOUR KITCHEN")
    kitchen_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(kitchen_title)

    var chefs = HBoxContainer.new()
    chefs.add_theme_constant_override("separation", 16)
    layout.add_child(chefs)

    var chef_one = make_button("👩 CHEF 1\nPREPARE INGREDIENTS")
    chef_one.pressed.connect(prepare_ingredients)
    chefs.add_child(chef_one)
    prepare_button = chef_one

    var chef_two = make_button("👨 CHEF 2\nCOOK MEALS")
    chef_two.pressed.connect(cook_meal)
    chefs.add_child(chef_two)
    cook_button = chef_two

    serve_button = make_button("🍽 SERVE CUSTOMER")
    serve_button.pressed.connect(serve_meal)
    layout.add_child(serve_button)

    ingredient_label = make_label("Ingredients: 0 / 3")
    meal_label = make_label("Cooked meals: 0")
    status_label = make_label("Order: Prepare 3 ingredients, cook, then serve!")

    ingredient_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    meal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    layout.add_child(ingredient_label)
    layout.add_child(meal_label)
    layout.add_child(status_label)


func make_label(value: String) -> Label:
    var label = Label.new()
    label.text = value
    label.add_theme_font_size_override("font_size", 23)
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    return label


func make_button(value: String) -> Button:
    var button = Button.new()
    button.text = value
    button.custom_minimum_size = Vector2(0, 110)
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.add_theme_font_size_override("font_size", 22)
    return button


func prepare_ingredients() -> void:
    if game_over:
        return

    ingredients += 1
    status_label.text = "Nice! Keep preparing ingredients."
    refresh_ui()


func cook_meal() -> void:
    if game_over:
        return

    if ingredients < 3:
        status_label.text = "You need 3 ingredients before cooking!"
        return

    ingredients -= 3
    cooked_meals += 1
    status_label.text = "Great teamwork! One meal is ready."
    refresh_ui()


func serve_meal() -> void:
    if game_over:
        return

    if cooked_meals < 1:
        status_label.text = "Cook a meal before serving!"
        return

    cooked_meals -= 1
    score += 100
    status_label.text = "Customer served! +100 points!"
    refresh_ui()


func refresh_ui() -> void:
    score_label.text = "Score: " + str(score)
    timer_label.text = "Time: " + str(time_left)
    ingredient_label.text = "Ingredients: " + str(ingredients) + " / 3"
    meal_label.text = "Cooked meals: " + str(cooked_meals)


func start_timer() -> void:
    game_timer = Timer.new()
    game_timer.wait_time = 1.0
    game_timer.timeout.connect(on_timer_timeout)
    add_child(game_timer)
    game_timer.start()


func on_timer_timeout() -> void:
    if game_over:
        return

    time_left -= 1
    refresh_ui()

    if time_left <= 0:
        game_over = true
        game_timer.stop()
        status_label.text = "TIME'S UP! Final score: " + str(score)
        prepare_button.disabled = true
        cook_button.disabled = true
        serve_button.disabled = true
