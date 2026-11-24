
extends Control

const BG := Color("#17283b")
const FLOOR := Color("#d9a66b")
const FLOOR_DARK := Color("#b77e4e")
const CREAM := Color("#fff4df")
const ORANGE := Color("#ff9d45")
const GREEN := Color("#65bd83")
const RED := Color("#e96b66")
const PANEL := Color("#263d54")

const ROUND_TIME := 120
const COOKING_TIME := 4.0
const CUSTOMER_PATIENCE := 30.0
const INGREDIENTS_REQUIRED := 3
const SAVE_PATH := "user://couple_chef.cfg"

var screen := "menu"
var game_mode := "Career"
var restaurant := "Burger Restaurant"

var score := 0
var coins := 0
var round_coins := 0
var best_score := 0
var ingredients := 0
var cooked_meals := 0
var customers_served := 0
var customers_lost := 0
var time_left := ROUND_TIME
var level := 1
var unlocked_level := 1

var game_running := false
var status_text := "Welcome to Couple Chef!"
var selected_language := "English"

var score_label: Label
var coins_label: Label
var timer_label: Label
var order_label: Label
var status_label: Label
var ingredient_label: Label
var meal_label: Label
var customers_label: Label

var game_timer: Timer
var cooking_timer: Timer
var cooking_seconds := 0.0
var cooking_active := false
var customer_patience := CUSTOMER_PATIENCE

var cooking_bar: ProgressBar
var patience_bar: ProgressBar
var cooking_status_label: Label


func _ready() -> void:
    get_viewport().size_changed.connect(queue_redraw)

    load_progress()

    game_timer = Timer.new()
    game_timer.wait_time = 1.0
    game_timer.timeout.connect(_on_timer)
    add_child(game_timer)

    cooking_timer = Timer.new()
    cooking_timer.wait_time = 0.1
    cooking_timer.timeout.connect(_on_cooking_tick)
    add_child(cooking_timer)

    show_menu()


func _draw() -> void:
    var size := get_viewport_rect().size
    draw_rect(Rect2(Vector2.ZERO, size), BG)

    if screen == "kitchen":
        draw_kitchen(size)
    else:
        draw_menu_background(size)


func draw_menu_background(size: Vector2) -> void:
    draw_rect(Rect2(0, size.y * 0.60, size.x, size.y * 0.40), FLOOR)

    for x in range(0, int(size.x), 110):
        draw_line(Vector2(x, size.y * 0.60), Vector2(x, size.y), FLOOR_DARK, 3)

    for y in range(int(size.y * 0.60), int(size.y), 65):
        draw_line(Vector2(0, y), Vector2(size.x, y), FLOOR_DARK, 2)

    draw_circle(Vector2(size.x * 0.15, size.y * 0.18), 48, Color("#38556d"))
    draw_circle(Vector2(size.x * 0.85, size.y * 0.18), 48, Color("#38556d"))
    draw_circle(Vector2(size.x * 0.15, size.y * 0.18), 31, Color("#f6c66b"))
    draw_circle(Vector2(size.x * 0.85, size.y * 0.18), 31, Color("#f6c66b"))


