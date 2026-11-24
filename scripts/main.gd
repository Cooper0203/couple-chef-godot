extends Control
# Couple Chef - consolidated Godot 4 main.gd
# Replace the entire contents of scripts/main.gd with this file.

const SAVE_PATH := "user://couple_chef.cfg"
const PORT := 24567
const MAX_CLIENTS := 1
const ROUND_TIME := 120
const PRACTICE_TIME := 180
const CUSTOMER_PATIENCE := 30.0
const BG := Color("#17283b")
const CREAM := Color("#fff4df")
const ORANGE := Color("#ff9d45")
const GREEN := Color("#65bd83")
const RED := Color("#e96b66")
const PANEL := Color("#263d54")
const OUTFIT_COLORS := [
    Color("#e96b66"), Color("#559bb9"), Color("#65bd83"),
    Color("#8d83d8"), Color("#ff9d45"), Color("#e78db5")
]
const OUTFIT_NAMES := ["RED", "BLUE", "GREEN", "PURPLE", "ORANGE", "PINK"]

var screen := "menu"
var game_mode := "Career"
var restaurant := "Burger Restaurant"
var level := 1
var unlocked_level := 1

var coins := 0
var best_score := 0
var score := 0
var round_coins := 0
var customers_served := 0
var customers_lost := 0
var ingredients := 0
var cooked_meals := 0
var current_order_name := "Classic Burger"
var current_ingredients_required := 3
var current_combo := 0
var best_combo := 0
var career_bonus_earned := 0

var game_running := false
var game_paused := false
var time_left := ROUND_TIME
var customer_patience := CUSTOMER_PATIENCE
var cooking_seconds := 0.0
var cooking_active := false
var patience_upgrade := 0
var total_rounds_played := 0
var achievements: Array[String] = []
var last_daily_reward := ""
var chef1_outfit_index := 0
var chef2_outfit_index := 1
var selected_language := "English"

var is_network_game := false
var is_host := false
var host_ip := "127.0.0.1"
var network_status := "Not connected"
var lobby_status_label: Label
var ip_input: LineEdit

var game_timer: Timer
var cooking_timer: Timer
var status_text := "Welcome to Couple Chef!"
var status_label: Label
var score_label: Label
var coins_label: Label
var timer_label: Label
var order_label: Label
var ingredient_label: Label
var meal_label: Label
var customers_label: Label
var combo_label: Label
var patience_bar: ProgressBar
var cooking_bar: ProgressBar

func _ready() -> void:
    randomize()
    load_progress()
    game_timer = Timer.new()
    game_timer.wait_time = 1.0
    game_timer.timeout.connect(_on_game_tick)
    add_child(game_timer)
    cooking_timer = Timer.new()
    cooking_timer.wait_time = 0.1
    cooking_timer.timeout.connect(_on_cooking_tick)
    add_child(cooking_timer)
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    multiplayer.connected_to_server.connect(_on_connected_to_server)
    multiplayer.connection_failed.connect(_on_connection_failed)
    multiplayer.server_disconnected.connect(_on_server_disconnected)
    show_menu()

func _draw() -> void:
    var size := get_viewport_rect().size
    draw_rect(Rect2(Vector2.ZERO, size), BG)
    if screen == "kitchen":
        draw_rect(Rect2(0, size.y * 0.48, size.x, size.y * 0.52), Color("#d9a66b"))
        draw_rect(Rect2(size.x * 0.12, size.y * 0.48, size.x * 0.76, size.y * 0.20), Color("#87583e"))
        for i in range(3):
            var x := size.x * (0.25 + 0.25 * i)
            draw_rect(Rect2(x - 55, size.y * 0.35, 110, 100), Color("#f6e6c9"))
            draw_circle(Vector2(x, size.y * 0.40), 23, Color("#d7e3e5"))
        draw_chef(Vector2(size.x * 0.40, size.y * 0.75), OUTFIT_COLORS[chef1_outfit_index])
        draw_chef(Vector2(size.x * 0.60, size.y * 0.75), OUTFIT_COLORS[chef2_outfit_index])
    else:
        draw_rect(Rect2(0, size.y * 0.62, size.x, size.y * 0.38), Color("#d9a66b"))
        for x in range(0, int(size.x), 100):
            draw_line(Vector2(x, size.y * 0.62), Vector2(x, size.y), Color("#b77e4e"), 2)

