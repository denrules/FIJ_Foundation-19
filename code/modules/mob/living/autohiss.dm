#define AUTOHISS_NUM 3


/mob/living/proc/handle_autohiss(message, datum/language/L)
	return message // no autohiss at this level

/mob/living/carbon/human/handle_autohiss(message, datum/language/L)
	if(!client || get_preference_value(/datum/client_preference/autohiss) == GLOB.PREF_OFF) // no need to process if there's no client or they have autohiss off
		return message
	return species.handle_autohiss(message, L, get_preference_value(/datum/client_preference/autohiss))

/datum/species
	var/list/autohiss_basic_map = null
	var/list/autohiss_extra_map = null
	var/list/autohiss_exempt = null

/datum/species/unathi
	autohiss_basic_map = list(
			"s" = list("ss", "sss", "ssss"),
			"с" = list("сс", "ссс", "сссс")
		)
	autohiss_extra_map = list(
			"x" = list("ks", "kss", "ksss"),
			"ш" = list("шш", "шшш", "шшшш"),
			"ч" = list("щ", "щщ", "щщщ")
		)
	autohiss_exempt = list(
					LANGUAGE_UNATHI_SINTA,
					LANGUAGE_UNATHI_YEOSA
	)

/datum/species/tajaran
	autohiss_basic_map = list(
			"r" = list("rr", "rrr", "rrrr"),
			"р" = list("рр", "ррр", "рррр")
		)

/datum/species/vulpkanin
	autohiss_basic_map = list(
			"r" = list("r", "rr", "rrr"),
			"р" = list("р", "рр", "ррр")
		)
	autohiss_exempt = list("Canilunzt")

/datum/species/vox
	autohiss_basic_map = list(
			"ch" = list("ch", "chch", "chich"),
			"k" = list("k", "kk", "kik"),
			"ч" = list("ч", "чч", "чич"),
			"к" = list("к", "кк", "кик")
		)
	autohiss_exempt = list("Vox-pidgin")

/datum/species/plasmaman
	autohiss_basic_map = list(
			"s" = list("ss", "sss", "ssss"),
			"с" = list("сс", "ссс", "сссс")
		)
/datum/species/kidan
	autohiss_basic_map = list(
			"z" = list("zz", "zzz", "zzzz"),
			"v" = list("vv", "vvv", "vvvv"),
			"з" = list("зз", "ззз", "зззз"),
			"в" = list("вв", "ввв", "вввв")
		)
	autohiss_extra_map = list(
			"s" = list("z", "zs", "zzz", "zzsz"),
			"с" = list("з", "зс", "ззз", "ззсз")
		)
	autohiss_exempt = list("Chittin")

/datum/species/drask
	autohiss_basic_map = list(
			"o" = list ("oo", "ooo"),
			"u" = list ("uu", "uuu"),
			"о" = list ("оо", "ооо"),
			"у" = list ("уу", "ууу")
		)
	autohiss_extra_map = list(
			"m" = list ("mm", "mmm"),
			"м" = list ("мм", "ммм")
		)
	autohiss_exempt = list("Orluum")

/datum/species/proc/handle_autohiss(message, datum/language/lang, mode)
	if(!autohiss_basic_map)
		return message
	if(lang.flags & NO_STUTTER)	// Currently prevents EAL, Sign language, and emotes from autohissing
		return message
	if(autohiss_exempt && (lang.name in autohiss_exempt))
		return message

	var/map = autohiss_basic_map.Copy()
	if(mode == GLOB.PREF_FULL && autohiss_extra_map)
		map |= autohiss_extra_map

	. = list()

	while(length_char(message))
		var/min_index = 10000 // if the message is longer than this, the autohiss is the least of your problems
		var/min_char = null
		for(var/char in map)
			var/i = findtext_char(message, char)
			if(!i) // no more of this character anywhere in the string, don't even bother searching next time
				map -= char
			else if(i < min_index)
				min_index = i
				min_char = char
		if(!min_char) // we didn't find any of the mapping characters
			. += message
			break
		. += copytext_char(message, 1, min_index)
		if(copytext_char(message, min_index, min_index+1) == uppertext(min_char))
			switch(text2ascii(message, min_index+1))
				if(65 to 90) // A-Z, uppercase; uppercase R/S followed by another uppercase letter, uppercase the entire replacement string
					. += uppertext(pick(map[min_char]))
				else
					. += capitalize(pick(map[min_char]))
		else
			. += pick(map[min_char])
		message = copytext_char(message, min_index + 1)

	return jointext(., null)