func draw_kitchen(size: Vector2) -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("#b9d7df"))
    draw_rect(Rect2(0, 0, size.x, size.y * 0.47), Color("#8bb6c5"))
    draw_rect(Rect2(0, size.y * 0.43, size.x, size.y * 0.08), Color("#f3d49c"))

    draw_rect(Rect2(0, size.y * 0.50, size.x, size.y * 0.50), FLOOR)

    for x in range(0, int(size.x), 100):
        draw_line(Vector2(x, size.y * 0.50), Vector2(x, size.y), FLOOR_DARK, 2)

    for y in range(int(size.y * 0.50), int(size.y), 65):
        draw_line(Vector2(0, y), Vector2(size.x, y), FLOOR_DARK, 2)

    draw_rect(Rect2(size.x * 0.08, size.y * 0.13, size.x * 0.22, 16), Color("#79533f"))
    draw_rect(Rect2(size.x * 0.70, size.y * 0.13, size.x * 0.22, 16), Color("#79533f"))

    for i in range(4):
        var jar_x: float = size.x * 0.11 + i * 62.0
        draw_rect(Rect2(jar_x, size.y * 0.07, 30, 55), Color("#f5e6c8"))
        draw_rect(Rect2(jar_x + 4, size.y * 0.03, 22, 9), ORANGE)

    draw_rect(Rect2(size.x * 0.12, size.y * 0.54, size.x * 0.76, size.y * 0.22), Color("#87583e"))
    draw_rect(Rect2(size.x * 0.12, size.y * 0.52, size.x * 0.76, size.y * 0.07), Color("#f1c58b"))

    var station_x := [0.25, 0.50, 0.75]

    for i in range(3):
        var x: float = size.x * float(station_x[i])
        draw_rect(Rect2(x - 65, size.y * 0.40, 130, 105), Color("#f6e6c9"))
        draw_rect(Rect2(x - 55, size.y * 0.43, 110, 65), Color("#4b6272"))
        draw_circle(Vector2(x, size.y * 0.47), 27, Color("#d7e3e5"))

    draw_circle(Vector2(size.x * 0.25, size.y * 0.47), 19, Color("#343c48"))
    draw_circle(Vector2(size.x * 0.25, size.y * 0.47), 13, Color("#e9ad54"))
    draw_circle(Vector2(size.x * 0.50, size.y * 0.47), 19, Color("#343c48"))
    draw_circle(Vector2(size.x * 0.50, size.y * 0.47), 13, Color("#b66a3c"))
    draw_circle(Vector2(size.x * 0.75, size.y * 0.47), 19, Color("#343c48"))
    draw_circle(Vector2(size.x * 0.75, size.y * 0.47), 13, Color("#78b96d"))

    draw_chef(Vector2(size.x * 0.39, size.y * 0.70), Color("#f4bd91"), Color("#e96b66"))
    draw_chef(Vector2(size.x * 0.61, size.y * 0.70), Color("#d99a6c"), Color("#5c91cf"))

    draw_circle(Vector2(size.x * 0.91, size.y * 0.40), 30, Color("#f2c29b"))
    draw_circle(Vector2(size.x * 0.91, size.y * 0.35), 31, Color("#5b463b"))
    draw_rect(Rect2(size.x * 0.87, size.y * 0.43, 75, 85), Color("#e7a45d"))
    draw_circle(Vector2(size.x * 0.90, size.y * 0.40), 3, Color("#302c2a"))
    draw_circle(Vector2(size.x * 0.93, size.y * 0.40), 3, Color("#302c2a"))


func draw_chef(pos: Vector2, skin: Color, clothes: Color) -> void:
    draw_circle(pos + Vector2(0, 24), 29, clothes)
    draw_circle(pos, 22, skin)
    draw_circle(pos + Vector2(-8, -3), 3, Color("#302c2a"))
    draw_circle(pos + Vector2(8, -3), 3, Color("#302c2a"))
    draw_arc(pos + Vector2(0, 4), 8, 0.2, 2.9, 12, Color("#8d5144"), 2)
    draw_rect(Rect2(pos.x - 20, pos.y - 28, 40, 8), CREAM)
    draw_circle(pos + Vector2(0, -30), 17, CREAM)
    draw_circle(pos + Vector2(-12, -25), 9, CREAM)
    draw_circle(pos + Vector2(12, -25), 9, CREAM)


func clear_screen() -> void:
    for child in get_children():
        if child != game_timer and child != cooking_timer:
            remove_child(child)
            child.queue_free()


