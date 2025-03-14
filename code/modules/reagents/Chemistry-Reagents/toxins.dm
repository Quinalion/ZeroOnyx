/* Toxins, poisons, venoms */

/datum/reagent/toxin
	name = "Toxin"
	description = "A toxic chemical."
	taste_description = "bitterness"
	taste_mult = 1.2
	reagent_state = LIQUID
	color = "#cf3600"
	metabolism = REM * 0.25 // 0.05 by default. They last a while and slowly kill you.

	var/target_organ
	var/strength = 4 // How much damage it deals per unit

/datum/reagent/toxin/affect_blood(mob/living/carbon/M, alien, removed)
	if(strength && alien != IS_DIONA)
		M.add_chemical_effect(CE_TOXIN, strength)
		var/dam = (strength * removed)
		if(target_organ && ishuman(M))
			var/mob/living/carbon/human/H = M
			var/obj/item/organ/internal/I = H.internal_organs_by_name[target_organ]
			if(I)
				var/can_damage = I.max_damage - I.damage
				if(can_damage > 0)
					if(dam > can_damage)
						I.take_internal_damage(can_damage, silent=TRUE)
						dam -= can_damage
					else
						I.take_internal_damage(dam, silent=TRUE)
						dam = 0
		if(dam)
			M.adjustToxLoss(target_organ ? (dam * 0.75) : dam)

/datum/reagent/toxin/plasticide
	name = "Plasticide"
	description = "Liquid plastic, do not eat."
	taste_description = "plastic"
	reagent_state = LIQUID
	color = "#cf3600"
	strength = 5

/datum/reagent/toxin/amatoxin
	name = "Amatoxin"
	description = "A powerful poison derived from certain species of mushroom."
	taste_description = "mushroom"
	reagent_state = LIQUID
	color = "#792300"
	strength = 10

/datum/reagent/toxin/carpotoxin
	name = "Carpotoxin"
	description = "A deadly neurotoxin produced by the dreaded space carp."
	taste_description = "fish"
	reagent_state = LIQUID
	color = "#003333"
	target_organ = BP_BRAIN
	strength = 10

/datum/reagent/toxin/plasma
	name = "Plasma"
	description = "Plasma in its liquid form."
	taste_mult = 1.5
	reagent_state = LIQUID
	color = "#e90eb8"
	strength = 30
	touch_met = 5
	var/fire_mult = 5

/datum/reagent/toxin/chlorine
	name = "Chlorine"
	description = "A highly poisonous liquid. Smells strongly of bleach."
	reagent_state = LIQUID
	taste_description = "bleach"
	color = "#707C13"
	strength = 15
	metabolism = REM

/datum/reagent/toxin/plasma/touch_mob(mob/living/L, amount)
	if(istype(L))
		L.adjust_fire_stacks(amount / fire_mult)

/datum/reagent/toxin/plasma/affect_blood(mob/living/carbon/M, alien, removed)
	if(alien == IS_NABBER)
		return
	..()

/datum/reagent/toxin/plasma/affect_touch(mob/living/carbon/M, alien, removed)
	M.take_organ_damage(0, removed * 0.1) //being splashed directly with plasma causes minor chemical burns
	if(prob(10 * fire_mult))
		M.pl_effects()

/datum/reagent/toxin/plasma/touch_turf(turf/simulated/T)
	if(!istype(T))
		return
	T.assume_gas("plasma", volume, 20 CELSIUS)
	remove_self(volume)

// Produced during deuterium synthesis. Super poisonous, SUPER flammable (doesn't need oxygen to burn).
/datum/reagent/toxin/plasma/oxygen
	name = "Plasmygen"
	description = "An exceptionally flammable molecule formed from deuterium synthesis."
	strength = 15
	fire_mult = 15

/datum/reagent/toxin/plasma/oxygen/touch_turf(turf/simulated/T)
	if(!istype(T))
		return
	T.assume_gas("oxygen", ceil(volume/2), 20 CELSIUS)
	T.assume_gas("plasma", ceil(volume/2), 20 CELSIUS)
	remove_self(volume)

