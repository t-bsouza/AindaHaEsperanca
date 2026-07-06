class_name GameNarrativeService
extends RefCounted


static func build_final_week_summary(
	survived_count: int,
	dead_count: int,
	total_count: int,
	dead_patient_names: Array[String],
	survived_patient_names: Array[String]
) -> String:
	var text := "Diário - Fim da Semana\n\n"
	text += "Sete dias se passaram desde que comecei a atender os doentes desta vila.\n\n"

	text += "Resultado final:\n"
	text += "- Sobreviventes: %d\n" % survived_count
	text += "- Mortos: %d\n" % dead_count
	text += "- Total de pacientes: %d\n\n" % total_count

	if total_count <= 0:
		text += "Nenhum paciente chegou até mim. A semana terminou em silêncio, sem vitória e sem derrota.\n"
		return text

	if dead_count <= 0:
		text += _build_perfect_victory_text(survived_patient_names)
		return text

	if survived_count <= 0:
		text += _build_total_defeat_text(dead_patient_names)
		return text

	text += _build_partial_ending_text(dead_patient_names, survived_patient_names)
	return text


static func build_game_over_summary(
	dead_count: int,
	total_count: int,
	dead_patient_names: Array[String]
) -> String:
	var text := "Diário - Game Over\n\n"
	text += "O último paciente morreu.\n\n"
	text += "Não há mais ninguém para salvar. A peste venceu antes do fim da semana.\n\n"

	text += "Resultado final:\n"
	text += "- Sobreviventes: 0\n"
	text += "- Mortos: %d\n" % dead_count
	text += "- Total de pacientes: %d\n\n" % total_count

	if not dead_patient_names.is_empty():
		text += "Pacientes que morreram:\n"
		for patient_name in dead_patient_names:
			text += "- %s\n" % patient_name
		text += "\n"

	text += "A casa ficou em silêncio. Não restou cura, promessa ou esperança suficiente para salvar a vila."

	return text


static func _build_perfect_victory_text(survived_patient_names: Array[String]) -> String:
	var text := "Todos sobreviveram.\n\n"
	text += "Contra a peste, contra o medo e contra a falta de recursos, a esperança resistiu.\n"
	text += "Cada escolha, cada mistura e cada hora sacrificada impediram que a morte levasse mais alguém.\n\n"

	if not survived_patient_names.is_empty():
		text += "Pacientes salvos:\n"
		for patient_name in survived_patient_names:
			text += "- %s\n" % patient_name
		text += "\n"

	text += "A semana termina com cansaço, mas também com vida. Ainda há esperança."

	return text


static func _build_total_defeat_text(dead_patient_names: Array[String]) -> String:
	var text := "Ninguém sobreviveu.\n\n"
	text += "A peste levou todos os pacientes que chegaram até mim. "
	text += "Meu diário termina como uma confissão de fracasso.\n\n"

	if not dead_patient_names.is_empty():
		text += "Pacientes que morreram:\n"
		for patient_name in dead_patient_names:
			text += "- %s\n" % patient_name
		text += "\n"

	text += "Não há comemoração, nem alívio. Apenas o peso das escolhas que não foram suficientes."

	return text


static func _build_partial_ending_text(
	dead_patient_names: Array[String],
	survived_patient_names: Array[String]
) -> String:
	var text := ""

	if dead_patient_names.size() == 1:
		text += "A semana terminou com esperança, mas não sem perda.\n\n"
	else:
		text += "A semana terminou com sobreviventes, mas também com perdas difíceis de esquecer.\n\n"

	if not survived_patient_names.is_empty():
		text += "Pacientes que sobreviveram:\n"
		for patient_name in survived_patient_names:
			text += "- %s\n" % patient_name
		text += "\n"

	if not dead_patient_names.is_empty():
		if dead_patient_names.size() == 1:
			text += "Paciente que morreu:\n"
		else:
			text += "Pacientes que morreram:\n"

		for patient_name in dead_patient_names:
			text += "- %s\n" % patient_name
		text += "\n"

	if dead_patient_names.size() == 1:
		text += "Uma vida se perdeu, e essa ausência ficará marcada. Ainda assim, nem tudo foi em vão."
	elif dead_patient_names.size() <= survived_patient_names.size():
		text += "Algumas vidas se perderam, mas outras continuaram por causa das escolhas feitas ao longo da semana."
	else:
		text += "Mais vidas se perderam do que foram salvas. Ainda houve sobreviventes, mas a vitória tem gosto amargo."

	return text


static func build_patient_treatment_result_text(patient: Patient, result: Patient.HealthState) -> String:
	match result:
		Patient.HealthState.RECOVERED:
			return "%s se recuperou após a mistura." % patient.patient_name

		Patient.HealthState.STABILIZED:
			return "%s ficou estável. A doença não cedeu por completo, mas consegui afastá-la da beira do abismo." % patient.patient_name

		Patient.HealthState.STABLE:
			return "%s permaneceu estável." % patient.patient_name

		Patient.HealthState.WEAK:
			return "%s ficou debilitado. A mistura não parece ter sido suficiente." % patient.patient_name

		Patient.HealthState.WORSENED:
			return "%s piorou depois do tratamento. Talvez eu tenha confundido os sinais da doença." % patient.patient_name

		Patient.HealthState.CRITICAL:
			return "%s terminou em estado crítico." % patient.patient_name

		Patient.HealthState.DEAD:
			return "%s morreu sob meus cuidados." % patient.patient_name

		_:
			return "%s teve um resultado incerto após o tratamento." % patient.patient_name


static func build_day_summary(
	day_name: String,
	current_day_actions: Array[String],
	current_day_patient_results: Array[String]
) -> String:
	var text := "Diário - %s\n\n" % day_name
	text += "Hoje foi mais um dia pesado durante a peste.\n\n"

	if current_day_actions.is_empty():
		text += "Quase nada pude fazer. O silêncio da casa pesou mais do que os gritos da vila.\n\n"
	else:
		text += "Minhas ações:\n"

		for action in current_day_actions:
			text += "- %s\n" % action

		text += "\n"

	if current_day_patient_results.is_empty():
		text += "Nenhum paciente ficou sob meus cuidados hoje.\n"
	else:
		text += "Sobre os pacientes:\n"

		for result in current_day_patient_results:
			text += "- %s\n" % result

	text += "\nTermino o dia cansado, com as mãos manchadas pelo cheiro das ervas e pela dúvida do que fiz."

	return text