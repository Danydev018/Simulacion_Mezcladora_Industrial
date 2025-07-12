extends Node2D

var valve_open = false

func abrir_valvula_deposito_a():
	$DepositoA/Valve.modulate = Color(1, 0.5, 0.5)
	$DepositoA/Flujo.visible = true

func cerrar_valvula_deposito_a():
	$DepositoA/Valve.modulate = Color(1, 1, 1)
	$DepositoA/Flujo.visible = false


func animar_flujo():
	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property($Flujo, "rect_scale", Vector2(0, 1), Vector2(1, 1), 0.5,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
