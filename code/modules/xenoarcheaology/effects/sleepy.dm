//todo
/datum/artifact_effect/sleepy
	name = "sleepy"

/datum/artifact_effect/sleepy/New()
	..()
	effect_type = pick(EFFECT_PSIONIC, EFFECT_ORGANIC)

/datum/artifact_effect/sleepy/DoEffectTouch(mob/toucher)
	if(toucher)
		var/weakness = GetAnomalySusceptibility(toucher)
		if(ishuman(toucher) && prob(weakness * 100))
			var/mob/living/carbon/human/H = toucher
			to_chat(H, pick(SPAN("notice", "You feel like taking a nap."),SPAN("notice", "You feel a yawn coming on."),SPAN("notice", "You feel a little tired.")))
			H.drowsyness = min(H.drowsyness + rand(5,25) * weakness, 50 * weakness)
			H.eye_blurry = min(H.eye_blurry + rand(1,3) * weakness, 50 * weakness)
			return 1
		else if(isrobot(toucher))
			to_chat(toucher, SPAN("warning", "SYSTEM ALERT: CPU cycles slowing down."))
			return 1

/datum/artifact_effect/sleepy/DoEffectAura()
	if(holder)
		var/turf/T = get_turf(holder)
		for (var/mob/living/carbon/human/H in range(src.effectrange,T))
			var/weakness = GetAnomalySusceptibility(H)
			if(prob(weakness * 100))
				if(prob(10))
					to_chat(H, pick(SPAN("notice", "You feel like taking a nap."),SPAN("notice", "You feel a yawn coming on."),SPAN("notice", "You feel a little tired.")))
				H.drowsyness = min(H.drowsyness + 1 * weakness, 25 * weakness)
				H.eye_blurry = min(H.eye_blurry + 1 * weakness, 25 * weakness)
		for (var/mob/living/silicon/robot/R in range(src.effectrange,holder))
			to_chat(R, SPAN("warning", "SYSTEM ALERT: CPU cycles slowing down."))
		return 1

/datum/artifact_effect/sleepy/DoEffectPulse()
	if(holder)
		var/turf/T = get_turf(holder)
		for(var/mob/living/carbon/human/H in range(src.effectrange, T))
			var/weakness = GetAnomalySusceptibility(H)
			if(prob(weakness * 100))
				to_chat(H, pick(SPAN("notice", "You feel like taking a nap."),SPAN("notice", "You feel a yawn coming on."),SPAN("notice", "You feel a little tired.")))
				H.drowsyness = min(H.drowsyness + rand(5,15) * weakness, 50 * weakness)
				H.eye_blurry = min(H.eye_blurry + rand(5,15) * weakness, 50 * weakness)
		for (var/mob/living/silicon/robot/R in range(src.effectrange,holder))
			to_chat(R, SPAN("warning", "SYSTEM ALERT: CPU cycles slowing down."))
		return 1
