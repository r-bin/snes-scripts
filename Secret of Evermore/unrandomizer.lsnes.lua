RNG_BYTES = { 0x0133, 0x0134, 0x0135, 0x0136, 0x0137, 0x0138, 0x0139, 0x013A }
RNG_NUMBER = 0x00

function unrandomize()
	for _, rng_byte in pairs(RNG_BYTES) do
		memory2.WRAM:byte(rng_byte, RNG_NUMBER)
	end
end

function on_input()
	unrandomize()
end