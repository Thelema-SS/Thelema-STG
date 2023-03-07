/datum/controller/subsystem/discord/proc/is_ckey_verified(ckey)
	// Insert into the table, null in the discord id, id and timestamp and valid fields so the db fills them out where needed
	var/datum/db_query/query_insert_link_record = SSdbcore.NewQuery(
		"SELECT * FROM[format_table_name("discord_links")] WHERE ckey =:ckey)",
		list("ckey" = ckey)
	)
	to_chat(world, "POIHALI")
	if(!query_insert_link_record.Execute())
		qdel(query_insert_link_record)
		to_chat(world, "PIZDA")
		return
	
	if(query_insert_link_record.NextRow())
		var/result = query_insert_link_record.item
		to_chat(world, "RAP [result[1]] [result[2]] [result[3]] [result[4]]")
	//Cleanup
	qdel(query_insert_link_record)
	return query_insert_link_record

/client/verify_in_discord()
	set category = "OOC"
	set name = "Verify Discord Account"
	set desc = "Verify your discord account with your BYOND account"

	// Safety checks
	if(!CONFIG_GET(flag/sql_enabled))
		to_chat(src, span_warning("This feature requires the SQL backend to be running."))
		return

	// Why this would ever be unset, who knows
	var/prefix = CONFIG_GET(string/discordbotcommandprefix)
	if(!prefix)
		to_chat(src, span_warning("This feature is disabled."))

	if(!SSdiscord || !SSdiscord.reverify_cache)
		to_chat(src, span_warning("Wait for the Discord subsystem to finish initialising"))
		return
	var/message = ""
	SSdiscord.is_ckey_verified(ckey)
	// Simple sanity check to prevent a user doing this too often
	var/cached_one_time_token = SSdiscord.reverify_cache[usr.ckey]
	if(cached_one_time_token && cached_one_time_token != "")
		message = "You already generated your one time token, it is [cached_one_time_token], if you need a new one, you will have to wait until the round ends, or switch to another server, try verifying yourself in discord by using the command <span class='warning'>\" [prefix]verify [cached_one_time_token] \"</span>"


	else
		// Will generate one if an expired one doesn't exist already, otherwise will grab existing token
		var/one_time_token = SSdiscord.get_or_generate_one_time_token_for_ckey(ckey)
		SSdiscord.reverify_cache[usr.ckey] = one_time_token
		message = "Your one time token is: [one_time_token], Assuming you have the required living minutes in game, you can now verify yourself in discord by using the command <span class='warning'>\" [prefix]verify [one_time_token] \"</span>"

	//Now give them a browse window so they can't miss whatever we told them
	var/datum/browser/window = new/datum/browser(usr, "discordverification", "Discord verification")
	window.set_content("<span>[message]</span>")
	window.open()
