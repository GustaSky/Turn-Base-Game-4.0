extends Control

export(Resource) var enemy = null

var current_player_health = 0
var current_enemy_health = 0
var is_defending = false

var danoEN = 15
var parry_active = false
var lfs_active = false
var rng = RandomNumberGenerator.new()

var case = 3

var qte_active = false
var qte_success_time = 2  

onready var animated_sprite = $Parry

signal textbox_closed  # Sinal para fechar o textbox

func _ready():
	var screen_size = get_viewport().get_size()
	if $Label:
		$Label.rect_position = Vector2((screen_size.x - $Label.rect_size.x) / 2, (screen_size.y - $Label.rect_size.y) / 2)

	$QTEataque.visible = false 
	$Parry.visible = false

	# Inicializar barras de vida com verificações
	set_health($EnemyContainer/ProgressBar, enemy.health, enemy.health)
	set_health($PlayerPanel/PlayerData/ProgressBar, State.current_health, State.max_health)
	$EnemyContainer/Enemy.texture = enemy.texture

	current_player_health = State.current_health
	current_enemy_health = enemy.health

	$TextBox.hide()
	$ActionsPanel.hide()

	yield(display_text("Um %s selvagem apareceu!!!" % enemy.name), "completed")

func display_text(text):
	$TextBox.show()
	$TextBox.get_node("Label").text = text
	yield(self, "textbox_closed")  # Espera pelo fechamento do textbox
	$ActionsPanel.show()

func set_health(progress_bar, health, max_health):
	if progress_bar:
		progress_bar.value = health
		progress_bar.max_value = max_health
		progress_bar.get_node("Label").text = "HP: %d/%d" % [health, max_health]
	else:
		print("Progress bar is null")

func fail_parry():
	$Parry.visible = false
	
	yield(display_text("%s TE DEU UMAS PORRADAS FORTES!!!" % enemy.name), "completed")

	current_player_health = max(0, current_player_health - enemy.damage)
	set_health($PlayerPanel/PlayerData/ProgressBar, current_player_health, State.max_health)

	$AnimationPlayer.play("shake")
	yield($AnimationPlayer, "animation_finished")

	yield(display_text("VOCE ERROU O PARRY E LEVOU %d DE DANO!!!" % enemy.damage), "completed")
	$ActionsPanel.show()

func enemy_turn():
	rng.randomize()
	var parryPro = rng.randi_range(0, 100)

	yield(display_text("%s TE DEU UMAS PORRADAS FORTES!!!" % enemy.name), "completed")

	# Verifica se o parry foi ativado e se o RNG foi bem-sucedido
	if parry_active and parryPro > 1:
		parryON()  # Inicia o QTE para o parry
		return  # Adiciona um return aqui para não continuar a execução

	# Caso o parry não tenha sido ativado
	if is_defending:
		is_defending = false
		$AnimationPlayer.play("shake")
		yield($AnimationPlayer, "animation_finished")
		yield(display_text("VOCE DEFENDEU CORRETAMENTE!!!"), "completed")
	else:
		var damage_taken = max(0, enemy.damage)
		current_player_health = max(0, current_player_health - damage_taken)
		set_health($PlayerPanel/Data/ProgressBar, current_player_health, State.max_health)

		$AnimationPlayer.play("shake")
		yield($AnimationPlayer, "animation_finished")

		yield(display_text("%s DEU %d DE DANO!!!" % [enemy.name, damage_taken]), "completed")

	if current_player_health <= 0:
		yield(display_text("VOCE FOI DERROTADO!!!"), "completed")
		get_tree().quit()

func start_qte():
	qte_active = true
	$Timer.start(qte_success_time)  
	$QTEataque.visible = true  
	$QTEataque.stop()  
	$QTEataque.play("default")  
	$QTEataque.set_frame(0) 

func start_parry():
	$Timer.start(qte_success_time)  
	$Parry.visible = true  
	$Parry.stop()  
	$Parry.play("default")  
	$Parry.set_frame(0) 

func parryON():
	start_parry()  # Inicia o QTE do parry
	parry_active = true  # Sempre ativa o parry se os requisitos forem cumpridos

func fail_qte():
	if not qte_active:
		return  

	qte_active = false
	$QTEataque.visible = false
	yield(display_text("VOCÊ TROPECOU ENQUANTO IA ATACAR!!!"), "completed")

	current_enemy_health = max(0, current_enemy_health - State.fail_damage)
	set_health($EnemyContainer/ProgressBar, current_enemy_health, enemy.health)

	$AnimationPlayer.play("Enemy_damaged")
	yield($AnimationPlayer, "animation_finished")

	yield(display_text("VOCÊ DEU %d DE DANO!!!" % State.fail_damage), "completed")
	enemy_turn()

