-- UTILITIES

function nonempty(s) return s and s ~= "" end
function nonzero(s) return s and s ~= 0 end

-- TICKER

local currentError = nil
local currentMessages = List()
local MESSAGE_DURATION = 600

-- Set the current message (optionally, make it an error)
function message(msg, isError)
	if isError then
		currentError = msg
	else
		currentMessages:put({msg, life=MESSAGE_DURATION})
	end
end

function statusMessage(msg)
	message(msg, true)
end

function errorMessage(msg)
	message(msg and "Error: " .. msg, true)
end

-- Version string tools
function parseVersion(s)
	local split = stringx.split(s)
	if not split[1] then return null end

	local split2 = stringx.split(split[1], ".")
	if not (split2[1] and split2[2]) then return null end

	local variant = {}
	for x=2,#split do table.insert(variant, split[x]) end

	return {major=split2[1], minor=split2[2], patch=split2[3], variant=variant}
end

function parsedVersionMatches(mine, theirs, exact)
	if not (mine and theirs) then -- Blank == wildcard
		return false
	end
	local mineMajor = tonumber(mine.major)
	local mineMinor = tonumber(mine.minor)
	local theirsMajor = tonumber(theirs.major)
	local theirsMinor = tonumber(theirs.minor)
	if not theirsMajor or not theirsMinor or
	   (theirsMajor > mineMajor) or -- FIXME: This is not how semver works but all versions are currently 1.0 so whatever
	   (exact and theirsMajor < mineMajor) or
	   (theirsMajor == mineMajor and theirsMinor > mineMinor) or
	   (exact and theirsMinor < mineMinor) then
	   return false
	end
	if tablex.find(theirs.variant, "beta") and not tablex.find(mine.variant, "beta") then
		return false
	end
	return true
end

function versionMatches(mine, theirs, exact) -- If exact is false allow "downgrades"
	mine = mine and parseVersion(mine)
	theirs = theirs and parseVersion(theirs)
	return parsedVersionMatches(mine, theirs, exact)
end

-- Callback to print the current error message
function printMessage()
	local msg = null
	if currentError then
		msg = currentError
	else
		while currentMessages:len() > 0 do
			local messageRecord = currentMessages[#currentMessages]
			if messageRecord.life <= 0 then
				currentMessages:pop()
			else
				msg = messageRecord[1]
				messageRecord.life = messageRecord.life - 1
				break
			end
		end
	end
	if msg then
		gui.text(5, 254-40, msg)
	end
end
