-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: Chronogeran
-- Data source: https://datacrystal.romhacking.net/wiki/Crystalis:RAM_map
-- This file is available under Creative Commons CC0

local spec = {
	guid = "9f4d9002-51df-4a4e-966a-650adda6c3ad",
	format = "1.2",
	name = "Crystalis",
	match = function(valueOverride, sizeOverride)
		return (memory.readbyte(0xfffa) == 0xb6
			and memory.readbyte(0xfffb) == 0xf3
			and memory.readbyte(0xfffc) == 0xa4
			and memory.readbyte(0xfffd) == 0xf2
			and memory.readbyte(0xfffe) == 0x43
			and memory.readbyte(0xffff) == 0xf4)
	end,
	running = {"test", addr = 0x6c, lte = 0xfe},
	sync = {},
}

local itemNameMap = {
	[0]="Sword of Wind",
	"Sword of Fire",
	"Sword of Water",
	"Sword of Thunder",
	"Crystalis",
	"Ball of Wind",
	"Tornado Bracelet",
	"Ball of Fire",
	"Flame Bracelet",
	"Ball of Water",
	"Blizzard Bracelet",
	"Ball of Thunder",
	"Storm Bracelet",
	"Carapace Shield",
	"Bronze Shield",
	"Platinum Shield",
	"Mirrored Shield",
	"Ceramic Shield",
	"Sacred Shield",
	"Battle Shield",
	"Psycho Shield",
	"Tanned Hide",
	"Leather Armor",
	"Bronze Armor",
	"Platinum Armor",
	"Soldier Suit",
	"Ceramic Suit",
	"Battle Armor",
	"Psycho Armor",
	"Medical Herb",
	"Antidote",
	"Lysis Plant",
	"Fruit of Lime",
	"Fruit of Power",
	"Magic Ring",
	"Fruit of Repun",
	"Warp Boots",
	"Statue of Onyx",
	"Opel Statue",
	"Insect Flute",
	"Flute of Lime",
	"Gas Mask",
	"Power Ring",
	"Warrior Ring",
	"Iron Necklace",
	"Deo's Pendant",
	"Rabbit Boots",
	"Leather Boots",
	"Shield Ring",
	"Alarm Flute",
	"Windmill Key",
	"Key to Prison",
	"Key to Stxy",
	"Fog Lamp",
	"Shell Flute",
	"Eye Glasses",
	"Broken Statue",
	"Glowing Lamp",
	"Statue of Gold",
	"Love Pendant",
	"Kirisa Plant",
	"Ivory Statue",
	"Bow of Moon",
	"Bow of Sun",
	"Bow of Truth",
	"Refresh",
	"Paralysis",
	"Telepathy",
	"Teleport",
	"Recover",
	"Barrier",
	"Change",
	"Flight"
}

updateUIWithNumber = function(addrHigh, addrLow, stringLoc, numDigits, val)
	-- flag
	local specifierOffset = memory.readbyte(0x0b)
	local incrementedOffset = specifierOffset + 4
	if incrementedOffset == 0x20 then
		incrementedOffset = 0
	end
	memory.writebyte(0x0b, incrementedOffset)
	-- address
	memory.writebyte(0x6200 + specifierOffset, addrHigh)
	memory.writebyte(0x6201 + specifierOffset, addrLow)
	-- num digits
	memory.writebyte(0x6202 + specifierOffset, numDigits)
	-- string location
	memory.writebyte(0x6203 + specifierOffset, stringLoc)
	-- digits
	local writeLoc = 0x6000 + stringLoc - 1
	for i=1,numDigits do
		memory.writebyte(writeLoc + i, math.floor((val % 10^(numDigits - i + 1)) / 10^(numDigits - i)))
	end
end

updateUIWithLife = function(life, maxLife)
	-- flag
	local specifierOffset = memory.readbyte(0x0b)
	local incrementedOffset = specifierOffset + 4
	if incrementedOffset == 0x20 then
		incrementedOffset = 0
	end
	memory.writebyte(0x0b, incrementedOffset)
	-- address
	memory.writebyte(0x6200 + specifierOffset, 0x2b)
	memory.writebyte(0x6201 + specifierOffset, 0x26)
	-- num digits
	memory.writebyte(0x6202 + specifierOffset, 0x11)
	-- string location
	memory.writebyte(0x6203 + specifierOffset, 0x60)
	-- tiles
	-- nothing: 0x20, right cap: 0x8d, empty: 0x8c, full: 0x88
	-- fractional: 1 -> empty (8c), 2-5: 0x8b, 6-9: 0x8a, 10-13: 0x89, 14-16: full (0x88)
	local writeLoc = 0x605f
	-- Each tile represents 16 HP
	local maxLifeSlot = math.floor((maxLife - 1) / 16) + 2
	local tilesOfLife = math.floor(life / 16)
	for i=1,17 do
		local tile = 0x20
		if maxLifeSlot == i then tile = 0x8d -- end cap
		elseif maxLifeSlot < i then tile = 0x20 -- blank
		elseif tilesOfLife >= i then tile = 0x88 -- full
		elseif tilesOfLife == i - 1 then -- fractional tile
			local fractionalAmount = life % 16
			if fractionalAmount <= 1 then tile = 0x8c
			elseif fractionalAmount <= 5 then tile = 0x8b
			elseif fractionalAmount <= 9 then tile = 0x8a
			elseif fractionalAmount <= 13 then tile = 0x89
			else tile = 0x88
			end
		else tile = 0x8c -- empty
		end
		memory.writebyte(writeLoc + i, tile)
	end