func draw_chef(pos: Vector2, clothes: Color) -> void:
    draw_circle(pos + Vector2(0, 24), 28, clothes)
    draw_circle(pos, 22, Color("#f4bd91"))
    draw_circle(pos + Vector2(-8, -3), 3, Color("#302c2a"))
    draw_circle(pos + Vector2(8, -3), 3, Color("#302c2a"))
    draw_rect(Rect2(pos.x - 20, pos.y - 28, 40, 8), CREAM)
    draw_circle(pos + Vector2(0, -30), 17, CREAM)

func clear_screen() -> void:
    for child in get_children():
        if child != game_timer and child != cooking_timer:
            remove_child(child)
            child.queue_free()

func make_margin() -> MarginContainer:
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 22)
    margin.add_theme_constant_override("margin_right", 22)
    margin.add_theme_constant_override("margin_top", 18)
    margin.add_theme_constant_override("margin_bottom", 18)
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    return margin

func make_label(value: String, font_size: int = 20, color: Color = CREAM) -> Label:
    var label := Label.new()
    label.text = value
    label.add_theme_font_size_override("font_size", font_size)
    label.add_theme_color_override("font_color", color)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return label

func make_button(value: String, callback: Callable, color: Color = ORANGE) -> Button:
    var button := Button.new()
    button.text = value
    button.custom_minimum_size = Vector2(0, 52)
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.add_theme_font_size_override("font_size", 18)
    var normal := StyleBoxFlat.new()
    normal.bg_color = color
    normal.corner_radius_top_left = 12
    normal.corner_radius_top_right = 12
    normal.corner_radius_bottom_left = 12
    normal.corner_radius_bottom_right = 12
    normal.content_margin_left = 10
    normal.content_margin_right = 10
    button.add_theme_stylebox_override("normal", normal)
    var hover := normal.duplicate()
    hover.bg_color = color.lightened(0.12)
    button.add_theme_stylebox_override("hover", hover)
    button.pressed.connect(callback)
    return button

func add_button(parent: VBoxContainer, value: String, callback: Callable, color: Color = ORANGE) -> Button:
    var button := make_button(value, callback, color)
    parent.add_child(button)
    return button

func make_layout(title_text: String, title_size: int = 32) -> VBoxContainer:
    clear_screen()
    var margin := make_margin()
    add_child(margin)
    var layout := VBoxContainer.new()
    layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
    layout.alignment = BoxContainer.ALIGNMENT_CENTER
    layout.add_theme_constant_override("separation", 10)
    margin.add_child(layout)
    var title := make_label(title_text, title_size)
    layout.add_child(title)
    return layout

func show_menu() -> void:
    disconnect_network()
    game_timer.stop()
    cooking_timer.stop()
    game_running = false
    game_paused = false
    is_network_game = false
    is_host = false
    screen = "menu"
    queue_redraw()
    var layout := make_layout("COUPLE CHEF", 42)
    layout.add_child(make_label("COOK TOGETHER. SERVE WITH LOVE.", 16))
    layout.add_child(make_label("COINS: %d     BEST SCORE: %d" % [coins, best_score], 17, GREEN))
    add_button(layout, "CAREER MODE", show_restaurants)
    add_button(layout, "LOCAL CO-OP", func(): start_game("Co-op"), GREEN)
    add_button(layout, "VERSUS MODE", func(): start_game("Versus"), Color("#8d83d8"))
    add_button(layout, "PRACTICE MODE", func(): start_game("Practice"), Color("#559bb9"))
    add_button(layout, "ONLINE / LAN MULTIPLAYER", show_multiplayer, GREEN)
    add_button(layout, "UPGRADES SHOP", show_shop, PANEL)
    add_button(layout, "ACHIEVEMENTS", show_achievements, PANEL)
    add_button(layout, "DAILY REWARD", claim_daily_reward, ORANGE)
    add_button(layout, "SETTINGS", show_settings, PANEL)

