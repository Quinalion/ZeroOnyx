/////////////////////
// DISABILITY GENES
//
// These activate either a mutation, disability, or sdisability.
//
// Gene is always activated.
/////////////////////

/datum/dna/gene/disability
	name="DISABILITY"

	// Mutation to give (or 0)
	var/mutation=0

	// Disability to give (or 0)
	var/disability=0

	// SDisability to give (or 0)
	var/sdisability=0

	// Activation message
	var/activation_message=""

	// Yay, you're no longer growing 3 arms
	var/deactivation_message=""

/datum/dna/gene/disability/can_activate(mob/M,flags)
	return 1 // Always set!

/datum/dna/gene/disability/activate(mob/M, connected, flags)
	if(mutation && !(mutation in M.mutations))
		M.mutations.Add(mutation)
	if(disability)
		M.disabilities|=disability
	if(sdisability)
		M.sdisabilities|=sdisability
	if(activation_message)
		to_chat(M, SPAN("warning", "[activation_message]"))
	else
		testing("[name] has no activation message.")

/datum/dna/gene/disability/deactivate(mob/M, connected, flags)
	if(mutation && (mutation in M.mutations))
		M.mutations.Remove(mutation)
	if(disability)
		M.disabilities &= (~disability)
	if(sdisability)
		M.sdisabilities &= (~sdisability)
	if(deactivation_message)
		to_chat(M, SPAN("warning", "[deactivation_message]"))
	else
		testing("[name] has no deactivation message.")

// Note: Doesn't seem to do squat, at the moment.
/datum/dna/gene/disability/hallucinate
	name="Hallucinate"
	activation_message="Your mind says 'Hello'."
	mutation=mHallucination

/datum/dna/gene/disability/hallucinate/New()
	block=GLOB.HALLUCINATIONBLOCK

/datum/dna/gene/disability/epilepsy
	name="Epilepsy"
	activation_message="You get a headache."
	disability=EPILEPSY

/datum/dna/gene/disability/epilepsy/New()
	block=GLOB.HEADACHEBLOCK

/datum/dna/gene/disability/cough
	name="Coughing"
	activation_message="You start coughing."
	disability=COUGHING

/datum/dna/gene/disability/cough/New()
	block=GLOB.COUGHBLOCK

/datum/dna/gene/disability/clumsy
	name="Clumsiness"
	activation_message="You feel lightheaded."
	mutation=MUTATION_CLUMSY

/datum/dna/gene/disability/clumsy/New()
	block=GLOB.CLUMSYBLOCK

/datum/dna/gene/disability/tourettes
	name="Tourettes"
	activation_message="You twitch."
	disability=TOURETTES

/datum/dna/gene/disability/tourettes/New()
	block=GLOB.TWITCHBLOCK

/datum/dna/gene/disability/nervousness
	name="Nervousness"
	activation_message="You feel nervous."
	disability=NERVOUS

/datum/dna/gene/disability/nervousness/New()
	block=GLOB.NERVOUSBLOCK

/datum/dna/gene/disability/blindness
	name="Blindness"
	activation_message="You can't seem to see anything."
	sdisability=BLIND

/datum/dna/gene/disability/blindness/New()
	block=GLOB.BLINDBLOCK

/datum/dna/gene/disability/deaf
	name="Deafness"
	activation_message="It's kinda quiet."
	sdisability=DEAF

/datum/dna/gene/disability/deaf/New()
	block=GLOB.DEAFBLOCK

/datum/dna/gene/disability/deaf/activate(mob/M, connected, flags)
	..(M,connected,flags)
	M.ear_deaf = 1

/datum/dna/gene/disability/nearsighted
	name="Nearsightedness"
	activation_message="Your eyes feel weird..."
	disability=NEARSIGHTED

/datum/dna/gene/disability/nearsighted/New()
	block=GLOB.GLASSESBLOCK
