-- STOP! Are you about to edit this file?
-- If you change ANYTHING, please please PLEASE run the following script:
-- https://www.guidgenerator.com/online-guid-generator.aspx
-- and put in a new GUID in the "guid" field.

-- Author: Andi McClure
-- Data source: http://alttp.run/hacking/index.php?title=SRAM_Map
-- Thanks to the Zelda randomizer team, especially Mike Trethewey, Zarby89 and Karkat
-- This file is available under Creative Commons CC0 

--Mod by Trevor Thompson
--Current Revision: 1.2
--8/19/19

--Note: 0x7EF300 to 0x7EF3FF in ALTTP WRAM will be at 0xA17B00 to 0xA17BFF while in SM. Likewise, 0x7E09A2 to 0x7E09E2 in SM WRAM will be at 0xA17900 to 0xA1793F while in ALTTP.
local int ZSTORAGE = 0x228800
local int MSTORAGE = 0x236F5E
local previous = {}
local roomqueuez = {}
for z = 0x7EF340, 0x7EF3C9 do --zelda item range
	previous[z] = 0
end
for m = 0x7E09C4, 0x7ED82C do --metroid item range
	previous[m] = 0
end
-- When you get a missile, super missile or power bomb, your current count goes up by the size of the expansion
local function makeMissileTrigger(targetAddr) -- 2 byte size
	return function(value, previousValue)
		local current = memory.readword(targetAddr)
		memory.writeword(targetAddr, current + (value - previousValue))
	end
end

local function difference(a, b) -- 1 byte size
	return AND(a, XOR(b, 0xFF))
end

