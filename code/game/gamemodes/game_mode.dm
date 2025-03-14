/datum/game_mode
	var/name = "invalid"
	var/round_description = "How did you even vote this in?"
	var/extended_round_description = "This roundtype should not be spawned, let alone votable. Someone contact a developer and tell them the game's broken again."
	var/config_tag = null
	var/votable = 1
	var/probability = 0

	var/required_players = 0                 // Minimum players for round to start if voted in.
	var/required_enemies = 0                 // Minimum antagonists for round to start.
	var/newscaster_announcements = null
	var/end_on_antag_death = 0               // Round will end when all antagonists are dead.
	var/ert_disabled = 0                     // ERT cannot be called.
	var/deny_respawn = 0	                 // Disable respawn during this round.

	var/list/disabled_jobs = list()           // Mostly used for Malf.  This check is performed in job_controller so it doesn't spawn a regular AI.

	var/shuttle_delay_mult = 1                    // Shuttle transit time is multiplied by this.
	var/auto_recall_shuttle = 0              // Will the shuttle automatically be recalled?

	var/list/antag_tags = list()             // Core antag templates to spawn.
	var/list/antag_templates                 // Extra antagonist types to include.
	var/list/latejoin_antag_tags = list()        // Antags that may auto-spawn, latejoin or otherwise come in midround.
	var/round_autoantag = 0                  // Will this round attempt to periodically spawn more antagonists?
	var/antag_scaling_coeff = 5              // Coefficient for scaling max antagonists to player count. How many players for one antag
	var/require_all_templates = 0            // Will only start if all templates are checked and can spawn.

	var/station_was_nuked = 0                // See nuclearbomb.dm and malfunction.dm.
	var/explosion_in_progress = 0            // Sit back and relax

	var/waittime_l = 60 SECONDS				 // Lower bound on time before start of shift report
	var/waittime_h = 180 SECONDS		     // Upper bounds on time before start of shift report

	//Format: list(start_animation = duration, hit_animation, miss_animation). null means animation is skipped.
	var/cinematic_icon_states = list(
		"intro_nuke" = 35,
		"summary_selfdes",
		null
	)

/datum/game_mode/New()
	..()
	// Enforce some formatting.
	// This will probably break something.
	name = capitalize(lowertext(name))
	config_tag = lowertext(config_tag)

	if(round_autoantag && !latejoin_antag_tags.len)
		latejoin_antag_tags = antag_tags.Copy()
	else if(!round_autoantag && latejoin_antag_tags.len)
		round_autoantag = TRUE

/datum/game_mode/Topic(href, href_list[])
	if(!check_rights(R_ADMIN))
		href_exploit(usr.ckey, href)
		return
	if(href_list["toggle"])
		switch(href_list["toggle"])
			if("respawn")
				deny_respawn = !deny_respawn
			if("ert")
				ert_disabled = !ert_disabled
				announce_ert_disabled()
			if("shuttle_recall")
				auto_recall_shuttle = !auto_recall_shuttle
			if("autotraitor")
				round_autoantag = !round_autoantag
		message_admins("Admin [key_name_admin(usr)] toggled game mode option '[href_list["toggle"]]'.")
	else if(href_list["set"])
		var/choice = ""
		switch(href_list["set"])
			if("shuttle_delay")
				choice = input("Enter a new shuttle delay multiplier") as num
				if(!choice || choice < 1 || choice > 20)
					return
				shuttle_delay_mult = choice
			if("antag_scaling")
				choice = input("Enter a new antagonist cap scaling coefficient.") as num
				if(isnull(choice) || choice < 0 || choice > 100)
					return
				antag_scaling_coeff = choice
		message_admins("Admin [key_name_admin(usr)] set game mode option '[href_list["set"]]' to [choice].")
	else if(href_list["debug_antag"])
		if(href_list["debug_antag"] == "self")
			usr.client.debug_variables(src)
			return
		var/datum/antagonist/antag = GLOB.all_antag_types_[href_list["debug_antag"]]
		if(antag)
			usr.client.debug_variables(antag)
			message_admins("Admin [key_name_admin(usr)] is debugging the [antag.role_text] template.")
	else if(href_list["remove_antag_type"])
		if(antag_tags && (href_list["remove_antag_type"] in antag_tags))
			to_chat(usr, "Cannot remove core mode antag type.")
			return
		var/datum/antagonist/antag = GLOB.all_antag_types_[href_list["remove_antag_type"]]
		if(antag_templates && antag_templates.len && antag && (antag in antag_templates))
			antag_templates -= antag
			message_admins("Admin [key_name_admin(usr)] removed [antag.role_text] template from game mode.")
	else if(href_list["add_antag_type"])
		var/choice = input("Which type do you wish to add?") as null|anything in GLOB.all_antag_types_
		if(!choice)
			return
		var/datum/antagonist/antag = GLOB.all_antag_types_[choice]
		if(antag)
			if(!islist(SSticker.mode.antag_templates))
				SSticker.mode.antag_templates = list()
			SSticker.mode.antag_templates |= antag
			message_admins("Admin [key_name_admin(usr)] added [antag.role_text] template to game mode.")

	// I am very sure there's a better way to do this, but I'm not sure what it might be. ~Z
	spawn(1)
		for(var/datum/admins/admin in world)
			if(usr.client == admin.owner)
				admin.show_game_mode(usr)
				return