func show_restaurants() -> void:
    screen = "restaurants"
    var layout := make_layout("CHOOSE RESTAURANT")
    layout.add_child(make_label("Highest unlocked level: %d" % unlocked_level, 17, GREEN))
    add_button(layout, "BURGER RESTAURANT - LEVELS 1-10", func(): show_levels("Burger Restaurant", 1, 10))
    var cafe := make_button("CAFE & BAKERY - LEVELS 11-20", func(): show_levels("Cafe & Bakery", 11, 20), Color("#b982c9"))
    cafe.disabled = unlocked_level < 11
    layout.add_child(cafe)
    var steak := make_button("STEAKHOUSE - LEVELS 21-30", func(): show_levels("Steakhouse", 21, 30), RED)
    steak.disabled = unlocked_level < 21
    layout.add_child(steak)
    add_button(layout, "BACK", show_menu, PANEL)

func show_levels(restaurant_name: String, first_level: int, last_level: int) -> void:
    screen = "levels"
    restaurant = restaurant_name
    var layout := make_layout(restaurant_name.to_upper())
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    layout.add_child(scroll)
    var list := VBoxContainer.new()
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(list)
    for n in range(first_level, last_level + 1):
        var selected := n
        var b := make_button("LEVEL %d%s" % [selected, " - LOCKED" if selected > unlocked_level else " - PLAY"], func(): start_career_level(selected))
        b.disabled = selected > unlocked_level
        list.add_child(b)
    add_button(layout, "BACK", show_restaurants, PANEL)

func start_career_level(selected_level: int) -> void:
    if selected_level > unlocked_level:
        return
    level = selected_level
    start_game("Career")

func show_settings() -> void:
    screen = "settings"
    var layout := make_layout("SETTINGS")
    add_button(layout, "CHEF 1 OUTFIT: " + OUTFIT_NAMES[chef1_outfit_index], cycle_chef1_outfit)
    add_button(layout, "CHEF 2 OUTFIT: " + OUTFIT_NAMES[chef2_outfit_index], cycle_chef2_outfit, Color("#559bb9"))
    add_button(layout, "LANGUAGE: " + selected_language, toggle_language, PANEL)
    add_button(layout, "BACK", show_menu, PANEL)

func cycle_chef1_outfit() -> void:
    chef1_outfit_index = (chef1_outfit_index + 1) % OUTFIT_COLORS.size()
    save_progress()
    show_settings()

func cycle_chef2_outfit() -> void:
    chef2_outfit_index = (chef2_outfit_index + 1) % OUTFIT_COLORS.size()
    save_progress()
    show_settings()

func toggle_language() -> void:
    selected_language = "Filipino" if selected_language == "English" else "English"
    save_progress()
    show_settings()

func show_shop() -> void:
    screen = "shop"
    var layout := make_layout("UPGRADES SHOP")
    layout.add_child(make_label("Coins: %d" % coins, 18, GREEN))
    layout.add_child(make_label("Customer patience upgrade: level %d" % patience_upgrade, 16))
    var cost := 50 + patience_upgrade * 50
    var buy := make_button("BUY +2 SECONDS PATIENCE - %d COINS" % cost, func():
        if coins >= cost:
            coins -= cost
            patience_upgrade += 1
            save_progress()
            show_shop()
        else:
            set_status("Not enough coins.")
    )
    buy.disabled = coins < cost
    layout.add_child(buy)
    add_button(layout, "BACK", show_menu, PANEL)

func show_achievements() -> void:
    screen = "achievements"
    var layout := make_layout("ACHIEVEMENTS")
    var names := ["First Service", "Combo Master", "Five-Star Chef", "Career Expert", "Dedicated Chef"]
    for achievement in names:
        var mark := "✓ " if achievements.has(achievement) else "○ "
        layout.add_child(make_label(mark + achievement, 18, GREEN if achievements.has(achievement) else CREAM))
    add_button(layout, "BACK", show_menu, PANEL)

func claim_daily_reward() -> void:
    var today := Time.get_date_string_from_system()
    if last_daily_reward == today:
        status_text = "Daily reward already claimed today."
    else:
        coins += 25
        last_daily_reward = today
        status_text = "Daily reward claimed: +25 coins!"
        save_progress()
    show_menu()

