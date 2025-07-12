extends Node2D

enum Estado {
	IDLE, LLENANDO_A, VOLCANDO_A,
	LLENANDO_B, VOLCANDO_B,
	MEZCLANDO, DESCARGANDO
}

var estado = Estado.IDLE

onready var ui = $UI
onready var deposito_a = $DepositoA
onready var deposito_b = $DepositoB
onready var recipiente_c = $RecipienteC
onready var mezclador = $Mezclador
signal mezcla_final_depositada

func _ready():
	ui.connect("start_pressed", self, "_on_iniciar")
	estado = Estado.IDLE

func _on_iniciar():
	if estado != Estado.IDLE:
		print("Ya hay un proceso en curso.")
		return

	if recipiente_c.peso_actual > 0:
		print("El recipiente C debe estar vacío.")
		return

	if mezclador.esta_mezclando():
		print("El mezclador debe estar vacío y detenido.")
		return

	# Nueva validación: mínimo de 10g en A y B
	var peso_a = ui.get_pesoA()
	var peso_b = ui.get_pesoB()

	if peso_a < 10 or peso_b < 10:
		print("Debe haber al menos 10g en A y B para iniciar.")
		ui.set_estado("Err: cantidad insuficiente en depósitos (<10g)")
		return

	estado = Estado.LLENANDO_A
	ui.set_estado("Llenando producto A...")
	print("Inicio: llenando producto A.")
	llenar_producto_a()

# -------------------
# Fase A
# -------------------
func llenar_producto_a():
	var peso_a = ui.get_pesoA()
	recipiente_c.comenzar_llenado(peso_a)
	recipiente_c.connect("peso_alcanzado", self, "_on_a_listo")
	
	deposito_a.get_node("Valve").modulate = Color(1, 0.5, 0.5)
	deposito_a.get_node("Flujo").visible = true
	deposito_a.get_node("Flujo2").visible = true
	deposito_a.get_node("Flujo3").visible = true

func _on_a_listo():
	recipiente_c.disconnect("peso_alcanzado", self, "_on_a_listo")
	print("Producto A alcanzado. Vaciando en mezclador...")

	estado = Estado.VOLCANDO_A

	# Detener visual del depósito A
	deposito_a.get_node("Valve").modulate = Color(1, 1, 1)
	deposito_a.get_node("Flujo").visible = false
	deposito_a.get_node("Flujo2").visible = false
	deposito_a.get_node("Flujo3").visible = false
	# Activar flujo visual desde RecipienteC al Mezclador
	$RecipienteC/FlujoCtoM.visible = true

	# Iniciar vaciado simulado
	recipiente_c.vaciar_en_mezclador()
	recipiente_c.connect("vaciado_completo", self, "_on_vaciado_a")

func _on_vaciado_a():
	recipiente_c.disconnect("vaciado_completo", self, "_on_vaciado_a")
	print("Recipiente C vacío tras producto A.")

	# Detener flujo visual del RecipienteC al Mezclador
	$RecipienteC/FlujoCtoM.visible = false

	# Activar nivel visual en mezclador
	mezclador.subir_nivel()

	# Pasar al siguiente estado
	estado = Estado.LLENANDO_B
	ui.set_estado("Llenando producto B...")

	# Iniciar llenado de producto B
	llenar_producto_b()

# -------------------
# Fase B
# -------------------
func llenar_producto_b():
	var peso_b = ui.get_pesoB()
	recipiente_c.comenzar_llenado(peso_b)
	recipiente_c.connect("peso_alcanzado", self, "_on_b_listo")
	
	deposito_b.get_node("Valve").modulate = Color(1, 0.5, 0.5)
	deposito_b.get_node("Flujo").visible = true
	deposito_b.get_node("Flujo2").visible = true
	deposito_b.get_node("Flujo3").visible = true

func _on_b_listo():
	recipiente_c.disconnect("peso_alcanzado", self, "_on_b_listo")
	print("Producto B alcanzado. Vaciando en mezclador...")

	estado = Estado.VOLCANDO_B

	# Detener visual del depósito B
	deposito_b.get_node("Valve").modulate = Color(1, 1, 1)
	deposito_b.get_node("Flujo").visible = false
	deposito_b.get_node("Flujo2").visible = false
	deposito_b.get_node("Flujo3").visible = false
	# Activar flujo visual del recipiente C al mezclador
	$RecipienteC/FlujoCtoM.visible = true

	# Iniciar vaciado hacia el mezclador
	recipiente_c.vaciar_en_mezclador()
	recipiente_c.connect("vaciado_completo", self, "_on_vaciado_b")
	

func _on_vaciado_b():
	recipiente_c.disconnect("vaciado_completo", self, "_on_vaciado_b")
	print("Recipiente C vacío tras producto B.")

	# Detener flujo visual del recipiente
	$RecipienteC/FlujoCtoM.visible = false

	# Subir nivel visual del mezclador
	mezclador.subir_nivel()

	# Actualizar estado
	estado = Estado.MEZCLANDO
	ui.set_estado("Mezclando...")

	# Iniciar mezcla con duración desde UI
	mezclador.iniciar_mezcla(ui.get_tiempo_mezcla())
	mezclador.connect("mezcla_listo", self, "_on_mezcla_completada")
	

# -------------------
# Mezcla y descarga
# -------------------

func _on_mezcla_completada():
	
	mezclador.disconnect("mezcla_listo", self, "_on_mezcla_completada")
	print("Mezcla completada. Descargando contenido del mezclador...")

	estado = Estado.DESCARGANDO
	ui.set_estado("Descargando mezcla...")

	# Opcional: animar color o rotación residual del mezclador
	mezclador.descargar_en()
	mezclador.connect("descarga_listo", self, "_on_descarga_completa")
	
	
func _on_descarga_completa():
	mezclador.disconnect("descarga_listo", self, "_on_descarga_completa")
	print("Descarga completa. Proceso finalizado.")

	estado = Estado.IDLE
	ui.set_estado("Sistema listo")

	# Reset visual del mezclador
	mezclador.reset_visual()
	ui.set_estado("🔓 Válvula abierta: vertiendo mezcla final...")
	mezclador.abrir_valvula_final()
	mezclador.connect("mezcla_final_depositada", self, "_on_mezcla_final_recibida")

	

func _on_mezcla_final_recibida():
	ui.set_estado("🧪 Recipiente final lleno. Proceso completo.")
	print("Recipiente destino ha recibido la mezcla.")
