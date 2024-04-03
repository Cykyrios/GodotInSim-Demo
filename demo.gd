extends MarginContainer


@export var insim_address := "127.0.0.1"
@export var insim_port := 29_999

var insim := InSim.new()
var outsim := OutSim.new()
var outgauge := OutGauge.new()

var car_lights_timer := Timer.new()
var car_switches_timer := Timer.new()

@onready var insim_button := %InSimButton
@onready var car_lights_button := %CarLightsButton
@onready var car_switches_button := %CarSwitchesButton

@onready var outgauge_label := %OutGaugeLabel
@onready var outsim_label := %OutSimLabel


func _ready() -> void:
	var _discard := insim_button.pressed.connect(_on_insim_button_pressed) as int
	_discard = car_lights_button.pressed.connect(_on_car_lights_button_pressed)
	_discard = car_switches_button.pressed.connect(_on_car_switches_button_pressed)

	add_child(outgauge)
	outgauge.initialize()
	add_child(outsim)
	outsim.initialize(0x1ff)
	_discard = outgauge.packet_received.connect(update_outgauge)
	_discard = outsim.packet_received.connect(update_outsim)
	initialize_timers()

	add_child(insim)
	_discard = insim.packet_received.connect(func(packet: InSimPacket) -> void:
		print("Received packet ", packet)
		print(packet.get_dictionary())
	)


func _exit_tree() -> void:
	if insim.insim_connected:
		insim.close()
	outgauge.close()
	outsim.close()


func initialize_timers() -> void:
	add_child(car_lights_timer)
	add_child(car_switches_timer)
	var _discard := car_lights_timer.timeout.connect(send_random_lights)
	_discard = car_switches_timer.timeout.connect(send_random_switches)


func _on_insim_button_pressed() -> void:
	if insim.insim_connected:
		insim.close()
		insim_button.text = "Initialize InSim"
	else:
		var initialization_data := InSimInitializationData.new()
		insim.initialize(insim_address, insim_port, initialization_data)
		insim_button.text = "Close InSim"


func _on_car_lights_button_pressed() -> void:
	if car_lights_timer.is_stopped():
		car_lights_timer.start(0.1)
		car_lights_button.text = "Stop Car Lights"
		send_local_car_lights(CarLights.new())
	else:
		car_lights_timer.stop()
		send_local_car_lights(CarLights.new(CarLights.ALL_OFF))
		car_lights_button.text = "Send Random Car Lights"


func _on_car_switches_button_pressed() -> void:
	if car_switches_timer.is_stopped():
		car_switches_timer.start(0.1)
		car_switches_button.text = "Stop Car Switches"
	else:
		car_switches_timer.stop()
		send_local_car_switches(CarSwitches.new(CarSwitches.ALL_OFF))
		car_switches_button.text = "Send Random Car Switches"


func send_local_car_lights(lcl: CarLights) -> void:
	insim.send_packet(InSimSmallPacket.new(0, InSim.Small.SMALL_LCL, lcl.get_value()))


func send_local_car_switches(lcs: CarSwitches) -> void:
	insim.send_packet(InSimSmallPacket.new(0, InSim.Small.SMALL_LCS, lcs.get_value()))


func send_random_lights() -> void:
	var lcl := CarLights.new()
	lcl.set_signals = true
	lcl.set_lights = true
	lcl.set_fog_rear = true
	lcl.set_fog_front = true
	lcl.set_extra = true
	lcl.signals = randi() % 4
	lcl.lights = randi() % 4
	lcl.fog_rear = randi() % 2
	lcl.fog_front = randi() % 2
	lcl.extra = randi() % 2
	send_local_car_lights(lcl)


func send_random_switches() -> void:
	var lcs := CarSwitches.new()
	lcs.set_signals = false
	lcs.set_flash = true
	lcs.set_headlights = false
	lcs.set_horn = true
	lcs.set_siren = true
	lcs.signals = randi() % 4
	lcs.flash = randi() % 2
	lcs.headlights = randi() % 2
	lcs.horn = randi() % 6
	lcs.siren = randi() % 3
	send_local_car_switches(lcs)