func handle_qte_success():
	current_enemy_health = max(0, current_enemy_health - State.crit_damage)
	set_health($EnemyContainer/ProgressBar, current_enemy_health, enemy.health)

	if lfs_active:
		current_player_health = min(State.max_health, current_player_health + State.vampirismo)
		set_health($PlayerPanel/PlayerData/ProgressBar, current_player_health, State.max_health)
		yield(display_text("VOCE ACERTOU UM CRITICO E RECUPEROU SUA FORCA"), "completed")

	$AnimationPlayer.play("Enemy_damaged")
	yield($AnimationPlayer, "animation_finished")
	yield(display_text("VOCE DEU %d DE DANO!!!" % State.crit_damage), "completed")

	if current_enemy_health <= 0:
		yield(display_text("VOCÊ MATOU O MATOU"), "completed")
		$AnimationPlayer.play("enemy_death")
		yield($AnimationPlayer, "animation_finished")
		get_tree().quit()

	enemy_turn()

func handle_parry_success():
	if case == 1:
		yield(display_text("%s TE DEU UMAS PORRADAS FORTES!!!" % enemy.name), "completed")
		current_player_health = max(0, current_player_health - enemy.damage * 0.5)

		set_health($PlayerPanel/PlayerData/ProgressBar, current_player_health, State.max_health)

		$AnimationPlayer.play("shake")
		yield($AnimationPlayer, "animation_finished")

		yield(display_text("VOCE DEFENDEU PERFEITAMENTE MAS AINDA TEVE CONSEQUENCIAS"), "completed")
		$ActionsPanel.show()
	elif case == 2:
		yield(display_text("%s TE DEU UMAS PORRADAS FORTES!!!" % enemy.name), "completed")

		set_health($PlayerPanel/PlayerData/ProgressBar, current_player_health, State.max_health)

		$AnimationPlayer.play("shake")
		yield($AnimationPlayer, "animation_finished")

		yield(display_text("VOCE CONSEGUIU SE DEFENDER NEGANDO O DANO POR COMPLETO"), "completed")
		$ActionsPanel.show()
	elif case == 3:
		yield(display_text("%s TE DEU UMAS PORRADAS FORTES!!!" % enemy.name), "completed")
		current_enemy_health = max(0, current_enemy_health - enemy.damage * 0.5)
		set_health($EnemyContainer/ProgressBar, current_enemy_health, enemy.health)

		set_health($PlayerPanel/PlayerData/ProgressBar, current_player_health, State.max_health)

		$AnimationPlayer.play("shake")
		yield($AnimationPlayer, "animation_finished")

		yield(display_text("VOCE SE DEFENDEU E CONSEGUIU DEFLETIR %d DE DANO!!!" % danoEN), "completed")
		$ActionsPanel.show()
		
		if current_enemy_health <= 0:
			yield(display_text("VOCÊ MATOU O MATOU"), "completed")
			$AnimationPlayer.play("enemy_death")
			yield($AnimationPlayer, "animation_finished")
			get_tree().quit()

func _on_Run_pressed():
	yield(display_text("FUGIU!!!"), "completed")
	get_tree().quit()

func _on_Attack_pressed():
	start_qte()

func _on_Defend_pressed():
	is_defending = true
	
	yield(display_text("VOCE MONTOU GUARDA!!!"), "completed")
	enemy_turn()

func _on_Parry_on_pressed():
	parry_active = !parry_active

func _on_Vampi_pressed():
	lfs_active = !lfs_active
	print(lfs_active)

func _input(event):
	if $TextBox.visible:
		handle_textbox_input_QTE(event)
		handle_textbox_input_Parry(event)

	if qte_active:
		handle_qte_input(event)

func handle_textbox_input_QTE(event):
	if (Input.is_action_just_pressed("ui_critico") or Input.is_mouse_button_pressed(BUTTON_LEFT)):
		$TextBox.hide()
		emit_signal("textbox_closed")
		return  

func handle_qte_input(event):
	if event is InputEventKey and event.pressed:
		if event.is_action_pressed("ui_critico"):
			var time_pressed = $Timer.get_time_left()
			if time_pressed > 0:  
				qte_active = false
				$Timer.stop()
				$QTEataque.visible = false
				handle_qte_success()
				return
		else:
			fail_qte() 

func handle_textbox_input_Parry(event):
	if (Input.is_action_just_pressed("ui_parry") or Input.is_mouse_button_pressed(BUTTON_LEFT)):
		$TextBox.hide()
		emit_signal("textbox_closed")
		return 

func _process(delta):
	if $QTEataque.frame == 63:
		fail_qte()  

	if parry_active and $Parry.visible:
		if $Parry.frame == 90:
			fail_parry()
		elif $Parry.frame >= 45 and $Parry.frame <= 58:
			if Input.is_action_just_pressed("ui_parry"):
				$Parry.stop()  # Interrompe a animação
				$Parry.visible = false  # Esconde o parry
				handle_parry_success()
				return
			else:
				$Parry.play("parry_animation")