func show_menu() -> void:
    game_timer.stop()
    cooking_timer.stop()
    cooking_active = false
    game_running = false
    screen = "menu"

    clear_screen()
    queue_redraw()

    var margin := make_margin()
    margin.add_theme_constant_override("margin_top", 28)
    margin.add_theme_constant_override("margin_bottom", 28)
    add_child(margin)

    var layout := VBoxContainer.new()
    layout.alignment = BoxContainer.ALIGNMENT_CENTER
    layout.add_theme_constant_override("separation", 13)
    margin.add_child(layout)

    var title := make_label("COUPLE CHEF", 52, CREAM)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(title)

    var subtitle := make_label("COOK TOGETHER. SERVE WITH LOVE.", 19, CREAM)
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(subtitle)

    var info := make_label("COINS: " + str(coins) + "     BEST SCORE: " + str(best_score), 18, CREAM)
    info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(info)

    var gap := Control.new()
    gap.custom_minimum_size.y = 35
    layout.add_child(gap)

    add_menu_button(layout, "CAREER MODE", show_restaurants, ORANGE)
    add_menu_button(layout, "CO-OP MODE", func(): start_game("Co-op"), GREEN)
    add_menu_button(layout, "VERSUS MODE", func(): start_game("Versus"), Color("#8d83d8"))
    add_menu_button(layout, "PRACTICE MODE", func(): start_game("Practice"), Color("#559bb9"))
    add_menu_button(layout, "SETTINGS / WIKA", show_settings, PANEL)

    var footer := make_label("Two chefs. One kitchen. Endless fun!", 17, CREAM)
    footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(footer)


func show_restaurants() -> void:
    screen = "restaurants"
    clear_screen()
    queue_redraw()

    var margin := make_margin()
    add_child(margin)

    var layout := VBoxContainer.new()
    layout.alignment = BoxContainer.ALIGNMENT_CENTER
    layout.add_theme_constant_override("separation", 12)
    margin.add_child(layout)

    var title := make_label("CHOOSE YOUR RESTAURANT", 30, CREAM)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(title)

    var progress := make_label("HIGHEST UNLOCKED LEVEL: " + str(unlocked_level), 18, GREEN)
    progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(progress)

    var burger := make_button("BURGER RESTAURANT  -  LEVELS 1-10", func(): show_levels("Burger Restaurant", 1, 10), ORANGE)
    layout.add_child(burger)

    var cafe := make_button("CAFE & BAKERY  -  LEVELS 11-20", func(): show_levels("Cafe & Bakery", 11, 20), Color("#b982c9"))
    cafe.disabled = unlocked_level < 11
    layout.add_child(cafe)

    var steakhouse := make_button("STEAKHOUSE  -  LEVELS 21-30", func(): show_levels("Steakhouse", 21, 30), RED)
    steakhouse.disabled = unlocked_level < 21
    layout.add_child(steakhouse)

    var seafood := make_button("SEAFOOD RESTAURANT  -  COMING SOON", func(): set_status("Coming in a future update."), PANEL)
    seafood.disabled = true
    layout.add_child(seafood)

    var diner := make_button("FAMILY DINER  -  COMING SOON", func(): set_status("Coming in a future update."), PANEL)
    diner.disabled = true
    layout.add_child(diner)

    add_menu_button(layout, "BACK", show_menu, PANEL)

func show_levels(restaurant_name: String, first_level: int, last_level: int) -> void:
    screen = "levels"
    clear_screen()
    queue_redraw()

    var margin := make_margin()
    add_child(margin)

    var layout := VBoxContainer.new()
    layout.alignment = BoxContainer.ALIGNMENT_CENTER
    layout.add_theme_constant_override("separation", 10)
    margin.add_child(layout)

    var title := make_label(restaurant_name.to_upper(), 30, CREAM)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(title)

    var progress := make_label("SELECT AN UNLOCKED LEVEL", 18, GREEN)
    progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(progress)

    for level_number in range(first_level, last_level + 1):
        var selected_level := level_number
        var level_button := make_button(
            "LEVEL " + str(selected_level),
            func(): start_career_level(restaurant_name, selected_level),
            ORANGE
        )

        level_button.disabled = selected_level > unlocked_level
        layout.add_child(level_button)

    add_menu_button(layout, "BACK", show_restaurants, PANEL)


func start_career_level(restaurant_name: String, selected_level: int) -> void:
    if selected_level > unlocked_level:
        return

    restaurant = restaurant_name
    level = selected_level
    start_game("Career")


func show_settings() -> void:
    screen = "settings"
    clear_screen()
    queue_redraw()

    var margin := make_margin()
    add_child(margin)

    var layout := VBoxContainer.new()
    layout.alignment = BoxContainer.ALIGNMENT_CENTER
    layout.add_theme_constant_override("separation", 18)
    margin.add_child(layout)

    var title := make_label("SETTINGS / MGA SETTING", 34, CREAM)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(title)

    add_menu_button(layout, "LANGUAGE: " + selected_language, toggle_language, PANEL)
    add_menu_button(layout, "MUSIC & SOUND", func(): set_status("Sound controls will be added in a future update."), PANEL)
    add_menu_button(layout, "BACK", show_menu, ORANGE)