end

-- Max HP
spec.sync[0x3c0] = {kind="high",
	receiveTrigger=function (value, previousValue)
		updateUIWithLife(memory.readbyte(0x3c1), value)
	end
}

-- HP
spec.sync[0x3c1] = {kind="delta", deltaMin=0, deltaMax=0xff,
	cond=function (value, size)
		return value <= memory.readbyte(0x3c0)
	end,
	receiveTrigger=function (value, previousValue)
		updateUIWithLife(value, memory.readbyte(0x3c0))
	end
}

-- Level
spec.sync[0x421] = {kind="high", verb="gained", name="a level", 
	receiveTrigger=function (value, previousValue)
		-- Grant level up stat boosts. Just 1 per level.
		local previousAttack = memory.readbyte(0x3e1)
		local previousDefense1 = memory.readbyte(0x400)
		local previousDefense2 = memory.readbyte(0x401)
		memory.writebyte(0x3e1, previousAttack + 1)
		memory.writebyte(0x400, previousDefense1 + 1)
		memory.writebyte(0x401, previousDefense2 + 1)
		-- Update UI
		updateUIWithNumber(0x2b, 0x39, 0x80, 2, value)
	end
}

-- Gold
spec.sync[0x702] = {size=2, kind="delta", deltaMin=0, deltaMax=0xffff, receiveTrigger=function (value, previousValue)
	updateUIWithNumber(0x2b, 0x59, 0x7b, 5, value)
end}

-- EXP
spec.sync[0x704] = {size=2, kind="delta", deltaMin=0, deltaMax=0xffff, receiveTrigger=function (value, previousValue)
	updateUIWithNumber(0x2b, 0x68, 0x82, 5, value)
end}

-- Level Up EXP
spec.sync[0x706] = {size=2, receiveTrigger=function (value, previousValue)
	updateUIWithNumber(0x2b, 0x6e, 0x87, 5, value)
end}

-- MP
spec.sync[0x708] = {kind="delta", deltaMin=0, deltaMax=0xff,
	cond=function (value, size)
		return value <= memory.readbyte(0x709)
	end,
	receiveTrigger=function (value, previousValue)
		updateUIWithNumber(0x2b, 0x77, 0x8c, 3, value)
	end
}

-- Max MP
spec.sync[0x709] = {kind="high",
	receiveTrigger=function (value, previousValue)
		updateUIWithNumber(0x2b, 0x7b, 0x8f, 3, value)
	end
}

-- Inventory space
for i = 0x6430, 0x645f do
	spec.sync[i] = {nameMap=itemNameMap}
end

-- Events & chests
-- Some events involve clearing flags, so bitOr isn't sufficient.
for i = 0x6480, 0x64a1 do
	spec.sync[i] = {kind=function(value, previousValue, receiving)
		local allow = true
		-- Size is assumed to be 1
		if receiving then
			-- value is value from the message, previousValue is current value locally
			local receivedMask = RSHIFT(AND(value, 0xff00), 8)
			local receivedValue = AND(value, 0xff)
			-- Set any bits that should be set
			value = OR(previousValue, AND(receivedMask, receivedValue))
			-- Clear any bits that should be cleard
			value = AND(value, BNOT(AND(receivedMask, BNOT(receivedValue))))
			-- Only accept if changed
			allow = value ~= previousValue
		else
			-- Only send if changed
			allow = value ~= previousValue
			-- Sending out. value is current value locally, previousValue is value from the memory cache
			-- mask is what changed
			local sendingMask = XOR(value, previousValue)
			-- stuff both into a single value for the message
			value = AND(value, 0xff) + LSHIFT(sendingMask, 8)
		end
		return allow, value
	end} -- nameBitmap={}
end

-- Change form is 6485 low 4 bits, don't sync that
spec.sync[0x6485] = {kind="bitOr", mask=0xf0}

-- Doors/walls/bridges
for i = 0x64d0, 0x64df do
	spec.sync[i] = {kind="bitOr"} -- nameBitmap={}
end

-- Teleport flags
spec.sync[0x64de] = {kind="bitOr", verb="visited", nameBitmap={
	[6]="Leaf",
	[7]="Brynmaer",
	[8]="Oak"
}}
spec.sync[0x64df] = {kind="bitOr", verb="visited", nameBitmap={
	"Nadare's", "Portoa", "Amazones", "Joel", "Swan", "Shyron", "Goa", "Sahara"
}}

-- Checkpoint for data synced above
for i = 0x7d30, 0x7d5f do
	spec.sync[i] = {}
end
for i = 0x7df5, 0x7df7 do
	spec.sync[i] = {}
end
for i = 0x7d80, 0x7d87 do
	spec.sync[i] = {}
end
for i = 0x7e00, 0x7e21 do
	spec.sync[i] = {}
end
for i = 0x7e50, 0x7e5f do
	spec.sync[i] = {}
end

return spec
