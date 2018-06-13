-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: megmacattack
-- Data source: mostly http://datacrystal.romhacking.net/wiki/The_Legend_of_Zelda:RAM_map
-- This file is available under Creative Commons CC0 

-- WARNING: May only work on first quest???

local bit = require("bit")
local math = require("math")

local base_spec = require('modes.tloz_progress')

local spec = {
	guid = "377c5683-3cf5-4c56-a921-ab40257b2ec1",
	format = "1.2",
	name = "The Legend of Zelda (sync most things)",
	match = {"stringtest", addr=0xffeb, value="ZELDA"},

	sync = {},
}

for base_key, base_val in pairs(base_spec.sync) do
	spec.sync[base_key] = base_val
end

spec.sync[0x066E] = {kind="delta", deltaMin=0} --keys

function pluralMessage(count, name)
	if count == 1 then
		return tostring(count) .. " " .. name
	else
		return tostring(count) .. " " .. name .. "s"
	end
end

-- hearts: high nibble is heart containers-1, low nibble is number of filled hearts-1
-- When we get a new container we need to add one to the number of hearts the other player gets
-- When we lose a container we need to make sure the filled heart count isn't > containers count.
spec.sync[0x066F] = {
	kind=function(value, previousValue, receiving)
		if receiving then
			-- if we're receiving we care which way the value changed, and want to
			-- act accordingly.
			local previousContainer = bit.rshift(AND(previousValue, 0xf0), 4)
			local newContainer = bit.rshift(AND(value, 0xf0), 4)
			if newContainer > previousContainer then
				-- bump up filled hearts by number of new containers
				value = OR(
					AND(value, 0xf0),
					AND(previousValue, 0x0f) + newContainer - previousContainer
				)
				message("Partner gained " .. pluralMessage(newContainer - previousContainer, "Heart Container"))
			else
				-- clamp the number of filled containers to the number of
				-- containers available
				local currentlyFilled = AND(previousValue, 0x0f)
				value = OR(
					AND(value, 0xf0),
					AND(math.min(currentlyFilled, newContainer), 0xf)
				)
				message("Partner lost " .. pluralMessage(previousContainer - newContainer, "Heart Container"))
			end
			return true, value
		else
			-- if we're sending, we just care if the container count changed.
			return AND(value, 0xf0) ~= AND(previousValue, 0xf0), value
		end
	end
}

 -- bomb count, but we need to adjust how many bombs you actually have after
 -- syncing (max out bombs on increase, reduce bombs on decrease)
spec.sync[0x067C] = {kind="delta", deltaMin=1, deltaMax=255,
	receiveTrigger=function(value, previousValue)
		if value > previousValue then
			-- we got an increase in bombs, set bomb count to the same thing and print out the bomb upgrade count
			memory.writebyte(0x0658, value)
			message("Partner got a bomb upgrade of " .. pluralMessage(value - previousValue, "bomb"))
		else
			-- we got a decrease in bombs so clamp our count and print out that we lost a bomb
			local oldBombCount = memory.readbyte(0x0658)
			if oldBombCount > value then
				memory.writebyte(0x0658, value)
			end
			message("Partner chose to get rid of " .. pluralMessage(previousValue - value, "bomb"))
		end
	end
}

-- ow map open/get data is between 0x067f and 0x6fe (top left to bottom right)
-- each tile has 0x80 set if it requires an item to open and is opened,
-- 0x10 if the thing inside is obtainable and obtained. Tiles can be either or both of
-- those. Bottom nibble seems to be unrelated and/or garbage.

-- comment out to not sync overworld map data
for i = 0x067f, 0x06fe do
	spec.sync[i] = {kind="bitOr", mask=OR(0x80,0x10)}
end


-- dungeon map data is between 0x6ff and 0x7fe (top left to bottom right, all
-- the dungeons are in a single 2d array with each other)
-- each tile has the following attributes that could be synced:
--  0x80 some enemies killed in room
--  0x40 all enemies killed in room
--  0x20 room visited (shows up on map)
--  0x10 item collected
--  0x08 top key door unlocked
--  0x04 bottom key door unlocked
--  0x02 left key door unlocked
--  0x01 right key door unlocked
-- Note that for the enemy kill info, this seems to be used as a cache for the
-- 6 room memory, as well as boss kill information. If you kill everything in
-- a room, the next time you visit that room without it being in the memory, it
-- will erase the bits unless the room has a boss in it, in which case it will
-- leave them alone and keep the boss killed.
for i = 0x06ff, 0x07fe do
	spec.sync[i] = {kind="bitOr"} -- including enemy kill data allows boss kills. Doesn't affect normal rooms.
end

return spec