func toggle_language() -> void:
    if selected_language == "English":
        selected_language = "Filipino"
    else:
        selected_language = "English"

    show_settings()


func start_game(mode: String) -> void:
    game_mode = mode
    score = 0
    round_coins = 0
    ingredients = 0
    cooked_meals = 0
    customers_served = 0
    customers_lost = 0
    time_left = ROUND_TIME

    cooking_seconds = 0.0
    cooking_active = false
    customer_patience = CUSTOMER_PATIENCE

    game_timer.stop()
    cooking_timer.stop()

    game_running = true
    status_text = "Prepare ingredients, cook food, then serve!"
    screen = "kitchen"

    build_kitchen_ui()
    game_timer.start()
    queue_redraw()


func build_kitchen_ui() -> void:
    clear_screen()

    var margin := make_margin()
    margin.add_theme_constant_override("margin_left", 28)
    margin.add_theme_constant_override("margin_right", 28)
    margin.add_theme_constant_override("margin_top", 15)
    margin.add_theme_constant_override("margin_bottom", 15)
    add_child(margin)

    var layout := VBoxContainer.new()
    layout.add_theme_constant_override("separation", 9)
    margin.add_child(layout)

    var top := HBoxContainer.new()
    layout.add_child(top)

    var heading := make_label(restaurant.to_upper(), 23, CREAM)
    heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(heading)

    score_label = make_label("SCORE: " + str(score), 19, CREAM)
    top.add_child(score_label)

    coins_label = make_label("COINS: " + str(coins), 19, CREAM)
    top.add_child(coins_label)

    timer_label = make_label("TIME: " + str(time_left), 19, CREAM)
    top.add_child(timer_label)

    order_label = make_label("CUSTOMER ORDER:  3 INGREDIENTS  >  COOK  >  SERVE", 19, Color("#25384c"))
    order_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(order_label)

    cooking_status_label = make_label("COOKING: WAITING", 18, CREAM)
    cooking_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(cooking_status_label)

    cooking_bar = ProgressBar.new()
    cooking_bar.max_value = COOKING_TIME
    cooking_bar.value = 0.0
    cooking_bar.custom_minimum_size = Vector2(0, 18)
    layout.add_child(cooking_bar)

    var patience_title := make_label("CUSTOMER PATIENCE", 16, CREAM)
    layout.add_child(patience_title)

    patience_bar = ProgressBar.new()
    patience_bar.max_value = CUSTOMER_PATIENCE
    patience_bar.value = CUSTOMER_PATIENCE
    patience_bar.custom_minimum_size = Vector2(0, 18)
    layout.add_child(patience_bar)

    var spacer := Control.new()
    spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
    layout.add_child(spacer)

    var stations := HBoxContainer.new()
    stations.add_theme_constant_override("separation", 14)
    layout.add_child(stations)

    add_station(stations, "PREP STATION", "CHOP INGREDIENTS", prepare_ingredients, GREEN)
    add_station(stations, "COOKING STATION", "COOK THE MEAL", cook_meal, ORANGE)
    add_station(stations, "SERVING COUNTER", "SERVE CUSTOMER", serve_meal, Color("#6e9ed0"))

    var stats := HBoxContainer.new()
    stats.add_theme_constant_override("separation", 25)
    layout.add_child(stats)

    ingredient_label = make_label("INGREDIENTS: 0 / 3", 18, CREAM)
    meal_label = make_label("READY MEALS: 0", 18, CREAM)
    customers_label = make_label("SERVED: 0", 18, CREAM)

    stats.add_child(ingredient_label)
    stats.add_child(meal_label)
    stats.add_child(customers_label)

    status_label = make_label(status_text, 19, CREAM)
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(status_label)

    add_menu_button(layout, "MAIN MENU", show_menu, PANEL)

    refresh_ui()