/datum/reagent/toxin/cyanide //Fast and Lethal
	name = "Cyanide"
	description = "A highly toxic chemical."
	taste_mult = 0.6
	reagent_state = LIQUID
	color = "#cf3600"
	strength = 20
	metabolism = REM * 0.5
	target_organ = BP_HEART

/datum/reagent/toxin/cyanide/affect_blood(mob/living/carbon/M, alien, removed)
	..()

/datum/reagent/toxin/potassium_chloride
	name = "Potassium Chloride"
	description = "A delicious salt that stops the heart when injected into cardiac muscle."
	taste_description = "salt"
	reagent_state = SOLID
	color = "#ffffff"
	strength = 0
	overdose = REAGENTS_OVERDOSE

/datum/reagent/toxin/potassium_chloride/overdose(mob/living/carbon/M, alien)
	..()
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(H.stat != 1)
			if(H.losebreath >= 10)
				H.losebreath = max(10, H.losebreath - 10)
			H.adjustOxyLoss(2)
			H.Weaken(10)
			H.Stun(10)
		M.add_chemical_effect(CE_NOPULSE, 1)


/datum/reagent/toxin/potassium_chlorophoride
	name = "Potassium Chlorophoride"
	description = "A specific chemical based on Potassium Chloride to stop the heart for surgery. Not safe to eat!"
	taste_description = "salt"
	reagent_state = SOLID
	color = "#ffffff"
	strength = 10
	overdose = 20
	metabolism = REM * 0.5
	absorbability = 0.75

/datum/reagent/toxin/potassium_chlorophoride/affect_blood(mob/living/carbon/M, alien, removed, affecting_dose)
	..()
	if(affecting_dose < 1)
		if(M.chem_doses[type] == metabolism)
			to_chat(M, SPAN("danger", "You can feel your heart going numb!"))
		return
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(H.stat != 1)
			if(H.losebreath >= 10)
				H.losebreath = max(10, M.losebreath-10)
			H.adjustOxyLoss(2)
			H.Weaken(10)
			H.Stun(10)
		M.add_chemical_effect(CE_NOPULSE, 1)

/datum/reagent/toxin/zombiepowder
	name = "Zombie Powder"
	description = "A strong neurotoxin that puts the subject into a death-like state."
	taste_description = "death"
	reagent_state = SOLID
	color = "#669900"
	metabolism = REM
	strength = 3
	target_organ = BP_BRAIN

/datum/reagent/toxin/zombiepowder/affect_blood(mob/living/carbon/M, alien, removed)
	..()
	if(alien == IS_DIONA)
		return
	M.status_flags |= FAKEDEATH
	M.adjustOxyLoss(3 * removed)
	M.Weaken(10)
	M.Stun(10)
	M.silent = max(M.silent, 10)
	if(M.chem_doses[type] <= removed) //half-assed attempt to make timeofdeath update only at the onset
		M.timeofdeath = world.time
	M.add_chemical_effect(CE_NOPULSE, 1)

/datum/reagent/toxin/zombiepowder/Destroy()
	if(holder && holder.my_atom && ismob(holder.my_atom))
		var/mob/M = holder.my_atom
		M.status_flags &= ~FAKEDEATH
	. = ..()

/datum/reagent/toxin/fertilizer //Reagents used for plant fertilizers.
	name = "Fertilizer"
	description = "A chemical mix good for growing plants with."
	taste_description = "plant food"
	taste_mult = 0.5
	reagent_state = LIQUID
	strength = 0.5 // It's not THAT poisonous.
	color = "#664330"

/datum/reagent/toxin/fertilizer/eznutrient
	name = "EZ Nutrient"

/datum/reagent/toxin/fertilizer/left4zed
	name = "Left-4-Zed"
	color = "#515130"

/datum/reagent/toxin/fertilizer/robustharvest
	name = "Robust Harvest"
	taste_description = "robust plant food"
	color = "#4e204b"

/datum/reagent/toxin/fertilizer/compost
	name = "compost"
	taste_description = "literal shit"
	taste_mult = 1.0
	color = "#7f4323"

