extends Node2D

signal start_pressed

func _ready():
	$VBox/ButtonStart.connect("pressed", self, "_on_pressed")

func _on_pressed():
	emit_signal("start_pressed")

func get_pesoA():
	return $VBox/SpinBoxA.value

func get_pesoB():
	return $VBox/SpinBoxB.value

func get_tiempo_mezcla():
	return 5.0  # segundos
	
func set_estado(texto):
	$LabelEstado.text = "Estado: " + texto