func add_station(parent: HBoxContainer, heading: String, action: String, callback: Callable, color: Color) -> void:
    var column := VBoxContainer.new()
    column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(column)

    var title := make_label(heading, 18, CREAM)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    column.add_child(title)

    var button := make_button(action, callback, color)
    button.custom_minimum_size = Vector2(0, 90)
    column.add_child(button)


func prepare_ingredients() -> void:
    if not game_running:
        return

    if ingredients >= INGREDIENTS_REQUIRED:
        status_text = "You have enough ingredients. Start cooking!"
        refresh_ui()
        return

    ingredients += 1
    status_text = "Ingredient prepared! Keep going."
    refresh_ui()


func cook_meal() -> void:
    if not game_running:
        return

    if cooking_active:
        status_text = "Your food is already cooking!"
        refresh_ui()
        return

    if ingredients < INGREDIENTS_REQUIRED:
        status_text = "You need 3 ingredients before cooking!"
        refresh_ui()
        return

    cooking_active = true
    cooking_seconds = 0.0
    cooking_bar.value = 0.0
    cooking_status_label.text = "COOKING: 0%"
    status_text = "Your meal is cooking! Please wait."

    cooking_timer.start()
    refresh_ui()


func serve_meal() -> void:
    if not game_running:
        return

    if cooked_meals < 1:
        status_text = "Cook a meal before serving!"
        refresh_ui()
        return

    cooked_meals -= 1
    score += 100
    coins += 10
    round_coins += 10
    customers_served += 1
    customer_patience = CUSTOMER_PATIENCE

    patience_bar.value = customer_patience

    status_text = "Customer served! +100 points and +10 coins!"

    save_progress()
    refresh_ui()


func refresh_ui() -> void:
    if score_label:
        score_label.text = "SCORE: " + str(score)

    if coins_label:
        coins_label.text = "COINS: " + str(coins)

    if timer_label:
        timer_label.text = "TIME: " + str(time_left)

    if ingredient_label:
        ingredient_label.text = "INGREDIENTS: " + str(ingredients) + " / 3"

    if meal_label:
        meal_label.text = "READY MEALS: " + str(cooked_meals)

    if customers_label:
        customers_label.text = "SERVED: " + str(customers_served)

    if status_label:
        status_label.text = status_text


func _on_cooking_tick() -> void:
    if not cooking_active:
        cooking_timer.stop()
        return

    cooking_seconds += 0.1
    cooking_bar.value = cooking_seconds

    var percentage := int((cooking_seconds / COOKING_TIME) * 100.0)
    cooking_status_label.text = "COOKING: " + str(percentage) + "%"

    if cooking_seconds >= COOKING_TIME:
        cooking_timer.stop()
        cooking_active = false
        ingredients -= INGREDIENTS_REQUIRED
        cooked_meals += 1

        cooking_bar.value = COOKING_TIME
        cooking_status_label.text = "COOKING COMPLETE!"
        status_text = "Delicious! Your meal is ready."

        refresh_ui()


func _on_timer() -> void:
    if not game_running:
        return

    time_left -= 1
    customer_patience -= 1

    if patience_bar:
        patience_bar.value = maxf(customer_patience, 0.0)

    if customer_patience <= 0:
        customers_lost += 1
        customer_patience = CUSTOMER_PATIENCE
        status_text = "Customer left! A new customer has arrived."

    refresh_ui()

    if time_left <= 0:
        finish_game()


func finish_game() -> void:
    game_running = false
    game_timer.stop()
    cooking_timer.stop()
    cooking_active = false

    if score > best_score:
        best_score = score

    if game_mode == "Career" and customers_served >= 5:
        unlocked_level = maxi(unlocked_level, level + 1)

    save_progress()

    status_text = "TIME UP! ROUND COMPLETE!"
    show_results()


