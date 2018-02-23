-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: megmacattack
-- Data source: mostly http://datacrystal.romhacking.net/wiki/The_Legend_of_Zelda:RAM_map
-- This file is available under Creative Commons CC0 

-- WARNING: May only work on first quest???

local base_spec = require('modes.tloz_progress')

local spec = {
	guid = "af791fc5-eeb2-49dc-985c-2ecba72157d9",
	format = "1.1",
	name = "The Legend of Zelda (sync everything)",
	match = {"stringtest", addr=0xffeb, value="ZELDA"},

	sync = {},
}

for base_key, base_val in pairs(base_spec.sync) do
	spec.sync[base_key] = base_val
end

spec.sync[0x066F] = {kind="high", mask=0xf0} -- hearts: high nibble is heart containers-1, low nibble is number of filled hearts-1

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
-- 0x80 some enemies killed in room
-- 0x40 all enemies killed in room
-- 0x20 room visited (shows up on map)
-- 0x10 item collected
-- 0x08 top key door unlocked
-- 0x04 bottom key door unlocked
-- 0x02 left key door unlocked
-- 0x01 right key door unlocked
for i = 0x06ff, 0x07fe do
	spec.sync[i] = {kind="bitOr", mask=0x3f} -- all but enemy kills? Play around with different masks maybe.
end

return spec