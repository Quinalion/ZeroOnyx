/proc/all_predicates_true(list/input, list/predicates)
	predicates = istype(predicates) ? predicates : list(predicates)

	for(var/i = 1 to predicates.len)
		if(istype(input))
			if(!call(predicates[i])(arglist(input)))
				return FALSE
		else
			if(!call(predicates[i])(input))
				return FALSE
	return TRUE

/proc/any_predicate_true(list/input, list/predicates)
	predicates = istype(predicates) ? predicates : list(predicates)
	if(!predicates.len)
		return TRUE

	for(var/i = 1 to predicates.len)
		if(istype(input))
			if(call(predicates[i])(arglist(input)))
				return TRUE
		else
			if(call(predicates[i])(input))
				return TRUE
	return FALSE

/proc/is_atom_predicate(value, feedback_receiver)
	. = isatom(value)
	if(!. && feedback_receiver)
		to_chat(feedback_receiver, SPAN("warning", "Value must be an atom."))

/proc/is_num_predicate(value, feedback_receiver)
	. = isnum(value)
	if(!. && feedback_receiver)
		to_chat(feedback_receiver, SPAN("warning", "Value must be a numeral."))

/proc/is_text_predicate(value, feedback_receiver)
	. = !value || istext(value)
	if(!. && feedback_receiver)
		to_chat(feedback_receiver, SPAN("warning", "Value must be a text."))

/proc/is_dir_predicate(value, feedback_receiver)
	. = (value in GLOB.alldirs)
	if(!. && feedback_receiver)
		to_chat(feedback_receiver, SPAN("warning", "Value must be a direction."))

/proc/can_locate(atom/container, container_thing)
	return (locate(container_thing) in container)

/proc/can_not_locate(atom/container, container_thing)
	return !(locate(container_thing) in container) // We could just do !can_locate(container, container_thing) but BYOND is pretty awful when it comes to deep proc calls


/proc/where(list/list_to_filter, list/predicates, list/extra_predicate_input)
	. = list()
	for(var/entry in list_to_filter)
		var/predicate_input
		if(extra_predicate_input)
			predicate_input = (list(entry) + extra_predicate_input)
		else
			predicate_input = entry

		if(all_predicates_true(predicate_input, predicates))
			. += entry

/proc/map(list/list_to_map, map_proc)
	. = list()
	for(var/entry in list_to_map)
		. += call(map_proc)(entry)