/datum/game_mode/proc/announce() //to be called when round starts
	to_world("<B>The current game mode is [capitalize(name)]!</B>")
	if(round_description) to_world("[round_description]")
	if(round_autoantag) to_world("Antagonists will be added to the round automagically as needed.")
	if(antag_templates && antag_templates.len)
		var/antag_summary = "<b>Possible antagonist types:</b> "
		var/i = 1
		for(var/datum/antagonist/antag in antag_templates)
			if(i > 1)
				if(i == antag_templates.len)
					antag_summary += " and "
				else
					antag_summary += ", "
			antag_summary += "[antag.role_text_plural]"
			i++
		antag_summary += "."
		if(antag_templates.len > 1 && SSticker.master_mode != "secret")
			to_world("[antag_summary]")
		else
			message_admins("[antag_summary]")

// isStartRequirementsSatisfied()
// Checks to see if the game can be setup and ran with the current number of players or whatnot.
// Returns 0 if the mode can start and a message explaining the reason why it can't otherwise.
/datum/game_mode/proc/isStartRequirementsSatisfied(totalPlayers)
	if(totalPlayers < required_players)
		return FALSE

	var/enemy_count = 0
	var/list/all_antag_types = GLOB.all_antag_types_

	if(antag_tags && antag_tags.len)
		for(var/antag_tag in antag_tags)
			var/datum/antagonist/antag = all_antag_types[antag_tag]
			if(!antag)
				continue
			var/list/potential = list()
			if(antag_templates && antag_templates.len)
				if(antag.flags & ANTAG_OVERRIDE_JOB)
					potential = antag.pending_antagonists
				else
					potential = antag.candidates
			else
				potential = antag.get_potential_candidates(src)
			if(islist(potential))
				if(require_all_templates && potential.len < antag.initial_spawn_req)
					log_debug("Not enough antagonists ([antag.role_text]), [antag.initial_spawn_req] required and [potential.len] available.")
					return FALSE
				enemy_count += potential.len
				if(enemy_count >= required_enemies)
					return TRUE
		log_debug("Not enough antagonists for [name], [required_enemies] required and [enemy_count] available.")
		return FALSE
	else
		return TRUE

/datum/game_mode/proc/pre_setup()
	for(var/datum/antagonist/antag in antag_templates)
		antag.update_current_antag_max(src)
		antag.build_candidate_list(src) //compile a list of all eligible candidates

		//antag roles that replace jobs need to be assigned before the job controller hands out jobs.
		if(antag.flags & ANTAG_OVERRIDE_JOB)
			antag.attempt_spawn() //select antags to be spawned

///post_setup()
/datum/game_mode/proc/post_setup()

	next_spawn = world.time + rand(min_autotraitor_delay, max_autotraitor_delay)

	spawn (ROUNDSTART_LOGOUT_REPORT_TIME)
		display_roundstart_logout_report()

	spawn (rand(waittime_l, waittime_h))
		GLOB.using_map.send_welcome()
		sleep(rand(100,150))
		announce_ert_disabled()

	//Assign all antag types for this game mode. Any players spawned as antags earlier should have been removed from the pending list, so no need to worry about those.
	for(var/datum/antagonist/antag in antag_templates)
		if(!(antag.flags & ANTAG_OVERRIDE_JOB))
			antag.attempt_spawn() //select antags to be spawned
		antag.finalize_spawn() //actually spawn antags

	//Finally do post spawn antagonist stuff.
	for(var/datum/antagonist/antag in antag_templates)
		antag.post_spawn()

	if(evacuation_controller && auto_recall_shuttle)
		evacuation_controller.recall = 1

	feedback_set_details("round_start","[time2text(world.realtime)]")
	if(SSticker.mode)
		feedback_set_details("game_mode","[SSticker.mode]")
	feedback_set_details("server_ip","[world.internet_address]:[world.port]")
	return 1

/datum/game_mode/proc/fail_setup()
	for(var/datum/antagonist/antag in antag_templates)
		antag.reset_antag_selection()