/datum/reagent/toxin/plantbgone
	name = "Plant-B-Gone"
	description = "A harmful toxic mixture to kill plantlife. Do not ingest!"
	taste_mult = 1
	reagent_state = LIQUID
	color = "#49002e"
	strength = 4

/datum/reagent/toxin/plantbgone/touch_turf(turf/T)
	if(istype(T, /turf/simulated/wall))
		var/turf/simulated/wall/W = T
		if(locate(/obj/effect/overlay/wallrot) in W)
			for(var/obj/effect/overlay/wallrot/E in W)
				qdel(E)
			W.visible_message(SPAN("notice", "The fungi are completely dissolved by the solution!"))

/datum/reagent/toxin/plantbgone/touch_obj(obj/O, volume)
	if(istype(O, /obj/effect/vine))
		qdel(O)

/datum/reagent/toxin/plantbgone/affect_blood(mob/living/carbon/M, alien, removed)
	..()
	if(alien == IS_DIONA)
		M.adjustToxLoss(50 * removed)

/datum/reagent/toxin/plantbgone/affect_touch(mob/living/carbon/M, alien, removed)
	..()
	if(alien == IS_DIONA)
		M.adjustToxLoss(50 * removed)

/datum/reagent/acid/polyacid
	name = "Polytrinic acid"
	description = "Polytrinic acid is a an extremely corrosive chemical substance."
	taste_description = "acid"
	reagent_state = LIQUID
	color = "#8e18a9"
	power = 10
	meltdose = 4

/datum/reagent/acid/stomach
	name = "stomach acid"
	taste_description = "coppery foulness"
	power = 1
	color = "#d8ff00"

/datum/reagent/lexorin
	name = "Lexorin"
	description = "Lexorin temporarily stops respiration. Causes tissue damage."
	taste_description = "acid"
	reagent_state = LIQUID
	color = "#c8a5dc"
	overdose = REAGENTS_OVERDOSE

/datum/reagent/lexorin/affect_blood(mob/living/carbon/M, alien, removed)
	if(alien == IS_DIONA)
		return
	if(alien == IS_SKRELL)
		M.take_organ_damage(2.4 * removed, 0)
		if(M.losebreath < 22.5)
			M.losebreath++
	else
		M.take_organ_damage(3 * removed, 0)
		if(M.losebreath < 15)
			M.losebreath++

/datum/reagent/mutagen
	name = "Unstable mutagen"
	description = "Might cause unpredictable mutations. Keep away from children."
	taste_description = "metroid"
	taste_mult = 0.9
	reagent_state = LIQUID
	color = "#13bc5e"
	var/mutation_potency = 0.1 // Determines the probability of causing mutations

/datum/reagent/mutagen/affect_touch(mob/living/carbon/M, alien, removed)
	if(prob(33))
		affect_blood(M, alien, removed)

/datum/reagent/mutagen/affect_ingest(mob/living/carbon/M, alien, removed)
	if(prob(67))
		affect_blood(M, alien, removed)

/datum/reagent/mutagen/affect_blood(mob/living/carbon/M, alien, removed)

	if(M.isSynthetic())
		return

	var/mob/living/carbon/human/H = M
	if(istype(H) && (H.species.species_flags & SPECIES_FLAG_NO_SCAN))
		return

	if(M.dna)
		if(prob(removed * mutation_potency)) // Approx. one mutation per 10 injected/20 ingested/30 touching units
			randmuti(M)
			if(prob(98))
				randmutb(M)
			else
				randmutg(M)
			domutcheck(M, null)
			M.UpdateAppearance()
	M.radiation += (0.05 SIEVERT) * removed

/datum/reagent/mutagen/industrial
	name = "Industrial mutagen"
	description = "A rather stable form of mutagen usually used for agricultural purposes. However, it's still extremely poisonous."
	taste_mult = 0.7
	color = "#4d9e6c"
	mutation_potency = 0.025

/datum/reagent/metroidjelly
	name = "Metroid Jelly"
	description = "A gooey semi-liquid produced from one of the deadliest lifeforms in existence. SO REAL."
	taste_description = "slime"
	taste_mult = 1.3
	reagent_state = LIQUID
	color = "#801e28"