func show_multiplayer() -> void:
    screen = "multiplayer"
    var layout := make_layout("ONLINE / LAN CO-OP")
    layout.add_child(make_label("Both players must use the same Wi-Fi network.", 15))
    ip_input = LineEdit.new()
    ip_input.placeholder_text = "Host IP address (example: 192.168.1.10)"
    ip_input.text = host_ip
    layout.add_child(ip_input)
    lobby_status_label = make_label(network_status, 16, GREEN)
    layout.add_child(lobby_status_label)
    add_button(layout, "HOST GAME", host_lan_game, GREEN)
    add_button(layout, "JOIN GAME", join_lan_game, Color("#559bb9"))
    add_button(layout, "START CO-OP MATCH (HOST)", start_host_match, ORANGE)
    add_button(layout, "DISCONNECT", disconnect_network, RED)
    add_button(layout, "BACK", show_menu, PANEL)

func update_lobby(message: String) -> void:
    network_status = message
    if is_instance_valid(lobby_status_label):
        lobby_status_label.text = message

func host_lan_game() -> void:
    disconnect_network()
    var peer := ENetMultiplayerPeer.new()
    var result := peer.create_server(PORT, MAX_CLIENTS)
    if result != OK:
        update_lobby("Could not host. Error: %s" % error_string(result))
        return
    multiplayer.multiplayer_peer = peer
    is_network_game = true
    is_host = true
    update_lobby("Hosting. Give your partner your local IP address and wait for them to join.")

func join_lan_game() -> void:
    host_ip = ip_input.text.strip_edges() if is_instance_valid(ip_input) else host_ip
    if host_ip.is_empty():
        update_lobby("Enter the host's local IP address.")
        return
    disconnect_network()
    var peer := ENetMultiplayerPeer.new()
    var result := peer.create_client(host_ip, PORT)
    if result != OK:
        update_lobby("Could not connect: %s" % error_string(result))
        return
    multiplayer.multiplayer_peer = peer
    is_network_game = true
    is_host = false
    update_lobby("Connecting to host...")

func start_host_match() -> void:
    if not is_network_game or not is_host:
        update_lobby("Only the host can start the online match.")
        return
    if multiplayer.get_peers().is_empty():
        update_lobby("Waiting for your partner to join before starting.")
        return
    start_game("Co-op")

func disconnect_network() -> void:
    if multiplayer.multiplayer_peer != null:
        multiplayer.multiplayer_peer.close()
        multiplayer.multiplayer_peer = null
    is_network_game = false
    is_host = false
    network_status = "Not connected"

func _on_peer_connected(peer_id: int) -> void:
    if is_host:
        update_lobby("Player connected. Host can start the match.")

func _on_peer_disconnected(peer_id: int) -> void:
    update_lobby("Other player disconnected.")

func _on_connected_to_server() -> void:
    update_lobby("Connected! Waiting for the host to start.")

func _on_connection_failed() -> void:
    disconnect_network()
    update_lobby("Connection failed. Check Wi-Fi and host IP.")

func _on_server_disconnected() -> void:
    disconnect_network()
    if screen == "kitchen":
        show_menu()
    else:
        update_lobby("Host disconnected.")

func generate_customer_order() -> void:
    var choice := randi_range(0, 2)
    if choice == 0:
        current_order_name = "Classic Burger"
        current_ingredients_required = 3
    elif choice == 1:
        current_order_name = "Cheese Burger"
        current_ingredients_required = 4
    else:
        current_order_name = "Double Burger"
        current_ingredients_required = 5

func start_game(mode: String) -> void:
    if is_network_game and not is_host:
        return
    game_mode = mode
    score = 0
    round_coins = 0
    career_bonus_earned = 0
    current_combo = 0
    best_combo = 0
    ingredients = 0
    cooked_meals = 0
    customers_served = 0
    customers_lost = 0
    generate_customer_order()
    time_left = PRACTICE_TIME if mode == "Practice" else ROUND_TIME
    customer_patience = CUSTOMER_PATIENCE + float(patience_upgrade * 2)
    if mode == "Career":
        customer_patience = maxf(15.0, customer_patience - float(level - 1) * 0.5)
    cooking_seconds = 0.0
    cooking_active = false
    game_paused = false
    game_running = true
    screen = "kitchen"
    build_kitchen_ui()
    game_timer.start()
    if is_network_game and is_host:
        rpc("remote_start_game", mode)
        broadcast_game_state()

