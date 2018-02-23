-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: megmacattack
-- Data source: mostly http://datacrystal.romhacking.net/wiki/The_Legend_of_Zelda:RAM_map
-- This file is available under Creative Commons CC0 

local base_spec = require('modes.tloz_basic')

local spec = {
	guid = "658ed546-4984-4203-9e10-5866d2bc05c0",
	format = "1.1",
	name = "The Legend of Zelda (sync normal and progress items)",
	match = {"stringtest", addr=0xffeb, value="ZELDA"},

	sync = {},
}
for base_key, base_val in pairs(base_spec.sync) do
	spec.sync[base_key] = base_val
end

spec.sync[0x0667] = { -- level 0-8 compass
	nameBitmap={"Level 1 Compass", "Level 2 Compass", "Level 3 Compass", "Level 4 Compass", "Level 5 Compass", "Level 6 Compass", "Level 7 Compass", "Level 8 Compass"},
	kind="bitOr"
}
spec.sync[0x0668] = { -- level 0-8 map
	nameBitmap={"Level 1 Map", "Level 2 Map", "Level 3 Map", "Level 4 Map", "Level 5 Map", "Level 6 Map", "Level 7 Map", "Level 8 Map"},
	kind="bitOr"
}
spec.sync[0x0669] = {name="Level 9 Compass", kind="high"}
spec.sync[0x066A] = {name="Level 9 Map", kind="high"}
spec.sync[0x0671] = { -- triforce pieces
	nameBitmap={"First Triforce Piece", "Second Triforce Piece", "Third Triforce Piece", "Fourth Triforce Piece", "Fifth Triforce Piece", "Sixth Triforce Piece", "Seventh Triforce Piece", "Eighth Triforce Piece"},
	kind="bitOr"
}
spec.sync[0x0672] = {name="Triforce of Power", kind="high"}

return spec