/datum/reagent/metroidjelly/affect_blood(mob/living/carbon/M, alien, removed)
	if(alien == IS_DIONA)
		return
	if(prob(10))
		to_chat(M, SPAN("danger", "Your insides are burning!"))
		M.adjustToxLoss(rand(100, 300) * removed)
	else if(prob(40))
		M.heal_organ_damage(25 * removed, 0)

/datum/reagent/soporific
	name = "Soporific"
	description = "An effective hypnotic used to treat insomnia."
	taste_description = "bitterness"
	reagent_state = LIQUID
	color = "#009ca8"
	metabolism = REM * 0.5
	overdose = REAGENTS_OVERDOSE
	absorbability = 0.75

/datum/reagent/soporific/affect_blood(mob/living/carbon/M, alien, removed, affecting_dose)
	if(alien == IS_DIONA)
		return

	var/threshold = metabolism / removed
	if(alien == IS_SKRELL)
		threshold *= 1.2

	if(affecting_dose < threshold)
		if(affecting_dose == metabolism * 2 || prob(5))
			M.emote("yawn")
	else if(affecting_dose < threshold * 1.5)
		M.eye_blurry = max(M.eye_blurry, 10)
	else if(affecting_dose < threshold * 5)
		if(prob(50))
			M.Weaken(2)
		M.drowsyness = max(M.drowsyness, 20)
	else
		M.sleeping = max(M.sleeping, 20)
		M.drowsyness = max(M.drowsyness, 60)
	M.add_chemical_effect(CE_PULSE, -1)

/datum/reagent/chloralhydrate
	name = "Chloral Hydrate"
	description = "A powerful sedative."
	taste_description = "bitterness"
	reagent_state = SOLID
	color = "#000067"
	metabolism = REM * 0.5
	overdose = REAGENTS_OVERDOSE * 0.5
	absorbability = 0.75

/datum/reagent/chloralhydrate/affect_blood(mob/living/carbon/M, alien, removed, affecting_dose)
	if(alien == IS_DIONA)
		return

	var/threshold = metabolism / removed
	if(alien == IS_SKRELL)
		threshold *= 1.2

	if(affecting_dose < threshold * 0.5)
		M.confused += 2
		M.drowsyness += 2
	else if(affecting_dose < threshold * 2)
		M.Weaken(30)
		M.eye_blurry = max(M.eye_blurry, 10)
	else
		M.sleeping = max(M.sleeping, 30)

	if(affecting_dose > threshold)
		M.adjustToxLoss(removed)

/datum/reagent/chloralhydrate/beer2 //disguised as normal beer for use by emagged brobots
	name = "Beer"
	description = "An alcoholic beverage made from malted grains, hops, yeast, and water. The fermentation appears to be incomplete." //If the players manage to analyze this, they deserve to know something is wrong.
	taste_description = "shitty piss water"
	reagent_state = LIQUID
	color = "#ffd300"
	absorbability = 1.0 // SpEcIaL ingestible chloralhydrate

	glass_name = "beer"
	glass_desc = "A freezing pint of beer"
/* Drugs */

/datum/reagent/space_drugs
	name = "Space Drugs"
	description = "An illegal chemical compound used as drug."
	taste_description = "bitterness"
	taste_mult = 0.4
	reagent_state = LIQUID
	color = "#60a584"
	metabolism = REM * 0.5
	overdose = REAGENTS_OVERDOSE

/datum/reagent/space_drugs/affect_blood(mob/living/carbon/M, alien, removed)
	if(alien == IS_DIONA)
		return

	var/effect_mult = removed / metabolism
	if(alien == IS_SKRELL)
		effect_mult *= 0.8

	M.druggy = max(M.druggy, 15 * effect_mult)
	if(prob(10))
		M.SelfMove(pick(GLOB.cardinal))
	if(prob(7))
		M.emote(pick("twitch", "drool", "moan", "giggle"))
	M.add_chemical_effect(CE_PULSE, -1)