func update_outgauge(outgauge_packet: OutGaugePacket) -> void:
	outgauge_label.text = "OutGauge:"
	outgauge_label.text += "\n%s: %s" % ["Time", outgauge_packet.time]
	outgauge_label.text += "\n%s: %s" % ["Car Name", outgauge_packet.car_name]
	outgauge_label.text += "\n%s: %s" % ["Flags", outgauge_packet.get_flags_array()]
	outgauge_label.text += "\n%s: %s" % ["Gear", outgauge_packet.gear]
	outgauge_label.text += "\n%s: %s" % ["Player ID", outgauge_packet.player_id]
	outgauge_label.text += "\n%s: %s" % ["Speed", outgauge_packet.speed]
	outgauge_label.text += "\n%s: %s" % ["RPM", outgauge_packet.rpm]
	outgauge_label.text += "\n%s: %s" % ["Turbo", outgauge_packet.turbo]
	outgauge_label.text += "\n%s: %s" % ["Engine Temperature", outgauge_packet.engine_temp]
	outgauge_label.text += "\n%s: %s" % ["Fuel", outgauge_packet.fuel]
	outgauge_label.text += "\n%s: %s" % ["Oil Pressure", outgauge_packet.oil_pres]
	outgauge_label.text += "\n%s: %s" % ["Oil Temperature", outgauge_packet.oil_temp]
	outgauge_label.text += "\n%s: %s" % ["Available Lights",
			outgauge_packet.get_lights_array(outgauge_packet.dash_lights)]
	outgauge_label.text += "\n%s: %s" % ["Active Lights",
			outgauge_packet.get_lights_array(outgauge_packet.show_lights)]
	outgauge_label.text += "\n%s: %s" % ["Throttle", outgauge_packet.throttle]
	outgauge_label.text += "\n%s: %s" % ["Brake", outgauge_packet.brake]
	outgauge_label.text += "\n%s: %s" % ["Clutch", outgauge_packet.clutch]
	outgauge_label.text += "\n%s: %s" % ["Display 1", outgauge_packet.display1]
	outgauge_label.text += "\n%s: %s" % ["Display 2", outgauge_packet.display2]
	outgauge_label.text += "\n%s: %s" % ["ID", outgauge_packet.id]


