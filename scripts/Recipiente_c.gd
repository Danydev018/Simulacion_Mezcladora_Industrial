extends Node2D

signal peso_alcanzado
signal vaciado_completo

var peso_actual = 0
var peso_objetivo = 0
var llenando = false

onready var timer = Timer.new()

func _ready():
	add_child(timer)
	timer.wait_time = 0.1
	timer.connect("timeout", self, "_on_tick")

func comenzar_llenado(peso_deseado):
	peso_objetivo = peso_deseado
	peso_actual = 0
	llenando = true
	timer.start()

func _on_tick():
	if llenando:
		peso_actual += 10  # Simulamos flujo constante
		$LabelPeso.text = str(peso_actual) + "g"
		if peso_actual >= peso_objetivo:
			timer.stop()
			llenando = false
			emit_signal("peso_alcanzado")

func vaciar_en_mezclador():
	$LabelPeso.text = "Vaciando..."
	yield(get_tree().create_timer(1.0), "timeout")
	peso_actual = 0
	$LabelPeso.text = "0g"
	emit_signal("vaciado_completo")
