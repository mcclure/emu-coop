return{
	--Set beamVal to a value between 0 and 15.  0 is no beams, 15 is all except charge.
	--To get this value, add the following numbers for which beams you want.  Set chargeBeam to 1 if you want it on, 0 if you want it off.
	--Wave: 1
	--Ice: 2
	--Spazer: 4
	--Plasma: 8
	--Example:  If you want Plasma and Ice only, set beamVal to 10 and chargeBeam to 0
	local beamVal = 0
	local chargeBeam = 0
	memory.writebyte(0x7E09A8, beamVal),
	memory.writebyte(0x7E09A6, 0),
	memory.writebyte(0x7E09A9, 16*chargeBeam),
	print("beams set")
}