@rpc("authority", "call_remote", "reliable")
func remote_start_game(mode: String) -> void:
    var was_network := is_network_game
    is_network_game = false
    is_host = false
    start_game(mode)
    is_network_game = was_network
    is_host = false

func build_kitchen_ui() -> void:
    screen = "kitchen"
    clear_screen()
    queue_redraw()
    var margin := make_margin()
    add_child(margin)
    var layout := VBoxContainer.new()
    layout.add_theme_constant_override("separation", 6)
    margin.add_child(layout)
    var heading := make_label("COUPLE CHEF - " + game_mode.to_upper(), 23)
    layout.add_child(heading)
    score_label = make_label("", 17, GREEN)
    coins_label = make_label("", 16)
    timer_label = make_label("", 18, ORANGE)
    order_label = make_label("", 18)
    ingredient_label = make_label("", 16)
    meal_label = make_label("", 16)
    customers_label = make_label("", 16)
    combo_label = make_label("", 16)
    for label in [score_label, coins_label, timer_label, order_label, ingredient_label, meal_label, customers_label, combo_label]:
        layout.add_child(label)
    patience_bar = ProgressBar.new()
    patience_bar.max_value = CUSTOMER_PATIENCE + float(patience_upgrade * 2)
    layout.add_child(patience_bar)
    cooking_bar = ProgressBar.new()
    cooking_bar.max_value = 4.0
    layout.add_child(cooking_bar)
    var stations := HBoxContainer.new()
    stations.add_theme_constant_override("separation", 6)
    layout.add_child(stations)
    var prepare := make_button("PREPARE", prepare_ingredients, GREEN)
    stations.add_child(prepare)
    var cook := make_button("COOK", cook_meal, ORANGE)
    stations.add_child(cook)
    var serve := make_button("SERVE", serve_meal, Color("#559bb9"))
    stations.add_child(serve)
    status_label = make_label(status_text, 15)
    layout.add_child(status_label)
    var pause := make_button("PAUSE / RESUME", toggle_pause, PANEL)
    layout.add_child(pause)
    add_button(layout, "MAIN MENU", show_menu, RED)
    refresh_ui()

func prepare_ingredients() -> void:
    if not game_running or game_paused:
        return
    if is_network_game and not is_host:
        rpc_id(1, "request_player_action", "prepare")
        return
    ingredients = mini(ingredients + 1, current_ingredients_required)
    status_text = "Ingredients: %d / %d" % [ingredients, current_ingredients_required]
    refresh_ui()
    broadcast_game_state()

func cook_meal() -> void:
    if not game_running or game_paused or cooking_active:
        return
    if is_network_game and not is_host:
        rpc_id(1, "request_player_action", "cook")
        return
    if ingredients < current_ingredients_required:
        status_text = "Prepare all ingredients first!"
        refresh_ui()
        return
    if cooked_meals >= 1:
        status_text = "Meal is already ready. Serve it!"
        refresh_ui()
        return
    cooking_active = true
    cooking_seconds = 0.0
    cooking_timer.start()
    status_text = "Cooking..."
    refresh_ui()
    broadcast_game_state()

func serve_meal() -> void:
    if not game_running or game_paused:
        return
    if is_network_game and not is_host:
        rpc_id(1, "request_player_action", "serve")
        return
    if cooked_meals < 1:
        status_text = "Cook the meal before serving!"
        refresh_ui()
        return
    score += 10
    coins += 5
    round_coins += 5
    customers_served += 1
    current_combo += 1
    best_combo = maxi(best_combo, current_combo)
    if current_combo == 3:
        coins += 5
        round_coins += 5
    if current_combo == 5:
        coins += 10
        round_coins += 10
    ingredients = 0
    cooked_meals = 0
    customer_patience = CUSTOMER_PATIENCE + float(patience_upgrade * 2)
    generate_customer_order()
    status_text = "Order served! Great teamwork!"
    check_achievements()
    refresh_ui()
    broadcast_game_state()

@rpc("any_peer", "call_remote", "reliable")
func request_player_action(action: String) -> void:
    if not is_host or not game_running or game_paused:
        return
    match action:
        "prepare":
            prepare_ingredients()
        "cook":
            cook_meal()
        "serve":
            serve_meal()

