require "iuplua"

function ircDialog()
	local res, server, port, nick, partner, forceSend = iup.GetParam("Connection settings", nil,
	    "Enter an IRC server: %s\n" ..
		"IRC server port: %i\n" ..
		"Your nick: %s\n" ..
		"Partner nick: %s\n" ..
		"%t\n" .. -- <hr>
		"Are you restarting\rafter a crash? %o|No|Yes|\n"
	    ,"irc.speedrunslive.com", 6667, "", "", 0)

	if 0 == res then return nil end

	return {server=server, port=port, nick=nick, partner=partner, forceSend=forceSend==1}
end

function selectDialog(specs, reason)
	local names = ""
	for i, v in ipairs(specs) do
		names = names .. v.name .. "|"
	end

	local res, selection = iup.GetParam("Select game", nil,
	    "Can't figure out\rwhich game to load\r(" .. reason .. ")\r" ..
	    "Which game is this? " ..
		"%l|" .. names .. "\n",
		0)

	if 0 == res or nil == selection then return nil end

	return specs[selection + 1]
end

function refuseDialog(options)
	iup.Message("Cannot run", "No ROM is running.")
end