/datum/reagent/serotrotium
	name = "Serotrotium"
	description = "A chemical compound that promotes concentrated production of the serotonin neurotransmitter in humans."
	taste_description = "bitterness"
	reagent_state = LIQUID
	color = "#202040"
	metabolism = REM * 0.25
	overdose = REAGENTS_OVERDOSE

/datum/reagent/serotrotium/affect_blood(mob/living/carbon/M, alien, removed)
	if(alien == IS_DIONA)
		return
	if(prob(7))
		M.emote(pick("twitch", "drool", "moan", "gasp"))
	return

/datum/reagent/cryptobiolin
	name = "Cryptobiolin"
	description = "Cryptobiolin causes confusion and dizzyness."
	taste_description = "sourness"
	reagent_state = LIQUID
	color = "#000055"
	metabolism = REM * 0.5
	overdose = REAGENTS_OVERDOSE

/datum/reagent/cryptobiolin/affect_blood(mob/living/carbon/M, alien, removed)
	if(alien == IS_DIONA)
		return
	var/effect_mult = removed / metabolism
	if(alien == IS_SKRELL)
		effect_mult *= 0.8
	M.make_dizzy(4 * effect_mult)
	M.confused = max(M.confused, 5 * effect_mult)

/datum/reagent/impedrezene
	name = "Impedrezene"
	description = "Impedrezene is a narcotic that impedes one's ability by slowing down the higher brain cell functions."
	taste_description = "numbness"
	reagent_state = LIQUID
	color = "#c8a5dc"
	overdose = REAGENTS_OVERDOSE

/datum/reagent/impedrezene/affect_blood(mob/living/carbon/M, alien, removed)
	if(alien == IS_DIONA)
		return
	var/effect_mult = removed / metabolism
	M.jitteriness = max(M.jitteriness - (5 * effect_mult), 0)
	if(prob(80))
		M.adjustBrainLoss(0.1 * removed)
	if(prob(50))
		M.drowsyness = max(M.drowsyness, 3)
	if(prob(10))
		M.emote("drool")

/datum/reagent/mindbreaker
	name = "Mindbreaker Toxin"
	description = "A powerful hallucinogen, it can cause fatal effects in users."
	taste_description = "sourness"
	reagent_state = LIQUID
	color = "#b31008"
	metabolism = REM * 0.25
	overdose = REAGENTS_OVERDOSE

/datum/reagent/mindbreaker/affect_blood(mob/living/carbon/M, alien, removed)
	if(alien == IS_DIONA)
		return
	M.add_chemical_effect(CE_MIND, -2)
	var/effect_mult = removed / metabolism
	if(alien == IS_SKRELL)
		M.hallucination(25 * effect_mult, 30 * effect_mult)
	else
		M.hallucination(25 * effect_mult, 25 * effect_mult)

/datum/reagent/psilocybin
	name = "Psilocybin"
	description = "A strong psycotropic derived from certain species of mushroom."
	taste_description = "mushroom"
	color = "#e700e7"
	overdose = REAGENTS_OVERDOSE
	metabolism = REM * 0.5
	absorbability = 0.75

/datum/reagent/psilocybin/affect_blood(mob/living/carbon/M, alien, removed, affecting_dose)
	if(alien == IS_DIONA)
		return

	var/threshold = 1
	if(alien == IS_SKRELL)
		threshold = 1.2

	var/effect_mult = removed / metabolism
	if(affecting_dose < 1 * threshold)
		M.apply_effect(3, STUTTER)
		M.make_dizzy(5 * effect_mult)
		M.druggy = max(M.druggy, 30 * effect_mult)
		if(prob(5))
			M.emote(pick("twitch", "giggle"))
	else if(affecting_dose < 2 * threshold)
		M.apply_effect(3, STUTTER)
		M.make_jittery(5 * effect_mult)
		M.make_dizzy(5 * effect_mult)
		M.druggy = max(M.druggy, 35 * effect_mult)
		if(prob(10))
			M.emote(pick("twitch", "giggle"))
	else
		M.add_chemical_effect(CE_MIND, -1)
		M.apply_effect(3, STUTTER)
		M.make_jittery(10 * effect_mult)
		M.make_dizzy(10 * effect_mult)
		M.druggy = max(M.druggy, 40 * effect_mult)
		if(prob(15))
			M.emote(pick("twitch", "giggle"))