func _on_cooking_tick() -> void:
    if not game_running or game_paused:
        return
    if is_network_game and not is_host:
        return
    if not cooking_active:
        cooking_timer.stop()
        return
    cooking_seconds += 0.1
    if cooking_seconds >= 4.0:
        cooking_active = false
        cooking_timer.stop()
        cooked_meals = 1
        status_text = "Meal ready! Serve it!"
    refresh_ui()
    broadcast_game_state()

func _on_game_tick() -> void:
    if not game_running or game_paused:
        return
    if is_network_game and not is_host:
        return
    time_left -= 1
    customer_patience -= 1.0
    if customer_patience <= 0.0:
        customers_lost += 1
        current_combo = 0
        ingredients = 0
        cooked_meals = 0
        cooking_active = false
        cooking_timer.stop()
        generate_customer_order()
        customer_patience = CUSTOMER_PATIENCE + float(patience_upgrade * 2)
        status_text = "Customer left. Next order!"
    if time_left <= 0:
        finish_game()
    else:
        refresh_ui()
        broadcast_game_state()

func toggle_pause() -> void:
    if not game_running:
        return
    if is_network_game and not is_host:
        rpc_id(1, "request_pause")
        return
    game_paused = not game_paused
    if game_paused:
        game_timer.stop()
        cooking_timer.stop()
        status_text = "Game paused."
    else:
        game_timer.start()
        if cooking_active:
            cooking_timer.start()
        status_text = "Game resumed."
    refresh_ui()
    broadcast_game_state()

@rpc("any_peer", "call_remote", "reliable")
func request_pause() -> void:
    if is_host:
        toggle_pause()

func refresh_ui() -> void:
    if is_instance_valid(score_label):
        score_label.text = "SCORE: %d" % score
        coins_label.text = "COINS: %d (+%d THIS ROUND)" % [coins, round_coins]
        timer_label.text = "TIME: %d" % time_left
        order_label.text = "ORDER: %s - %d ingredients" % [current_order_name, current_ingredients_required]
        ingredient_label.text = "INGREDIENTS: %d / %d" % [ingredients, current_ingredients_required]
        meal_label.text = "READY MEALS: %d" % cooked_meals
        customers_label.text = "SERVED: %d    LOST: %d" % [customers_served, customers_lost]
        combo_label.text = "COMBO: %d    BEST: %d" % [current_combo, best_combo]
        patience_bar.value = maxf(customer_patience, 0.0)
        cooking_bar.value = cooking_seconds
        status_label.text = status_text

func broadcast_game_state() -> void:
    if not is_network_game or not is_host:
        return
    rpc("receive_game_state", score, coins, round_coins, ingredients, cooked_meals,
        current_order_name, current_ingredients_required, customers_served, customers_lost,
        time_left, customer_patience, current_combo, best_combo, cooking_active,
        cooking_seconds, status_text, game_paused)

@rpc("authority", "call_remote", "reliable")
func receive_game_state(new_score: int, new_coins: int, new_round_coins: int,
        new_ingredients: int, new_meals: int, new_order: String, new_required: int,
        new_served: int, new_lost: int, new_time: int, new_patience: float,
        new_combo: int, new_best_combo: int, new_cooking: bool,
        new_cooking_seconds: float, new_status: String, new_paused: bool) -> void:
    score = new_score
    coins = new_coins
    round_coins = new_round_coins
    ingredients = new_ingredients
    cooked_meals = new_meals
    current_order_name = new_order
    current_ingredients_required = new_required
    customers_served = new_served
    customers_lost = new_lost
    time_left = new_time
    customer_patience = new_patience
    current_combo = new_combo
    best_combo = new_best_combo
    cooking_active = new_cooking
    cooking_seconds = new_cooking_seconds
    status_text = new_status
    game_paused = new_paused
    if game_paused:
        game_timer.stop()
        cooking_timer.stop()
    else:
        if game_running and not game_timer.time_left > 0.0:
            game_timer.start()
        if cooking_active and not cooking_timer.time_left > 0.0:
            cooking_timer.start()
        elif not cooking_active:
            cooking_timer.stop()
    refresh_ui()

