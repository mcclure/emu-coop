class   = require "pl.class"
pretty  = require "pl.pretty"
List    = require "pl.list"
stringx = require "pl.stringx"
tablex  = require "pl.tablex"

require "version"
require "util"

require "modes.index"
require "dialog"
require "pipe"
require "driver"

-- PROGRAM

if emu.emulating() then
	local spec = nil -- Mode specification
	
	local usableModes = {} -- Mode files that can be loaded in this version of coop.lua
	for i,v in ipairs(modes) do
		if versionMatches(version.modeFormat, v.format) then
			table.insert(usableModes, v)
		else
			print("Could not load a game mode because it is not compatible with this version of the emulator. The game's name was: " .. tostring(v.name))
		end
	end

	local specOptions = {} -- Mode files that match the currently running ROM
	for i,v in ipairs(usableModes) do
		if performTest(v.match) then
			table.insert(specOptions, v)
		end
	end

	if #specOptions == 1 then -- The current game's mode file has been found
		spec = specOptions[1]
	elseif #specOptions > 1 then -- More than one mode file was found that could be this game
		spec = selectDialog(specOptions, "multiple matches")
	else                         -- No matches
		spec = selectDialog(usableModes, "no matches")
	end

	if spec then -- If user did not hit cancel
		print("Playing " .. spec.name)

		local data = ircDialog()

		if data then -- If user did not hit cancel
			local failed = false

			function scrub(invalid) errorMessage(invalid .. " not valid") failed = true end

			-- Strip out stray whitespace (this can be a problem on FCEUX)
			for _,v in ipairs{"server", "nick", "partner"} do
				if data[v] then data[v] = data[v]:gsub("%s+", "") end
			end

			-- Check input valid
			if not nonempty(data.server) then scrub("Server")
			elseif not nonzero(data.port) then scrub("Port")
			elseif not nonempty(data.nick) then scrub("Nick")
			elseif not nonempty(data.partner) then scrub("Partner nick")
			end

			function connect()
				local socket = require "socket"
				local server = socket.tcp()
				result, err = server:connect(data.server, data.port)

				if not result then errorMessage("Could not connect to IRC: " .. err) failed = true return end

				statusMessage("Connecting to server...")

				opts.hpshare = data.hpshare
				opts.magicshare = data.magicshare
				opts.deathshare = data.deathshare
				mainDriver = GameDriver(spec, data.forceSend) -- Notice: This is a global, specs can use it
				IrcPipe(data, mainDriver):wake(server)
			end

			if not failed then connect() end

			if failed then gui.register(printMessage) end
		end
	end
else
	refuseDialog()
end
