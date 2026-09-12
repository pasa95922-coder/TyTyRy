extends Control

@onready var start_button: Button = $Center/Panel/StartButton
@onready var subtitle: Label = $Center/Panel/Subtitle
@onready var main_ui: CenterContainer = $Center
@onready var loading_overlay: Control = $LoadingOverlay
@onready var loading_status: Label = $LoadingOverlay/Center/Panel/Status
@onready var loading_progress: ProgressBar = $LoadingOverlay/Center/Panel/Progress
@onready var splash_overlay: Control = $SplashOverlay

func _ready() -> void:
	# The first version keeps no currency, accounts, or secrets on-device.
	# Critical game data should be validated by a server when it is added.
	start_button.pressed.connect(_on_start_pressed)
	show_loading_sequence()

func show_loading_sequence() -> void:
	loading_progress.value = 0.0
	var progress_tween := create_tween()
	progress_tween.tween_property(loading_progress, "value", 100.0, 1.8)
	for percent in [20, 45, 70, 100]:
		await get_tree().create_timer(0.45).timeout
		loading_status.text = "Загрузка… %d%%" % percent
	await get_tree().create_timer(0.05).timeout
	loading_overlay.hide()
	splash_overlay.show()
	await get_tree().create_timer(1.4).timeout
	splash_overlay.hide()
	main_ui.show()

func _on_start_pressed() -> void:
	subtitle.text = "Новая игра начнётся здесь"
