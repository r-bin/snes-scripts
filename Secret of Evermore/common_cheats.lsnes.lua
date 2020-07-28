function block(start, finish)
	for i=start, finish do
		memory2.BUS:byte(i, 0xff)
	end
end

--memory2.BUS:word(0x7E0A3F, 0xe000) --Atlas

--block(0x7E2258, 0x7E225D) --Alchemy
--memory2.BUS:word(0x7E2261, 0x0000) --Characters
--memory2.BUS:word(0x7E2262, 0xffff) --Charms
--memory2.BUS:word(0x7E22DA, 0xffff) --Weapons
--block(0x7E22FF, 0x7E2347) --Ingredients/Items
--block(0x7E0AC6, 0x7E0AD1) --Currencies

--memory2.BUS:word(0x7E4EB3, 0x0fff) --Boy_HP_current
--memory2.BUS:word(0x7E4F61, 0x0fff) --Dog_HP_current

--memory2.BUS:word(0x7E22EB, 0xffff) --debug

--memory2.BUS:word(0x7E0A47, 99) --Boy_hit%