func update_outsim(outsim_packet: OutSimPacket) -> void:
	outsim_label.text = "OutSim:"
	var pack := outsim_packet.outsim_pack
	var os_options := pack.outsim_options
	if os_options & OutSim.OutSimOpts.OSO_HEADER:
		outsim_label.text += "\n%s%s%s%s" % [pack.header_l, pack.header_f, pack.header_s, pack.header_t]
	if os_options & OutSim.OutSimOpts.OSO_ID:
		outsim_label.text += "\n%s: %d" % ["ID", pack.id]
	if os_options & OutSim.OutSimOpts.OSO_TIME:
		outsim_label.text += "\n%s: %d" % ["Time", pack.time]
	if os_options & OutSim.OutSimOpts.OSO_MAIN:
		var outsim_main := pack.os_main
		outsim_label.text += "\n%s: %.2v" % ["AngVel", outsim_main.ang_vel]
		outsim_label.text += "\n%s: %.2f, %s: %.2f, %s: %.2f" % \
				["Heading", outsim_main.heading, "Pitch", outsim_main.pitch, "Roll", outsim_main.roll]
		outsim_label.text += "\n%s: %.2v" % ["Accel", outsim_main.accel]
		outsim_label.text += "\n%s: %.2v" % ["Vel", outsim_main.vel]
		outsim_label.text += "\n%s: %s" % ["Pos", outsim_main.pos]
	if os_options & OutSim.OutSimOpts.OSO_INPUTS:
		var outsim_inputs := pack.os_inputs
		outsim_label.text += "\n%s: %.2f, %s: %.2f, %s: %.2f, %s: %.2f, %s: %.2f" % \
				["Throttle", outsim_inputs.throttle, "Brake", outsim_inputs.brake,
				"InputSteer", outsim_inputs.input_steer, "Clutch", outsim_inputs.clutch,
				"Handbrake", outsim_inputs.handbrake]
	if os_options & OutSim.OutSimOpts.OSO_DRIVE:
		outsim_label.text += "\n%s: %d" % ["Gear", pack.gear]
		outsim_label.text += "\n%s: %.2f" % ["EngineAngVel", pack.engine_ang_vel]
		outsim_label.text += "\n%s: %.2f" % ["MaxTorqueAtVel", pack.max_torque_at_vel]
	if os_options & OutSim.OutSimOpts.OSO_DISTANCE:
		outsim_label.text += "\n%s: %.2f" % ["CurrentLapDistance", pack.current_lap_distance]
		outsim_label.text += "\n%s: %.2f" % ["IndexedDistance", pack.indexed_distance]
	if os_options & OutSim.OutSimOpts.OSO_WHEELS:
		var outsim_wheels := pack.os_wheels
		outsim_label.text += "\n%s: %.2f/%.2f/%.2f/%.2f" % ["SuspDeflect", outsim_wheels[0].susp_deflect, outsim_wheels[1].susp_deflect, outsim_wheels[2].susp_deflect, outsim_wheels[3].susp_deflect]
		outsim_label.text += "\n%s: %.2f/%.2f/%.2f/%.2f" % ["Steer", outsim_wheels[0].steer, outsim_wheels[1].steer, outsim_wheels[2].steer, outsim_wheels[3].steer]
		outsim_label.text += "\n%s: %.2f/%.2f/%.2f/%.2f" % ["XForce", outsim_wheels[0].x_force, outsim_wheels[1].x_force, outsim_wheels[2].x_force, outsim_wheels[3].x_force]
		outsim_label.text += "\n%s: %.2f/%.2f/%.2f/%.2f" % ["YForce", outsim_wheels[0].y_force, outsim_wheels[1].y_force, outsim_wheels[2].y_force, outsim_wheels[3].y_force]
		outsim_label.text += "\n%s: %.2f/%.2f/%.2f/%.2f" % ["VerticalLoad", outsim_wheels[0].vertical_load, outsim_wheels[1].vertical_load, outsim_wheels[2].vertical_load, outsim_wheels[3].vertical_load]
		outsim_label.text += "\n%s: %.2f/%.2f/%.2f/%.2f" % ["AngVel", outsim_wheels[0].ang_vel, outsim_wheels[1].ang_vel, outsim_wheels[2].ang_vel, outsim_wheels[3].ang_vel]
		outsim_label.text += "\n%s: %.2f/%.2f/%.2f/%.2f" % ["LeanRelToRoad", outsim_wheels[0].lean_rel_to_road, outsim_wheels[1].lean_rel_to_road, outsim_wheels[2].lean_rel_to_road, outsim_wheels[3].lean_rel_to_road]
		outsim_label.text += "\n%s: %d/%d/%d/%d" % ["AirTemp", outsim_wheels[0].air_temp, outsim_wheels[1].air_temp, outsim_wheels[2].air_temp, outsim_wheels[3].air_temp]
		outsim_label.text += "\n%s: %d/%d/%d/%d" % ["SlipFraction", outsim_wheels[0].slip_fraction, outsim_wheels[1].slip_fraction, outsim_wheels[2].slip_fraction, outsim_wheels[3].slip_fraction]
		outsim_label.text += "\n%s: %d/%d/%d/%d" % ["Touching", outsim_wheels[0].touching, outsim_wheels[1].touching, outsim_wheels[2].touching, outsim_wheels[3].touching]
		outsim_label.text += "\n%s: %.2f/%.2f/%.2f/%.2f" % ["SlipRatio", outsim_wheels[0].slip_ratio, outsim_wheels[1].slip_ratio, outsim_wheels[2].slip_ratio, outsim_wheels[3].slip_ratio]
		outsim_label.text += "\n%s: %.2f/%.2f/%.2f/%.2f" % ["TanSlipAngle", outsim_wheels[0].tan_slip_angle, outsim_wheels[1].tan_slip_angle, outsim_wheels[2].tan_slip_angle, outsim_wheels[3].tan_slip_angle]
	if os_options & OutSim.OutSimOpts.OSO_EXTRA_1:
		outsim_label.text += "\n%s: %.2f" % ["SteerTorque", pack.steer_torque]
