extends Node2D

signal mezcla_listo
signal descarga_listo
signal mezcla_final_depositada

var mezclando := false
var mezcla_vacia := true
var mezcla_descargada := false
var valvula_abierta := false

func esta_mezclando() -> bool:
	return mezclando

func esta_vacio() -> bool:
	return mezcla_vacia

func iniciar_mezcla(duracion):
	mezclando = true
	mezcla_vacia = true

	var timer = get_tree().create_timer(duracion)
	yield(timer, "timeout")

	mezclando = false
	emit_signal("mezcla_listo")

func descargar_en():
	mezcla_descargada = false  # aún no descargada
	var tubo = get_node("/root/main/Mezclador/DescargaTubo")
	tubo.visible = true

	var tween = Tween.new()
	add_child(tween)
	tween.interpolate_property(
		tubo,
		"rect_size",
		Vector2(20, 0),
		Vector2(40, 95),
		1.0,
		Tween.TRANS_LINEAR,
		Tween.EASE_OUT
	)
	tween.start()

	yield(get_tree().create_timer(1.0), "timeout")

	tubo.visible = false
	tubo.rect_size = Vector2(0, 20)

	mezcla_vacia = true
	mezcla_descargada = true
	emit_signal("descarga_listo")

func reset_visual():
	$NivelMezcla.visible = false
	$Helice.rotation_degrees = 0
	valvula_abierta = false
	mezcla_descargada = false

func subir_nivel():
	$NivelMezcla.visible = true
	$NivelMezcla.rect_scale = Vector2(1, 0.1)

	var tween = Tween.new()
	add_child(tween)

	tween.interpolate_property(
		$NivelMezcla,
		"rect_scale",
		Vector2(0, 0),
		Vector2(3, -1.7),
		0.3,
		Tween.TRANS_LINEAR,
		Tween.EASE_OUT
	)

	tween.start()

func abrir_valvula_final():
	if not valvula_abierta and mezcla_descargada:
		valvula_abierta = true
		var valvula_final = get_node("/root/main/Mezclador/ValvulaFinal/Cuerpo")
		valvula_final.modulate = Color(1, 0.6, 0.6)
		print("✅ Válvula final abierta. Iniciando vertido...")
		emitir_mezcla_final()
	else:
		print("⚠️ No se puede abrir la válvula: mezcla no ha sido descargada o ya está abierta.")

func emitir_mezcla_final():
	var flujo = get_node("/root/main/VertidoFinal/FluidoVertido")
	flujo.visible = true
	flujo.rect_size = Vector2(10, 0)

	var tween = Tween.new()
	add_child(tween)

	tween.interpolate_property(
		flujo,
		"rect_size",
		Vector2(0, -10),
		Vector2(40, 40),
		1.0,
		Tween.TRANS_LINEAR,
		Tween.EASE_OUT
	)
	tween.start()
	mezcla_vacia = false
	get_node("/root/main").actualizar_panel_sensores()
	yield(get_tree().create_timer(1.0), "timeout")

	flujo.visible = false
	flujo.rect_size = Vector2(10, 0)
	emit_signal("mezcla_final_depositada")
	print("🧪 Mezcla final depositada en el recipiente destino.")
	
		# Marcar el recipiente final como lleno
	var vertido_final = get_node("/root/main/VertidoFinal")
	if vertido_final.has_method("set_lleno"):
		vertido_final.set_lleno(true)
	# Actualizar sensores
	get_node("/root/main").actualizar_panel_sensores()
		
	yield(get_tree().create_timer(1.0), "timeout")
	flujo.visible = false
	emit_signal("mezcla_final_depositada")

func cerrar_valvula_final():
	if valvula_abierta:
		valvula_abierta = false
		var valvula_final = get_node("/root/main/Mezclador/ValvulaFinal/Cuerpo")
		valvula_final.modulate = Color(1, 1, 1)  # Color de válvula cerrada

		print("🔒 Válvula final cerrada.")
	
func _process(delta):
	if mezclando:
		$Helice.rotation_degrees += 200 * delta