/datum/game_mode/proc/announce_ert_disabled()
	if(!ert_disabled)
		return

	var/list/reasons = list(
		"political instability",
		"quantum fluctuations",
		"hostile raiders",
		"derelict station debris",
		"REDACTED",
		"ancient alien artillery",
		"solar magnetic storms",
		"sentient time-travelling killbots",
		"gravitational anomalies",
		"wormholes to another dimension",
		"a telescience mishap",
		"radiation flares",
		"supermatter dust",
		"leaks into a negative reality",
		"antiparticle clouds",
		"residual bluespace energy",
		"suspected criminal operatives",
		"malfunctioning von Neumann probe swarms",
		"shadowy interlopers",
		"a stranded Vox arkship",
		"haywire IPC constructs",
		"rogue Unathi exiles",
		"artifacts of eldritch horror",
		"a brain slug infestation",
		"killer bugs that lay eggs in the husks of the living",
		"a deserted transport carrying xenomorph specimens",
		"an emissary for the gestalt requesting a security detail",
		"a Tajaran slave rebellion",
		"radical Skrellian transevolutionaries",
		"classified security operations"
		)
	command_announcement.Announce("The presence of [pick(reasons)] in the region is tying up all available local emergency resources; emergency response teams cannot be called at this time, and post-evacuation recovery efforts will be substantially delayed.","Emergency Transmission")

/datum/game_mode/proc/check_finished()
	if(evacuation_controller.round_over() || station_was_nuked)
		return 1
	if(end_on_antag_death && antag_templates && antag_templates.len)
		var/has_antags = 0
		for(var/datum/antagonist/antag in antag_templates)
			if(!antag.antags_are_dead())
				has_antags = 1
				break
		if(!has_antags)
			evacuation_controller.recall = 0
			return 1
	return 0

/datum/game_mode/proc/cleanup()	//This is called when the round has ended but not the game, if any cleanup would be necessary in that case.
	return

/datum/game_mode/proc/special_report()
	return

/datum/game_mode/proc/check_win() //universal trigger to be called at mob death, nuke explosion, etc. To be called from everywhere.
	return 0

/datum/game_mode/proc/get_players_for_role(antag_id)
	var/list/players = list()
	var/list/candidates = list()

	var/list/all_antag_types = GLOB.all_antag_types_
	var/datum/antagonist/antag_template = all_antag_types[antag_id]
	if(!antag_template)
		return candidates

	// If this is being called post-roundstart then it doesn't care about ready status.
	if(GAME_STATE == RUNLEVEL_GAME)
		for(var/mob/player in GLOB.player_list)
			if(!player.client)
				continue
			if(!antag_id || (antag_id in player.client.prefs.be_special_role))
				log_debug("[player.key] had [antag_id] enabled, so we are drafting them.")
				candidates += player.mind
	else
		// Assemble a list of active players without jobbans.
		for(var/mob/new_player/player in GLOB.player_list)
			if( player.client && player.ready )
				players += player

		// Get a list of all the people who want to be the antagonist for this round
		for(var/mob/new_player/player in players)
			if(!antag_id || (antag_id in player.client.prefs.be_special_role))
				log_debug("[player.key] had [antag_id] enabled, so we are drafting them.")
				candidates += player.mind
				players -= player

		// If we don't have enough antags, draft people who voted for the round.
		if(candidates.len < required_enemies)
			for(var/mob/new_player/player in players)
				if(!antag_id || ((antag_id in player.client.prefs.be_special_role) || (antag_id in player.client.prefs.may_be_special_role)))
					log_debug("[player.key] has not selected never for this role, so we are drafting them.")
					candidates += player.mind
					players -= player
					if(candidates.len == required_enemies || players.len == 0)
						break

	return candidates		// Returns: The number of people who had the antagonist role set to yes, regardless of recomended_enemies, if that number is greater than required_enemies
							//			required_enemies if the number of people with that role set to yes is less than recomended_enemies,
							//			Less if there are not enough valid players in the game entirely to make required_enemies.

/datum/game_mode/proc/num_players()
	. = 0
	for(var/mob/new_player/P in GLOB.player_list)
		if(P.client && P.ready)
			. ++

/datum/game_mode/proc/check_antagonists_topic(href, href_list[])
	return 0

/datum/game_mode/proc/create_antagonists()

	if(!config.gamemode.antag_scaling)
		antag_scaling_coeff = 0

	var/list/all_antag_types = GLOB.all_antag_types_
	if(antag_tags && antag_tags.len)
		antag_templates = list()
		for(var/antag_tag in antag_tags)
			var/datum/antagonist/antag = all_antag_types[antag_tag]
			if(antag)
				antag_templates |= antag

	shuffle(antag_templates) //In the case of multiple antag types
	// TODO(rufus): move out of create_antagonists proc to gamemode setup.
	newscaster_announcements = pick(newscaster_standard_feeds)

/datum/game_mode/proc/print_roundend()
	return