/* Transformations */

/datum/reagent/metroidtoxin
	name = "Mutation Toxin"
	description = "A corruptive toxin produced by metroids."
	taste_description = "sludge"
	reagent_state = LIQUID
	color = "#13bc5e"
	metabolism = REM * 0.4

/datum/reagent/metroidtoxin/affect_blood(mob/living/carbon/human/H, alien, removed)
	if(!istype(H))
		return
	if(H.species.name == SPECIES_PROMETHEAN)
		return
	H.adjustToxLoss(20 * removed)
	if(H.chem_doses[type] < 0.5 || prob(30))
		return
	H.chem_doses[type] = 0
	var/list/meatchunks = list()
	for(var/limb_tag in list(BP_R_ARM, BP_L_ARM, BP_R_LEG,BP_L_LEG))
		var/obj/item/organ/external/E = H.get_organ(limb_tag)
		if(!E.is_stump() && !BP_IS_ROBOTIC(E) && E.species.name != SPECIES_PROMETHEAN)
			meatchunks += E
	if(!meatchunks.len)
		if(prob(15))
			to_chat(H, SPAN("danger", "Your flesh rapidly mutates!"))
			H.set_species(SPECIES_PROMETHEAN)
			H.shapeshifter_set_colour("#05ff9b")
			H.verbs -= /mob/living/carbon/human/proc/shapeshifter_select_colour
		return
	var/obj/item/organ/external/O = pick(meatchunks)
	to_chat(H, SPAN("danger", "Your [O.name]'s flesh mutates rapidly!"))
	if(!wrapped_species_by_ref["\ref[H]"])
		wrapped_species_by_ref["\ref[H]"] = H.species.name
	meatchunks = list(O) | O.children
	for(var/obj/item/organ/external/E in meatchunks)
		E.species = all_species[SPECIES_PROMETHEAN]
		E.s_tone = null
		E.s_col = ReadRGB("#05ff9b")
		E.s_col_blend = ICON_ADD
		E.mend_fracture()
		E.status |= ORGAN_MUTATED
		E.limb_flags &= ~ORGAN_FLAG_CAN_BREAK
		E.dislocated = -1
		E.max_damage = 5
		E.update_icon(1)
	O.max_damage = 15
	if(prob(10))
		to_chat(H, SPAN("danger", "Your slimy [O.name] plops off!"))
		O.droplimb()
	H.update_body()

/datum/reagent/ametroidtoxin
	name = "Advanced Mutation Toxin"
	description = "An advanced corruptive toxin produced by metroids."
	taste_description = "sludge"
	reagent_state = LIQUID
	color = "#13bc5e"

/datum/reagent/ametroidtoxin/affect_blood(mob/living/carbon/M, alien, removed) // TODO: check if there's similar code anywhere else
	if(HAS_TRANSFORMATION_MOVEMENT_HANDLER(M))
		return
	to_chat(M, SPAN("danger", "Your flesh rapidly mutates!"))
	ADD_TRANSFORMATION_MOVEMENT_HANDLER(M)
	M.icon = null
	M.overlays.Cut()
	M.set_invisibility(101)
	for(var/obj/item/I in M)
		if(istype(I, /obj/item/implant)) //TODO: Carn. give implants a dropped() or something
			qdel(I)
			continue
		M.drop(I, force = TRUE)
	var/mob/living/carbon/metroid/new_mob = new /mob/living/carbon/metroid(M.loc)
	new_mob.a_intent = "hurt"
	new_mob.universal_speak = 1
	if(M.mind)
		M.mind.transfer_to(new_mob)
	else
		new_mob.key = M.key
	qdel(M)

/datum/reagent/nanites
	name = "Nanomachines"
	description = "Microscopic construction robots."
	taste_description = "metroidy metal"
	reagent_state = LIQUID
	color = "#535e66"
	overdose = 5

