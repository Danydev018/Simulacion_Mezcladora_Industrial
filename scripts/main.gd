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
onready var valvula_cm = $RecipienteC/ValveCM
onready var sensor_a_mesh = $UI/SensorA
onready var sensor_b_mesh = $UI/SensorB
onready var sensor_c_mesh = $UI/SensorC
onready var sensor_m_mesh: MeshInstance2D = $UI/SensorM
onready var sensor_f_mesh: MeshInstance2D = $UI/SensorF

signal mezcla_final_depositada

var recipiente_final_lleno = false
var estado_sensor_a
var estado_sensor_b
var estado_sensor_c
var estado_sensor_m
var estado_sensor_f

var indicador_a
var indicador_b
var indicador_c
var indicador_m
var indicador_f


func _ready():
	ui.connect("start_pressed", self, "_on_iniciar")
	estado = Estado.IDLE
	
	estado_sensor_a = $VBoxContainer/SensorA/LabelEstadoA
	estado_sensor_b = $VBoxContainer/SensorB/LabelEstadoB
	estado_sensor_c = $VBoxContainer/SensorC/LabelEstadoC
	estado_sensor_m = $VBoxContainer/SensorM/LabelEstadoM
	estado_sensor_f = $VBoxContainer/SensorF/LabelEstadoF

	indicador_a = $VBoxContainer/SensorA/IndicadorA
	indicador_b = $VBoxContainer/SensorB/IndicadorB
	indicador_c = $VBoxContainer/SensorC/IndicadorC
	indicador_m = $VBoxContainer/SensorM/IndicadorM
	indicador_f = $VBoxContainer/SensorF/IndicadorF
	actualizar_panel_sensores()
	

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
	# Cargar depósitos con valores del input
	deposito_a.cargar(ui.get_pesoA())
	#deposito_b.cargar(ui.get_pesoB())
	actualizar_panel_sensores()

	recipiente_final_lleno = false
	actualizar_panel_sensores()

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
	actualizar_panel_sensores()

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
	$RecipienteC/FlujoCtoM2.visible = true
	valvula_cm.modulate = Color(1, 0.6, 0.6)  # color de válvula abierta

	# Iniciar vaciado simulado
	recipiente_c.vaciar_en_mezclador()
	recipiente_c.connect("vaciado_completo", self, "_on_vaciado_a")
	actualizar_panel_sensores()
	deposito_a.consumir(ui.get_pesoA())
	actualizar_panel_sensores()


func _on_vaciado_a():
	recipiente_c.disconnect("vaciado_completo", self, "_on_vaciado_a")
	print("Recipiente C vacío tras producto A.")

	# Detener flujo visual del RecipienteC al Mezclador
	$RecipienteC/FlujoCtoM.visible = false
	$RecipienteC/FlujoCtoM2.visible = false
	valvula_cm.modulate = Color(1, 1, 1)  # color normal / cerrada
	# Activar nivel visual en mezclador
	mezclador.subir_nivel()

	# Pasar al siguiente estado
	estado = Estado.LLENANDO_B
	ui.set_estado("Llenando producto B...")

	# Iniciar llenado de producto B
	llenar_producto_b()
	actualizar_panel_sensores()


# -------------------
# Fase B
# -------------------
func llenar_producto_b():
	deposito_b.cargar(ui.get_pesoB())
	var peso_b = ui.get_pesoB()
	recipiente_c.comenzar_llenado(peso_b)
	recipiente_c.connect("peso_alcanzado", self, "_on_b_listo")
	
	deposito_b.get_node("Valve").modulate = Color(1, 0.5, 0.5)
	deposito_b.get_node("Flujo").visible = true
	deposito_b.get_node("Flujo2").visible = true
	deposito_b.get_node("Flujo3").visible = true
	actualizar_panel_sensores()

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
	$RecipienteC/FlujoCtoM2.visible = true
	valvula_cm.modulate = Color(1, 0.6, 0.6)  # color de válvula abierta

	# Iniciar vaciado hacia el mezclador
	recipiente_c.vaciar_en_mezclador()
	recipiente_c.connect("vaciado_completo", self, "_on_vaciado_b")
	deposito_b.consumir(ui.get_pesoB())
	actualizar_panel_sensores()