func check_achievements() -> void:
    if customers_served >= 1 and not achievements.has("First Service"):
        achievements.append("First Service")
    if best_combo >= 5 and not achievements.has("Combo Master"):
        achievements.append("Combo Master")
    if score >= 100 and not achievements.has("Five-Star Chef"):
        achievements.append("Five-Star Chef")
    if unlocked_level >= 20 and not achievements.has("Career Expert"):
        achievements.append("Career Expert")
    if total_rounds_played >= 10 and not achievements.has("Dedicated Chef"):
        achievements.append("Dedicated Chef")

func finish_game() -> void:
    if is_network_game and not is_host:
        return
    game_running = false
    game_paused = false
    game_timer.stop()
    cooking_timer.stop()
    cooking_active = false
    total_rounds_played += 1
    best_score = maxi(best_score, score)
    if game_mode == "Career" and customers_served >= 5:
        career_bonus_earned = 50
        coins += career_bonus_earned
        round_coins += career_bonus_earned
        unlocked_level = mini(30, maxi(unlocked_level, level + 1))
    check_achievements()
    save_progress()
    status_text = "ROUND COMPLETE!"
    show_results()
    if is_network_game and is_host:
        rpc("remote_finish_game", score, coins, round_coins, customers_served, customers_lost)

@rpc("authority", "call_remote", "reliable")
func remote_finish_game(final_score: int, final_coins: int, final_round_coins: int,
        served: int, lost: int) -> void:
    score = final_score
    coins = final_coins
    round_coins = final_round_coins
    customers_served = served
    customers_lost = lost
    game_running = false
    game_timer.stop()
    cooking_timer.stop()
    show_results()

func show_results() -> void:
    screen = "results"
    queue_redraw()
    var layout := make_layout("ROUND COMPLETE!", 34)
    layout.add_child(make_label("SCORE: %d" % score, 26, GREEN))
    layout.add_child(make_label("CUSTOMERS SERVED: %d" % customers_served, 19))
    layout.add_child(make_label("CUSTOMERS LOST: %d" % customers_lost, 19))
    layout.add_child(make_label("COINS EARNED: %d" % round_coins, 19, ORANGE))
    layout.add_child(make_label("BEST COMBO: %d" % best_combo, 19))
    if not is_network_game or is_host:
        add_button(layout, "PLAY AGAIN", func(): start_game(game_mode), GREEN)
    else:
        layout.add_child(make_label("Waiting for the host to start the next round.", 15))
    add_button(layout, "MAIN MENU", show_menu, PANEL)

func set_status(message: String) -> void:
    status_text = message
    if is_instance_valid(status_label):
        status_label.text = message

func load_progress() -> void:
    var config := ConfigFile.new()
    if config.load(SAVE_PATH) != OK:
        return
    coins = int(config.get_value("progress", "coins", 0))
    best_score = int(config.get_value("progress", "best_score", 0))
    unlocked_level = int(config.get_value("progress", "unlocked_level", 1))
    patience_upgrade = int(config.get_value("progress", "patience_upgrade", 0))
    total_rounds_played = int(config.get_value("progress", "total_rounds_played", 0))
    last_daily_reward = str(config.get_value("progress", "last_daily_reward", ""))
    chef1_outfit_index = int(config.get_value("settings", "chef1_outfit", 0))
    chef2_outfit_index = int(config.get_value("settings", "chef2_outfit", 1))
    selected_language = str(config.get_value("settings", "language", "English"))
    var saved := config.get_value("progress", "achievements", [])
    if saved is Array:
        for item in saved:
            achievements.append(str(item))

func save_progress() -> void:
    var config := ConfigFile.new()
    config.set_value("progress", "coins", coins)
    config.set_value("progress", "best_score", best_score)
    config.set_value("progress", "unlocked_level", unlocked_level)
    config.set_value("progress", "patience_upgrade", patience_upgrade)
    config.set_value("progress", "total_rounds_played", total_rounds_played)
    config.set_value("progress", "last_daily_reward", last_daily_reward)
    config.set_value("progress", "achievements", achievements)
    config.set_value("settings", "chef1_outfit", chef1_outfit_index)
    config.set_value("settings", "chef2_outfit", chef2_outfit_index)
    config.set_value("settings", "language", selected_language)
    config.save(SAVE_PATH)