func show_results() -> void:
    screen = "results"
    clear_screen()
    queue_redraw()

    var margin := make_margin()
    margin.add_theme_constant_override("margin_left", 45)
    margin.add_theme_constant_override("margin_right", 45)
    add_child(margin)

    var layout := VBoxContainer.new()
    layout.alignment = BoxContainer.ALIGNMENT_CENTER
    layout.add_theme_constant_override("separation", 14)
    margin.add_child(layout)

    var title := make_label("ROUND COMPLETE!", 42, CREAM)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(title)

    var restaurant_label := make_label(restaurant.to_upper() + "  |  LEVEL " + str(level) + "  |  " + game_mode.to_upper(), 20, CREAM)
    restaurant_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(restaurant_label)

    var gap := Control.new()
    gap.custom_minimum_size.y = 15
    layout.add_child(gap)

    add_result_line(layout, "FINAL SCORE", str(score))
    add_result_line(layout, "COINS EARNED", "+" + str(round_coins))
    add_result_line(layout, "TOTAL COINS", str(coins))
    add_result_line(layout, "CUSTOMERS SERVED", str(customers_served))
    add_result_line(layout, "CUSTOMERS LOST", str(customers_lost))
    add_result_line(layout, "BEST SCORE", str(best_score))

    var message := "Great work, Chef!"

    if game_mode == "Career" and customers_served >= 5:
        message = "Amazing! Level " + str(level + 1) + " unlocked!"
    elif game_mode == "Career":
        message = "Serve 5 customers to unlock the next level!"

    var message_label := make_label(message, 21, GREEN)
    message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(message_label)
    var button_gap := Control.new()
    button_gap.custom_minimum_size.y = 12
    layout.add_child(button_gap)

    add_menu_button(layout, "PLAY AGAIN", func(): start_game(game_mode), ORANGE)
    add_menu_button(layout, "MAIN MENU", show_menu, PANEL)


func add_result_line(parent: VBoxContainer, heading: String, value: String) -> void:
    var line := HBoxContainer.new()
    parent.add_child(line)

    var left := make_label(heading, 20, CREAM)
    left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    line.add_child(left)

    var right := make_label(value, 20, ORANGE)
    right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    line.add_child(right)

func load_progress() -> void:
    var config := ConfigFile.new()
    var error := config.load(SAVE_PATH)

    if error != OK:
        coins = 0
        best_score = 0
        unlocked_level = 1
        return

    coins = int(config.get_value("progress", "coins", 0))
    best_score = int(config.get_value("progress", "best_score", 0))
    unlocked_level = int(config.get_value("progress", "unlocked_level", 1))


func save_progress() -> void:
    var config := ConfigFile.new()

    config.set_value("progress", "coins", coins)
    config.set_value("progress", "best_score", best_score)
    config.set_value("progress", "unlocked_level", unlocked_level)

    config.save(SAVE_PATH)


func make_margin() -> MarginContainer:
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 65)
    margin.add_theme_constant_override("margin_right", 65)
    margin.add_theme_constant_override("margin_top", 25)
    margin.add_theme_constant_override("margin_bottom", 25)
    return margin


func make_label(value: String, font_size: int, color: Color) -> Label:
    var label := Label.new()
    label.text = value
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    return label


func make_button(value: String, callback: Callable, color: Color) -> Button:
    var button := Button.new()
    button.text = value
    button.custom_minimum_size = Vector2(0, 52)
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.add_theme_font_size_override("font_size", 19)
    button.add_theme_color_override("font_color", Color("#ffffff"))

    var normal := StyleBoxFlat.new()
    normal.bg_color = color
    normal.corner_radius_top_left = 14
    normal.corner_radius_top_right = 14
    normal.corner_radius_bottom_left = 14
    normal.corner_radius_bottom_right = 14
    normal.content_margin_left = 12
    normal.content_margin_right = 12
    normal.content_margin_top = 8
    normal.content_margin_bottom = 8

    button.add_theme_stylebox_override("normal", normal)

    var hover := normal.duplicate()
    hover.bg_color = color.lightened(0.13)
    button.add_theme_stylebox_override("hover", hover)

    var pressed_style := normal.duplicate()
    pressed_style.bg_color = color.darkened(0.15)
    button.add_theme_stylebox_override("pressed", pressed_style)

    button.pressed.connect(callback)
    return button


func add_menu_button(parent: VBoxContainer, value: String, callback: Callable, color: Color) -> void:
    var button := make_button(value, callback, color)
    button.custom_minimum_size = Vector2(0, 55)
    parent.add_child(button)


func set_status(message: String) -> void:
    status_text = message

    if status_label:
        status_label.text = message