// Manipulates the end-game cinematic in conjunction with GLOB.cinematic
/datum/game_mode/proc/nuke_act(obj/screen/cinematic_screen, station_missed = 0)
	if(!cinematic_icon_states)
		return
	if(station_missed < 2)
		var/intro = cinematic_icon_states[1]
		if(intro)
			flick(intro,cinematic_screen)
			sleep(cinematic_icon_states[intro])
		var/end = cinematic_icon_states[3]
		var/to_flick = "station_intact_fade_red"
		if(!station_missed)
			end = cinematic_icon_states[2]
			to_flick = "station_explode_fade_red"
			for(var/mob/living/M in GLOB.living_mob_list_)
				if(is_station_turf(get_turf(M)))
					M.death()//No mercy
		if(end)
			flick(to_flick,cinematic_screen)
			cinematic_screen.icon_state = end

	else
		sleep(50)
	sound_to(world, sound('sound/effects/explosions/explosion23.ogg'))

//////////////////////////
//Reports player logouts//
//////////////////////////
/proc/display_roundstart_logout_report()
	var/msg = "<b>Roundstart logout report</b>\n\n"
	for(var/mob/living/L in SSmobs.mob_list)

		if(L.ckey)
			var/found = 0
			for(var/client/C in GLOB.clients)
				if(C.ckey == L.ckey)
					found = 1
					break
			if(!found)
				msg += "<b>[L.name]</b> ([L.ckey]), the [L.job] (<font color='#ffcc00'><b>Disconnected</b></font>)\n"

		if(L.ckey && L.client)
			if(L.client.inactivity >= (ROUNDSTART_LOGOUT_REPORT_TIME / 2))	//Connected, but inactive (alt+tabbed or something)
				msg += "<b>[L.name]</b> ([L.ckey]), the [L.job] (<font color='#ffcc00'><b>Connected, Inactive</b></font>)\n"
				continue //AFK client
			if(L.stat)
				if(L.stat == UNCONSCIOUS)
					msg += "<b>[L.name]</b> ([L.ckey]), the [L.job] (Dying)\n"
					continue //Unconscious
				if(L.stat == DEAD)
					msg += "<b>[L.name]</b> ([L.ckey]), the [L.job] (Dead)\n"
					continue //Dead

			continue //Happy connected client
		for(var/mob/observer/ghost/D in SSmobs.mob_list)
			var/mob/living/original_mob = D.mind?.original_mob?.resolve()
			if(D.mind && ((istype(original_mob) && original_mob == L) || D.mind.current == L))
				if(L.stat == DEAD)
					msg += "<b>[L.name]</b> ([ckey(D.mind.key)]), the [L.job] (Dead)\n"
					continue //Dead mob, ghost abandoned
				else
					if(D.can_reenter_corpse)
						msg += "<b>[L.name]</b> ([ckey(D.mind.key)]), the [L.job] (<font color='red'><b>Adminghosted</b></font>)\n"
						continue //Lolwhat
					else
						msg += "<b>[L.name]</b> ([ckey(D.mind.key)]), the [L.job] (<font color='red'><b>Ghosted</b></font>)\n"
						continue //Ghosted while alive

	for(var/mob/M in SSmobs.mob_list)
		if(M.client && M.client.holder)
			to_chat(M, SPAN("notice", msg))
/proc/get_nt_opposed()
	var/list/dudes = list()
	for(var/mob/living/carbon/human/man in GLOB.player_list)
		if(man.client)
			if(man.client.prefs.nanotrasen_relation == COMPANY_OPPOSED)
				dudes += man
			else if(man.client.prefs.nanotrasen_relation == COMPANY_SKEPTICAL && prob(50))
				dudes += man
	if(dudes.len == 0) return null
	return pick(dudes)

/proc/show_objectives(datum/mind/player)

	if(!player || !player.current) return

	if(config.gamemode.antag_objectives == CONFIG_ANTAG_OBJECTIVES_NONE || !player.objectives.len)
		return

	var/obj_count = 1
	to_chat(player.current, SPAN("notice", "Your current objectives:"))
	for(var/datum/objective/objective in player.objectives)
		to_chat(player.current, "<B>Objective #[obj_count]</B>: [objective.explanation_text]")
		obj_count++

/mob/verb/check_round_info()
	set name = "Check Round Info"
	set category = "OOC"

	GLOB.using_map.map_info(src)

	if(!SSticker.mode)
		to_chat(usr, "Something is terribly wrong; there is no gametype.")
		return

	if(SSticker.master_mode != "secret")
		to_chat(usr, "<b>The roundtype is [capitalize(SSticker.mode.name)]</b>")
		if(SSticker.mode.round_description)
			to_chat(usr, "<i>[SSticker.mode.round_description]</i>")
		if(SSticker.mode.extended_round_description)
			to_chat(usr, "[SSticker.mode.extended_round_description]")
	else
		to_chat(usr, "<i>Shhhh</i>. It's a secret.")
	return