/datum/reagent/nanites/affect_blood(mob/living/carbon/M, alien, removed)
	if(alien != IS_DIONA)
		M.heal_organ_damage(15 * removed, 15 * removed)
		M.add_chemical_effect(CE_OXYGENATED, 2)

/datum/reagent/nanites/affect_ingest(mob/living/carbon/M, alien, removed)
	affect_blood(M, alien, removed)

/datum/reagent/nanites/overdose(mob/living/carbon/M, alien)
	if(prob(80))
		if(prob(50))
			var/msg = pick("clicking","clanking","beeping","buzzing","pinging")
			to_chat(M, SPAN("warning", "You can feel something [msg] inside of you!"))
	else
		if(istype(M, /mob/living/carbon/human))
			var/mob/living/carbon/human/H = M
			if(job_master)
				var/datum/job/cyborg/cj = job_master.occupations_by_type[/datum/job/cyborg]
				if(jobban_isbanned(H, cj.title))
					to_chat(H, SPAN_WARNING("You feel that something is broken inside."))
					H.gib()
					return
			H.Robotize()

/datum/reagent/xenomicrobes
	name = "Xenomicrobes"
	description = "Microbes with an entirely alien cellular structure."
	taste_description = "sludge"
	reagent_state = LIQUID
	color = "#535e66"

/datum/reagent/toxin/hair_remover
	name = "Hair Remover"
	description = "An extremely effective chemical depilator. Do not ingest."
	taste_description = "acid"
	reagent_state = LIQUID
	color = "#d9ffb3"
	strength = 1
	overdose = REAGENTS_OVERDOSE

/datum/reagent/toxin/hair_remover/affect_touch(mob/living/carbon/human/M, alien, removed)
	if(alien == IS_SKRELL)	//skrell can't have hair unless you hack it in, also to prevent tentacles from falling off
		return
	M.species.set_default_hair(M)
	to_chat(M, SPAN("warning", "Your feel a chill, your skin feels lighter.."))
	remove_self(volume)

/datum/reagent/toxin/zombie
	name = "Liquid Corruption"
	description = "A filthy, oily substance which slowly churns of its own accord."
	taste_description = "decaying blood"
	color = "#800000"
	taste_mult = 5
	strength = 10
	metabolism = REM * 5
	overdose = 30
	var/amount_to_zombify = 5

/datum/reagent/toxin/zombie/affect_touch(mob/living/carbon/M, alien, removed)
	affect_blood(M, alien, removed * 0.5)

/datum/reagent/toxin/zombie/affect_blood(mob/living/carbon/M, alien, removed)
	..()
	if (ishuman(M))
		var/mob/living/carbon/human/H = M
		var/true_dose = H.chem_traces[type] + volume
		if ((true_dose >= amount_to_zombify) || (true_dose > 1 && prob(20)))
			H.zombify()
		else if (prob(10))
			to_chat(H, SPAN("warning", "You feel terribly ill!"))

/datum/reagent/vecuronium_bromide
	name = "Vecuronium Bromide"
	description = "A general anaesthetic, provides prolonged paralysis without unconsciousness or pain relief."
	taste_description = "bitterness"
	reagent_state = LIQUID
	color = "#cccccc"

/datum/reagent/vecuronium_bromide/affect_blood(mob/living/carbon/M, alien, removed)
	if(alien == IS_DIONA)
		return

	var/threshold = 2
	if(alien == IS_SKRELL)
		threshold = 2.4

	if(M.chem_doses[type] >= metabolism * threshold * 0.5)
		M.confused = max(M.confused, 2)
		M.add_chemical_effect(CE_VOICELOSS, 1)
	if(M.chem_doses[type] > threshold * 0.5)
		M.make_dizzy(3)
		M.Weaken(2)
		M.Stun(2)
	if(M.chem_doses[type] == round(threshold * 0.5, metabolism))
		to_chat(M, SPAN_WARNING("Your muscles slacken and cease to obey you."))
	if(M.chem_doses[type] >= threshold)
		M.add_chemical_effect(CE_SEDATE, 1)
		M.eye_blurry = max(M.eye_blurry, 10)

	if(M.chem_doses[type] > 1 * threshold)
		M.adjustToxLoss(removed)