-- When you get an item, any bit that goes high in the "available" byte should also go high in the "equipped" byte
-- (but only if it is ALSO in the mask of bits we're watching)
local function makeItemTrigger(targetAddr, mask, value, previousValue) -- 2 byte size
	local current = memory.readbyte(targetAddr)
	memory.writebyte(targetAddr, OR(current, AND(mask, difference(value, previousValue))))
	message("equipped at " .. targetAddr .. " old = " .. previousValue .. " new = " .. value)
end

local function zeldaLocalItemTrigger(targetAddr)
	return function(value, previousValue, forceSend)
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 0 then
			if previous[targetAddr] == nil then	
				previous[targetAddr] = 0
			end
			if value ~= nil and value > previous[targetAddr] then  
				local sendPayload = targetAddr .. value
				send("zsync", sendPayload)
				previous[targetAddr] = value
			end
		end
	end
end

local function zeldaLocalBottleTrigger(targetAddr)
	return function(value, previousValue, forceSend)
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 0 then
			if previous[targetAddr] == nil then	
				previous[targetAddr] = 0
			end
			if value ~= nil then  
				local sendPayload = targetAddr .. value
				send("zsync", sendPayload)
				previous[targetAddr] = value
			end
		end
	end
end

local function zeldaLocalBitTrigger(targetAddr)
	return function(value, previousValue, forceSend)
		--message("Equipment Changed")
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 0 then
			if previous[targetAddr] == nil then	
				previous[targetAddr] = 0
			end
			local newBitVal = OR(value, previous[targetAddr])
			local sendPayload = targetAddr .. newBitVal
			send("zsyncbit", sendPayload)
			previous[targetAddr] = newBitVal
		end
	end
end

local function zeldaForeignBitTrigger(targetAddr)
	return function(value, previousValue, forceSend)
		--message("Equipment Changed")
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 255 then
			if previous[targetAddr] == nil then	
				previous[targetAddr] = 0
			end
			local newBitVal = OR(value, previous[targetAddr])
			local sendPayload = targetAddr .. newBitVal
			send("zsyncbit", sendPayload)
			previous[targetAddr] = newBitVal
		end
	end
end

local function zeldaForeignItemTrigger(targetAddr)  
	return function(value, previousValue, forceSend)
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 255 then
			if previous[targetAddr] == nil then	
				previous[targetAddr] = 0
			end
			if value ~= nil and value > previous[targetAddr] then
				local sendPayload = targetAddr .. value
				send("zsync", sendPayload)
				previous[targetAddr] = value
			end
		end
	end
end

local function zeldaForeignBottleTrigger(targetAddr)  
	return function(value, previousValue, forceSend)
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 255 then
			if previous[targetAddr] == nil then	
				previous[targetAddr] = 0
			end
			if value ~= nil then
				local sendPayload = targetAddr .. value
				send("zsync", sendPayload)
				previous[targetAddr] = value
			end
		end
	end
end

local function metroidLocalExpTrigger(targetAddr, localFunc)
	return function(value, previousValue, forceSend)
		--message("Expansions Changed")
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 255 then
			if previous[targetAddr] == nil then	
				previous[targetAddr] = 0
			end
			if value ~= nil and value > previous[targetAddr] then
				local sendPayload = targetAddr .. value
				send(localFunc, sendPayload)
				previous[targetAddr] = value
			end
		end
	end
end

local function metroidLocalBitTrigger(targetAddr, mask) -- check bit to ensure extra value is not being added on second pickup:  Subtract old from new, AND this value with old, if that value is not zero then ignore
	return function(value, previousValue, forceSend)
		--message("Equipment Changed")
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 255 then
			if previous[targetAddr] == nil then	
				previous[targetAddr] = 0
			end
			local rising = value - previous[targetAddr]
			if AND(rising, previous[targetAddr]) == 0 then
				local newBitVal = OR(value, previous[targetAddr])
				local sendPayload = targetAddr .. mask .. newBitVal
				send("msync", sendPayload)
				previous[targetAddr] = newBitVal
			end
		end
	end
end

local function metroidBossBitTrigger(targetAddr)
	return function(value, previousValue, forceSend)
		--message("Equipment Changed")
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 255 then
			if previous[targetAddr] == nil then	
				previous[targetAddr] = 0
			end
			if value > previous[targetAddr] then
				local newBitVal = OR(value, previous[targetAddr])
				local sendPayload = targetAddr .. newBitVal
				send("msyncbit", sendPayload)
				previous[targetAddr] = newBitVal
			end
		end
	end
end

local function metroidLocalBeamTrigger(targetAddr, mask) -- check bit to ensure extra value is not being added on second pickup
	return function(value, previousValue, forceSend)
		--message("Equipment Changed")
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 255 and value ~= 0 then
			if previous[targetAddr] == nil then	
				previous[targetAddr] = 0
			end
			message("local")
			message(value)
			local rising = value - previous[targetAddr]
			message(rising)
			if AND(rising, previous[targetAddr]) == 0 then
				local newBitVal = OR(value, previous[targetAddr])
				message(newBitVal)
				local sendPayload = targetAddr .. newBitVal
				send("msyncbeam", sendPayload)
				send("msyncbeamequip", sendPayload)
				previous[targetAddr] = value
			end
			previous[targetAddr] = value
		end
	end
end

local function metroidForeignExpTrigger(targetAddr, localFunc)
	return function(value, previousValue, forceSend)
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 0 then
			if previous[targetAddr] == nil then	
				previous[targetAddr] = 0
			end
			if value ~= nil and value > previous[targetAddr] then
				local sendPayload = targetAddr .. value
				send(localFunc, sendPayload)
				previous[targetAddr] = value
			end
		end
	end
end

local function metroidForeignBitTrigger(targetAddr, mask) -- check bit to ensure extra value is not being added on second pickup
	return function(value, previousValue, forceSend)
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 0 then
			if previous[targetAddr] == nil then	
				previous[targetAddr] = 0
			end
			local rising = value - previous[targetAddr]
			if AND(rising, previous[targetAddr]) == 0 then
				local newBitVal = OR(value, previous[targetAddr])
				local sendPayload = targetAddr .. mask .. newBitVal
				send("msync", sendPayload)
				previous[targetAddr] = newBitVal
			end
		end
	end
end

local function metroidForeignBeamTrigger(targetAddr, mask) -- check bit to ensure extra value is not being added on second pickup
	return function(value, previousValue, forceSend)
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 0 and value ~= 0 then
			if previous[targetAddr] == nil then	
				previous[targetAddr] = 0
			end
			message("foreign")
			message(value)
			local rising = value - previous[targetAddr]
			message(rising)
			if AND(rising, previous[targetAddr]) == 0 then
				local newBitVal = OR(value, previous[targetAddr])
				message(newBitVal)
				local sendPayload = targetAddr .. newBitVal
				send("msyncbeam", sendPayload)
				send("msyncbeamequip", sendPayload)
				previous[targetAddr] = value
			end
		end
	end
end

------------------------------
--------Zelda Menu Fix--------
------------------------------
local function zeldaMenuTrigger()
	return function(value, previousValue, forceSend)
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 0 then
			memoryWrite(0x7E0FFC, 0)
		end
	end
end
------------------------------
---------Room Syncing---------
------------------------------

local function roomSync()
	return function(value, previousValue, forceSend)
		if currentGame == 0 then
			while roomqueuez.size > 0 do 
				memoryWrite(tonumber(string.sub(roomqueuez[roomqueuez.size], 1, 8), 16),tonumber(string.sub(roomqueuez[roomqueuez.size], 9), 10))
				roomqueuez[roomqueuez.size] = nil
			end	
		else
			while roomqueuem.size > 0 do 
				memoryWrite(tonumber(string.sub(roomqueuem[roomqueuem.size], 1, 8), 16),tonumber(string.sub(roomqueuem[roomqueuem.size], 9), 10))
				roomqueuem[roomqueum.size] = nil
			end	
		end
	end
end

local function zeldaRoomTrigger(targetAddr)
	return function(value, previousValue, forceSend)
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 0 then
			if previous[targetAddr] == nil then	
				previous[targetAddr] = 0
			end
			if value ~= previous[targetAddr] then
				sendPayload = targetAddr .. value
				send("zsyncroom", sendPayload)
				previous[targetAddr] = value
			end
		end
	end
end

local function metroidRoomTrigger(targetAddr)
	return function(value, previousValue, forceSend)
		local currentGame = memoryRead(0xA173FE)
		if currentGame == 0 then
			if previous[targetAddr] == nil then	
				previous[targetAddr] = 0
			end
			if value ~= previous[targetAddr] then
				sendPayload = targetAddr .. value
				send("msyncroom", sendPayload)
				previous[targetAddr] = value
			end
		end
	end
end
return {
	guid = "f003df87-0c3b-4b3b-86c8-d0deef93e6ec",
	format = "1.2",
	name = "Z3M3",
	match = {"stringtest", addr=0xFFC0, value="SMALTTP"},  -- This needs to be changed to the name of the file later

	--running = {"test", addr = 0x7E0010, gte = 0x6, lte = 0x13}, --Zelda
	--running = {"test", addr = 0x7E0998, gte = 0x8, lte = 0x18}, -- Super Metroid
	sync = {
		------------------------------
		---------Room Syncing---------
		------------------------------
		[0xA173FE] = {nameMap={"RoomState"}, kind="trigger", writeTrigger=roomSync()},
		------------------------------
		--------Zelda Menu Fix--------
		------------------------------
		[0x7E0FFC] = {nameMap={"Menu"}, kind="trigger", writeTrigger=zeldaMenuTrigger("0x7E0FFC")},
		------------------------------
		--Zelda Items while in Zelda--
		------------------------------
		[0x7EF340] = {nameMap={"Bow", "Bow", "Silver Arrows", "Silver Arrows"}, kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF340")},
		[0x7EF341] = {nameMap={"Boomerang", "Magic Boomerang"}, kind="trigger", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF341")},
		[0x7EF342] = {name="Hookshot", kind="trigger",   writeTrigger=zeldaLocalItemTrigger("0x7EF342")},
		[0x7EF344] = {nameMap={"Mushroom", "Magic Powder"}, kind="trigger",   writeTrigger=zeldaLocalItemTrigger("0x7EF344")},
		[0x7EF345] = {name="Fire Rod", kind="trigger",   writeTrigger=zeldaLocalItemTrigger("0x7EF345")},
		[0x7EF346] = {name="Ice Rod", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF346")},
		[0x7EF347] = {name="Bombos", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF347")},
		[0x7EF348] = {name="Ether", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF348")},
		[0x7EF349] = {name="Quake", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF349")},
		[0x7EF34A] = {name="Lantern", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF34A")},
		[0x7EF34B] = {name="Hammer", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF34B")},
		[0x7EF34C] = {nameMap={"Shovel", "Flute", "Bird"}, kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF34C")},
		[0x7EF34D] = {name="Net", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF34D")},
		[0x7EF34E] = {name="Book", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF34E")},
		[0x7EF34F] = {kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF34F")},-- Bottle count
		[0x7EF350] = {name="Red Cane", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF350")},
		[0x7EF351] = {name="Blue Cane", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF351")},
		[0x7EF352] = {name="Cape", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF352")},
		[0x7EF353] = {name="Mirror", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF353")},
		[0x7EF354] = {name="Gloves", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF354")},
		[0x7EF355] = {name="Boots", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF355")},
		[0x7EF356] = {name="Flippers", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF356")},
		[0x7EF357] = {name="Pearl", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF357")},
		[0x7EF359] = {nameMap={"Fighter's Sword", "Master Sword", "Tempered Sword", "Golden Sword"}, kind="trigger", cond={"test", gte = 0x1, lte = 0x4}, writeTrigger=zeldaLocalItemTrigger("0x7EF359")},
		[0x7EF35A] = {nameMap={"Shield", "Fire Shield", "Mirror Shield"}, kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF35A")},
		[0x7EF35B] = {nameMap={"Blue Armor", "Red Armor"}, kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF35B")},
		[0x7EF35C] = {name="Bottle", kind="trigger", writeTrigger=zeldaLocalBottleTrigger("0x7EF35C")},-- Only change contents when acquiring new *empty* bottle
		[0x7EF35D] = {name="Bottle", kind="trigger", writeTrigger=zeldaLocalBottleTrigger("0x7EF35D")},
		[0x7EF35E] = {name="Bottle", kind="trigger", writeTrigger=zeldaLocalBottleTrigger("0x7EF35E")},
		[0x7EF35F] = {name="Bottle", kind="trigger", writeTrigger=zeldaLocalBottleTrigger("0x7EF35F")},
		--[0x7EF366] = {name="a Big Key", kind="bitOr"},
		--[0x7EF367] = {name="a Big Key", kind="bitOr"},
		[0x7EF379] = {kind="bitOr", kind="trigger", writeTrigger=zeldaLocalBitTrigger("0x7EF379")},
		[0x7EF374] = {name="a Pendant", kind="trigger", writeTrigger=zeldaLocalBitTrigger("0x7EF374")},
		[0x7EF37A] = {name="a Crystal", kind="trigger", writeTrigger=zeldaLocalBitTrigger("0x7EF37A")},
		[0x7EF37B] = {name="Half Magic", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF37B")},
		--[0x7EF3C9] = {kind="bitOr", mask=0x20}, -- Dwarf rescue bit (required for bomb shop)
		
		[0x7EF36C] = {name="a Heart Container", kind="trigger", writeTrigger=zeldaLocalItemTrigger("0x7EF36C")},
		
		--------------------------------------
		--Zelda Items while in Super Metroid--
		--------------------------------------
		[0x7EF340+ZSTORAGE] = {nameMap={"Bow", "Bow", "Silver Arrows", "Silver Arrows"}, kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF340")},
		[0x7EF341+ZSTORAGE] = {nameMap={"Boomerang", "Magic Boomerang"}, kind="trigger", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF341")},
		[0x7EF342+ZSTORAGE] = {name="Hookshot", kind="trigger",   writeTrigger=zeldaForeignItemTrigger("0x7EF342")},
		[0x7EF344+ZSTORAGE] = {nameMap={"Mushroom", "Magic Powder"}, kind="trigger",   writeTrigger=zeldaForeignItemTrigger("0x7EF344")},
		[0x7EF345+ZSTORAGE] = {name="Fire Rod", kind="trigger",   writeTrigger=zeldaForeignItemTrigger("0x7EF345")},
		[0x7EF346+ZSTORAGE] = {name="Ice Rod", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF346")},
		[0x7EF347+ZSTORAGE] = {name="Bombos", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF347")},
		[0x7EF348+ZSTORAGE] = {name="Ether", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF348")},
		[0x7EF349+ZSTORAGE] = {name="Quake", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF349")},
		[0x7EF34A+ZSTORAGE] = {name="Lantern", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF34A")},
		[0x7EF34B+ZSTORAGE] = {name="Hammer", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF34B")},
		[0x7EF34C+ZSTORAGE] = {nameMap={"Shovel", "Flute", "Bird"}, kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF34C")},
		[0x7EF34D+ZSTORAGE] = {name="Net", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF34D")},
		[0x7EF34E +ZSTORAGE] = {name="Book", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF34E")},
		[0x7EF34F+ZSTORAGE] = {kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF34F")},-- Bottle count
		[0x7EF350+ZSTORAGE] = {name="Red Cane", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF350")},
		[0x7EF351+ZSTORAGE] = {name="Blue Cane", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF351")},
		[0x7EF352+ZSTORAGE] = {name="Cape", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF352")},
		[0x7EF353+ZSTORAGE] = {name="Mirror", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF353")},
		[0x7EF354+ZSTORAGE] = {name="Gloves", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF354")},
		[0x7EF355+ZSTORAGE] = {name="Boots", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF355")},
		[0x7EF356+ZSTORAGE] = {name="Flippers", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF356")},
		[0x7EF357+ZSTORAGE] = {name="Pearl", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF357")},
		[0x7EF359+ZSTORAGE] = {nameMap={"Fighter's Sword", "Master Sword", "Tempered Sword", "Golden Sword"}, kind="trigger", cond={"test", gte = 0x1, lte = 0x4}, writeTrigger=zeldaForeignItemTrigger("0x7EF359")},
		[0x7EF35A+ZSTORAGE] = {nameMap={"Shield", "Fire Shield", "Mirror Shield"}, kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF35A")},
		[0x7EF35B+ZSTORAGE] = {nameMap={"Blue Armor", "Red Armor"}, kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF35B")},
		[0x7EF35C+ZSTORAGE] = {name="Bottle", kind="trigger", writeTrigger=zeldaForeignBottleTrigger("0x7EF35C")},-- Only change contents when acquiring new *empty* bottle
		[0x7EF35D+ZSTORAGE] = {name="Bottle", kind="trigger", writeTrigger=zeldaForeignBottleTrigger("0x7EF35D")},
		[0x7EF35E +ZSTORAGE] = {name="Bottle", kind="trigger", writeTrigger=zeldaForeignBottleTrigger("0x7EF35E")},
		[0x7EF35F+ZSTORAGE] = {name="Bottle", kind="trigger", writeTrigger=zeldaForeignBottleTrigger("0x7EF35F")},
		--[0x7EF366+ZSTORAGE] = {name="a Big Key", kind="bitOr"},
		--[0x7EF367+ZSTORAGE] = {name="a Big Key", kind="bitOr"},
		[0x7EF379+ZSTORAGE] = {kind="bitOr", kind="trigger", writeTrigger=zeldaForeignBitTrigger("0x7EF379")},
		[0x7EF374+ZSTORAGE] = {name="a Pendant", kind="trigger", writeTrigger=zeldaForeignBitTrigger("0x7EF374")},
		[0x7EF37A+ZSTORAGE] = {name="a Crystal", kind="trigger", writeTrigger=zeldaForeignBitTrigger("0x7EF37A")},
		[0x7EF37B+ZSTORAGE] = {name="Half Magic", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF37B")},
		--[0x7EF3C9+ZSTORAGE] = {kind="bitOr", mask=0x20} -- Dwarf rescue bit (required for bomb shop)
		
		[0x7EF36C + ZSTORAGE] = {name="a Heart Container", kind="trigger", writeTrigger=zeldaForeignItemTrigger("0x7EF36C")},
		
		----------------------------------------------
		--Super Metroid Items while in Super Metroid--
		----------------------------------------------
		
		[0x7E09C4] = {name="Energy Tank", kind="trigger", size=2, writeTrigger=metroidLocalExpTrigger("0x7E09C4","msynctank")},
		[0x7E09C8] = {name="Missile Expansion", kind="trigger", size=2, writeTrigger=metroidLocalExpTrigger("0x7E09C8","msyncexp")},
		[0x7E09CC] = {name="Super Missiles", kind="trigger", size=2, writeTrigger=metroidLocalExpTrigger("0x7E09CC","msyncexp")},
		[0x7E09D0] = {name="Power Bombs", kind="trigger", size=2, writeTrigger=metroidLocalExpTrigger("0x7E09D0","msyncexp")},
		[0x7E09D4] = {name="Reserve Tank", kind="trigger", size=2, writeTrigger=metroidLocalExpTrigger("0x7E09D4","msynctankreserve")},
		[0x7E09A4] = {nameBitmap={"Varia Suit", "Spring Ball", "Morph Ball", "Screw Attack", "unknown item", "Gravity Suit"}, kind="trigger", writeTrigger=metroidLocalBitTrigger("0x7E09A4", "0x2F")},
		--[0x7E09A4] = {nameBitmap={"Varia Suit", "Spring Ball", "Morph Ball", "Screw Attack", "unknown item", "Gravity Suit"}, kind="bitOr", mask=0x2F, receiveTrigger=makeItemTrigger(0x7E09A2, 0x2F)},
		[0x7E09A5] = {nameBitmap={"Hi-Jump Boots", "Space Jump", "unknown item", "unknown item", "Bomb", "Speed Booster", "Grapple Beam", "X-Ray Scope"}, kind="trigger", writeTrigger=metroidLocalBitTrigger("0x7E09A5", "0xF3")},
		[0x7E09A8] = {nameBitmap={"Wave Beam", "Ice Beam", "Spazer Beam", "Plasma Beam"}, kind="trigger", writeTrigger=metroidLocalBeamTrigger("0x7E09A8", "0x0F")}, -- Trigger for beams is same as makeItemTrigger, EXCEPT we must make sure the plasma and spazer beam never go high at once
		[0x7E09A9] = {nameBitmap={"unknown beam", "unknown beam", "unknown beam", "unknown beam", "Charge Beam"}, kind="trigger", writeTrigger=metroidLocalBeamTrigger("0x7E09A9", "0x10")},
		[0x7ED829] = {nameBitmap={"Kraid"}, verb="defeated", kind="trigger", writeTrigger=metroidBossBitTrigger("0x7ED829", "0x01")},
		[0x7ED82A] = {nameBitmap={"Ridley"}, verb="defeated", kind="trigger", writeTrigger=metroidBossBitTrigger("0x7ED82A", "0x01")},
		[0x7ED82B] = {nameBitmap={"Phantoon"}, verb="defeated", kind="trigger", writeTrigger=metroidBossBitTrigger("0x7ED82B", "0x01")},
		[0x7ED82C] = {nameBitmap={"Draygon"}, verb="defeated", kind="trigger", writeTrigger=metroidBossBitTrigger("0x7ED82C", "0x01")},
		[0x7ED820] = {nameBitmap={"the planet angry"}, kind="trigger", writeTrigger=metroidBossBitTrigger("0x7ED820", "0x01")}, -- "Zebes is awake"
		
		--------------------------------------
		--Super Metroid Items while in Zelda--
		--------------------------------------
		[0x7E09C4+MSTORAGE] = {name="Energy Tank", kind="trigger", size=2, writeTrigger=metroidForeignExpTrigger("0x7E09C4","msynctank")},
		[0x7E09C8+MSTORAGE] = {name="Missile Expansion", kind="trigger", size=2, writeTrigger=metroidForeignExpTrigger("0x7E09C8","msyncexp")},
		[0x7E09CC+MSTORAGE] = {name="Super Missiles",    kind="trigger", size=2, writeTrigger=metroidForeignExpTrigger("0x7E09CC","msyncexp")},
		[0x7E09D0+MSTORAGE] = {name="Power Bombs",       kind="trigger", size=2, writeTrigger=metroidForeignExpTrigger("0x7E09D0","msyncexp")},
		[0x7E09D4+MSTORAGE] = {name="Reserve Tank",      kind="trigger", size=2, writeTrigger=metroidForeignExpTrigger("0x7E09D4","msynctankreserve")},
		[0x7E09A4+MSTORAGE] = {nameBitmap={"Varia Suit", "Spring Ball", "Morph Ball", "Screw Attack", "unknown item", "Gravity Suit"},kind="trigger", writeTrigger=metroidForeignBitTrigger("0x7E09A4", "0x2F")},
		[0x7E09A5+MSTORAGE] = {nameBitmap={"Hi-Jump Boots", "Space Jump", "unknown item", "unknown item", "Bomb", "Speed Booster", "Grapple Beam", "X-Ray Scope"},kind="trigger", writeTrigger=metroidForeignBitTrigger("0x7E09A5", "0xF3")}, 
		[0x7E09A8+MSTORAGE] = {nameBitmap={"Wave Beam", "Ice Beam", "Spazer Beam", "Plasma Beam"},kind="trigger",writeTrigger=metroidForeignBeamTrigger("0x7E09A8", "0x0F")}, -- Trigger for beams is same as makeItemTrigger, EXCEPT we must make sure the plasma and spazer beam never go high at once
		[0x7E09A9+MSTORAGE] = {nameBitmap={"unknown beam", "unknown beam", "unknown beam", "unknown beam", "Charge Beam"},
			kind="trigger", writeTrigger=metroidForeignBeamTrigger("0x7E09A9", "0x10")},
		--[0x7ED829+MSTORAGE] = {nameBitmap={"Kraid"},    verb="defeated", kind="bitOr", mask=0x1},
		--[0x7ED82A+MSTORAGE] = {nameBitmap={"Ridley"},   verb="defeated", kind="bitOr", mask=0x1},
		--[0x7ED82B+MSTORAGE] = {nameBitmap={"Phantoon"}, verb="defeated", kind="bitOr", mask=0x1},
		--[0x7ED82C+MSTORAGE] = {nameBitmap={"Draygon"},  verb="defeated", kind="bitOr", mask=0x1},
		--[0x7ED820+MSTORAGE] = {kind="bitOr", mask=0x01, nameBitmap={"the planet angry"}} -- "Zebes is awake"	
	},
	custom = { -- sync high and bit values to take only high or OR'ed values, and set previous for target address
		zsync = function(payload)
			local address = tonumber(string.sub(payload, 1, 8), 16)
			local value = string.sub(payload, 9)
			local currentGame = memoryRead(0xA173FE)
			if currentGame == 0 then
				memoryWrite(address, value)
				message("wrote val to Zelda while in Zelda")
			else
				local addressHex = address + ZSTORAGE
				memoryWrite(addressHex, value)
				message("wrote val to Zelda while in Metroid")
			end
		end,
		
		zsyncbit = function(payload)
			local address = tonumber(string.sub(payload, 1, 8), 16)
			local value = tonumber(string.sub(payload, 9), 10)
			local currentGame = memoryRead(0xA173FE)
			if currentGame == 0 then
				local previousValue = memoryRead(address)
				if previousValue == nil then
					previousValue = 0
				end
				memoryWrite(address, OR(value, previousValue))
			else
				local addressHex = address + ZSTORAGE
				local previousValue = memoryRead(addressHex)
				if previousValue == nil then
					previousValue = 0
				end
				memoryWrite(addressHex, OR(value, previousValue))
			end
		end,
		
		zsyncroom = function(payload)
			local currentGame = memoryRead(0xA173FE)
			if currentGame == 255 then
				roomqueuez[roomqueuez.size + 1] = payload
			end
		end,
		
		msyncroom = function(payload)
			local currentGame = memoryRead(0xA173FE)
			if currentGame == 0 then
				roomqueuem[roomqueuem.size + 1] = payload
			end
		end,
		
		msync = function(payload)
			local address = tonumber(string.sub(payload, 1, 8), 16)
			local mask = tonumber(string.sub(payload, 9, 12), 16)
			local value = tonumber(string.sub(payload, 13),10)
			local currentGame = memoryRead(0xA173FE)
			message(string.sub(payload, 1, 8))
			message(string.sub(payload, 9, 12))
			message(string.sub(payload, 13))
			if currentGame == 0 then
				local addressHex = address + MSTORAGE
				local previousValue = memoryRead(addressHex)
				if previousValue == nil then
					previousValue = 0
				end
				memoryWrite(addressHex, OR(value, previousValue))
				makeItemTrigger(addressHex-2, mask, value, previousValue)
			else
				local previousValue = memoryRead(address)
				if previousValue == nil then
					previousValue = 0
				end
				memoryWrite(address, OR(value, previousValue))
				makeItemTrigger(address-2, mask, value, previousValue)
			end
		end,
		
		msyncbit = function(payload)
			local address = tonumber(string.sub(payload, 1, 8), 16)
			local value = tonumber(string.sub(payload, 9), 10)
			local currentGame = memoryRead(0xA173FE)
			if currentGame == 0 then
				local addressHex = address + MSTORAGE
				local previousValue = memoryRead(addressHex)
				if previousValue == nil then
					previousValue = 0
				end
				memoryWrite(addressHex, OR(value, previousValue), 2)
			else
				local previousValue = memoryRead(address)
				if previousValue == nil then
					previousValue = 0
				end
				memoryWrite(address, OR(value, previousValue), 2)
			end
		end,
		
		msyncbeam = function(payload)
			local address = tonumber(string.sub(payload, 1, 8), 16)
			local value = tonumber(string.sub(payload, 9),10)
			message("recieved value " .. value .. "for beam sync")
			local currentGame = memoryRead(0xA173FE)
			if currentGame == 0 then
				local addressHex = address + MSTORAGE
				memoryWrite(addressHex, value)
			else
				memoryWrite(address, value)
			end
		end,
		
		msyncbeamequip = function(payload)
			local address = tonumber(string.sub(payload, 1, 8), 16)
			local value = tonumber(string.sub(payload, 9),10)
			message("recieved value " .. value .. "for beam equip")
			if currentGame == 0 then
				local current = memory.readbyte(address + MSTORAGE)
				local currentEquip = memory.readbyte(address-2 + MSTORAGE)
				if current == nil then
					current = 0
				end
				if currentEquip == nil then
					currentEquip = 0
				end
				newItem = value
				newVal = OR(currentEquip, newItem)
				message(newVal)
				if newVal >= 12 and address == 0x7E09A8 then
					newVal = newVal - 4
				end
				memory.writebyte(address - 2 + MSTORAGE, newVal)
				message("wrote beamequip to Metroid while in Metroid")
			else
				local current = memory.readbyte(address)
				local currentEquip = memory.readbyte(address - 2)
				if current == nil then
					current = 0
				end
				if currentEquip == nil then
					currentEquip = 0
				end
				message(value)
				newItem = value
				newVal = OR(currentEquip, newItem)
				message(newVal)
				if newVal >= 12 and address == 0x7E09A8 then
					newVal = newVal - 4
				end
				memory.writebyte(address - 2, newVal)
				message("wrote beamequip to Metroid while in Metroid")
			end
		end,
		
		msyncexp = function(payload)
			local address = tonumber(string.sub(payload, 1, 8), 16)
			local value = string.sub(payload, 9)
			local newVal = tonumber(value, 10)
			local currentGame = memoryRead(0xA173FE)
			if currentGame == 0 then
				local addressHex = address + MSTORAGE
				local ammoCount = memory.readword(addressHex-2)
				local oldVal = memory.readword(addressHex)
				if newVal > oldVal then
					memoryWrite(addressHex, value, 2)
					message("wrote expansion to Metroid while in Zelda")
					memory.writeword(addressHex - 2, ammoCount + 5) -- Add 5 ammo
				end
			else
				local ammoCount = memory.readword(address-2)
				local oldVal = memory.readword(address)
				if newVal > oldVal then
					memoryWrite(address, value, 2)
					message("wrote expansion to Metroid while in Metroid")
					memory.writeword(address - 2, ammoCount + 5) -- Add 5 ammo
				end
			end
		end,
		
		msynctank = function(payload)
			local address = tonumber(string.sub(payload, 1, 8), 16)
			local value = string.sub(payload, 9)
			local currentGame = memoryRead(0xA173FE)
			local newVal = tonumber(value, 10)
			if currentGame == 0 then
				local addressHex = address + MSTORAGE
				local oldVal = memory.readword(addressHex)
				if newVal > oldVal then
					memory.writeword(0x7E09C2 + MSTORAGE, value) -- Refill health on any Etank collection
					memoryWrite(addressHex, value, 2)
					message("wrote E-tank to Metroid while in Zelda")
				end
			else
				local oldVal = memory.readword(address)
				if newVal > oldVal then
					memory.writeword(0x7E09C2, value) -- Refill health on any Etank collection
					memoryWrite(address, value, 2)
					message("wrote E-tank to Metroid while in Metroid")
				end
			end
		end,
		
		msynctankreserve = function(payload)
			local address = tonumber(string.sub(payload, 1, 8), 16)
			local value = string.sub(payload, 9)
			local currentGame = memoryRead(0xA173FE)
			if currentGame == 0 then
				local addressHex = address + MSTORAGE
				memoryWrite(addressHex, value, 2)
				message("wrote R-tank to Metroid while in Zelda")
			else
				memoryWrite(address, value, 2)
				makeMissileTrigger(address - 14)
				message("wrote R-tank to Metroid while in Metroid")
			end
		end
		
	}
}


