extends Node2D

var cantidad: float = 0.0  # cantidad inicial se asigna desde UI

func cargar(valor: float):
	cantidad = valor

func get_cantidad() -> float:
	return cantidad

func consumir(valor: float):
	cantidad = max(0.0, cantidad - valor)