func _on_vaciado_b():
	recipiente_c.disconnect("vaciado_completo", self, "_on_vaciado_b")
	print("Recipiente C vacío tras producto B.")

	# Detener flujo visual del recipiente
	$RecipienteC/FlujoCtoM.visible = false
	$RecipienteC/FlujoCtoM2.visible = false
	valvula_cm.modulate = Color(1, 1, 1)  # color normal / cerrada
	# Subir nivel visual del mezclador
	mezclador.subir_nivel()

	# Actualizar estado
	estado = Estado.MEZCLANDO
	ui.set_estado("Mezclando...")

	# Iniciar mezcla con duración desde UI
	mezclador.connect("mezcla_listo", self, "_on_mezcla_completada")
	mezclador.iniciar_mezcla(ui.get_tiempo_mezcla())
	actualizar_panel_sensores()

# -------------------
# Mezcla y descarga
# -------------------

func _on_mezcla_completada():
	recipiente_final_lleno = true
	actualizar_panel_sensores()
	mezclador.disconnect("mezcla_listo", self, "_on_mezcla_completada")
	print("Mezcla completada. Descargando contenido del mezclador...")

	estado = Estado.DESCARGANDO
	ui.set_estado("Descargando mezcla...")

	# Opcional: animar color o rotación residual del mezclador
	mezclador.descargar_en()
	mezclador.connect("descarga_listo", self, "_on_descarga_completa")
	

	
func _on_descarga_completa():
	
	mezclador.disconnect("descarga_listo", self, "_on_descarga_completa")
	print("Descarga completa. Preparando válvula final...")

	estado = Estado.IDLE
	ui.set_estado("🔓 Preparando válvula final...")
	mezclador.connect("mezcla_final_depositada", self, "_on_mezcla_final_recibida")

	call_deferred("_abrir_valvula_seguro")  # ✅ llamada diferida
	
func _abrir_valvula_seguro():
	if mezclador.esta_vacio():  # Opcional si deseas añadir doble verificación
		mezclador.abrir_valvula_final()
	else:
		print("⚠️ Mezclador no está vacío. Válvula no se puede abrir.")
		
func _on_mezcla_final_recibida():
	recipiente_final_lleno = false
	actualizar_panel_sensores()
	ui.set_estado("🧪 Recipiente final lleno. Proceso completo.")
	print("Recipiente destino ha recibido la mezcla.")
	mezclador.cerrar_valvula_final()


func actualizar_panel_sensores():

	var COLOR_VERDE = Color(0, 1, 0, 1) 
	var COLOR_ROJO = Color(1, 0, 0, 1)   

	# Sensor A
	var deposito_a_lleno = deposito_a.get_cantidad() > 0
	estado_sensor_a.text = "LLENO" if deposito_a_lleno else "VACÍO"
	indicador_a.color = COLOR_VERDE if deposito_a_lleno else COLOR_ROJO
	sensor_a_mesh.modulate = COLOR_VERDE if deposito_a_lleno else COLOR_ROJO
	
	# Sensor B - Depósito B
	var deposito_b_lleno = deposito_b.get_cantidad() > 0
	estado_sensor_b.text = "LLENO" if deposito_b_lleno else "VACÍO"
	indicador_b.color = COLOR_VERDE if deposito_b_lleno else COLOR_ROJO
	sensor_b_mesh.modulate = COLOR_VERDE if deposito_b_lleno else COLOR_ROJO

	# Sensor C (Recipiente)
	var lleno_c = recipiente_c.get_peso() > 0

	if lleno_c:
		estado_sensor_c.text = "LLENO"
		indicador_c.color = COLOR_VERDE
		sensor_c_mesh.modulate = COLOR_VERDE
	else:
		estado_sensor_c.text = "VACÍO"
		indicador_c.color = COLOR_ROJO
		sensor_c_mesh.modulate = COLOR_ROJO

	# Sensor M (Motor mezclador)
	var mezclando = mezclador.esta_mezclando()

	if mezclando:
		estado_sensor_m.text = "MEZCLANDO"
		indicador_m.color = COLOR_VERDE  # rojo
		sensor_m_mesh.modulate = COLOR_VERDE
	else:
		estado_sensor_m.text = "VACÍO"
		indicador_m.color = COLOR_ROJO  # verde
		sensor_m_mesh.modulate = COLOR_ROJO

	# Sensor F - Recipiente Final
	estado_sensor_f.text = "LLENO" if recipiente_final_lleno else "VACÍO"
	indicador_f.color = COLOR_VERDE if recipiente_final_lleno else COLOR_ROJO
	sensor_f_mesh.modulate = COLOR_VERDE if recipiente_final_lleno else COLOR_ROJO
