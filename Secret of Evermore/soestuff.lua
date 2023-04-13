-- configuration --
cheat = false
show_tiles = false
show_mapdata = true
show_sprite_data = false
show_damage_rolls = false --causes seconds of lag when a new enemy/attack combination spawns (until they are buffered)
show_lag = true
show_lag_details = true
show_actual_market_time = false
show_script_ids = true
show_scripts = true
show_scripts_unknown = true
show_watchers = true
show_alchemy = true
show_projectiles = true
seconds_for_averages = 5
FPS = 60.098475521 -- 50.0069789082 for PAL
pos_fmt = "%d,%d"
--pos_fmt = "%3X,%3X"
lag_fmt = "Lag: %.1fs" -- change to .3f to get milliseconds
det_lag_fmt = "Lag: %d=%3.1fs" -- this shows frames and seconds
ext_lag_fmt = "Lag: %d+%d=%3.1fs" -- this includes missed VSync interrupts in arg2
-- end of configuration --

screen_width = client.screenwidth()
screen_height = client.screenheight()

frames = {}

-- implement required bitops for mesen from
-- https://github.com/AlberTajuelo/bitop-lua/
if not bit then
  bit = {}
  local floor = math.floor
  local function memoize(f)
    local mt = {}
    local t = setmetatable({}, mt)
    function mt:__index(k)
      local v = f(k)
      t[k] = v
      return v
    end
    return t
  end

  local function make_bitop_uncached(t, m)
    local function bitop(a, b)
      local res,p = 0,1
      while a ~= 0 and b ~= 0 do
        local am, bm = a%m, b%m
        res = res + t[am][bm]*p
        a = (a - am) / m
        b = (b - bm) / m
        p = p*m
      end
      res = res + (a+b) * p
      return res
    end
    return bitop
  end
  
  local function make_bitop(t)
    local op1 = make_bitop_uncached(t, 2^1)
    local op2 = memoize(function(a)
      return memoize(function(b)
        return op1(a, b)
      end)
    end)
    return make_bitop_uncached(op2, 2^(t.n or 1))
  end
  bit.bxor = make_bitop {[0]={[0]=0,[1]=1},[1]={[0]=1,[1]=0}, n=4}
  bit.band = function(a,b) return ((a+b) - bit.bxor(a,b))/2 end
  bit.rshift = function(a,disp)
    if disp < 0 then return bit.lshift(a,-disp) end
    return floor(a % 2^32 / 2^disp)
  end
  bit.lshift = function(a,disp)
    if disp < 0 then return rshift(a,-disp) end
    return (a * 2^disp) % 2^32
  end
  bit.bswap = function(x)
    local a = band(x, 0xff); x = rshift(x, 8)
    local b = band(x, 0xff); x = rshift(x, 8)
    local c = band(x, 0xff); x = rshift(x, 8)
    local d = band(x, 0xff)
    return lshift(lshift(lshift(a, 8) + b, 8) + c, 8) + d
  end
  bit.rrotate = function(x, disp)
    disp = disp % 32
    local low = bit.band(x, 2^disp-1)
    return bit.rshift(x, disp) + bit.lshift(low, 32-disp)
  end
  bit.lrotate = function(x, disp)
    return bit.rrotate(x, -disp)
  end
  bit.rol = bit.lrotate
  bit.ror = bit.rrotate
end

-- default fontsize
local fontw = 1
local fonth = 1

-----------------------------------------------
-- snes9x Bizhawk compatibility layer by Nethraz
-- + mesen compatibility layer by black_sliver
if emu and emu.memType ~= nil and bizstring == nil then
  -- detect mesen by existance of emu.memType
  fontw = 2 -- font is bigger in mesen
  fonth = 2 -- font is bigger in mesen
  is_mesen = true
  memory = {}
  gui = {}
  event = {}
  local decode_addr = function(addr)
    return addr, emu.memType.cpu
  end
  memory.usememorydomain = function()
    -- mesen works differently
  end
  memory.read_u8 = function(addr)
    local addr,t = decode_addr(addr)
    return emu.read(addr, t, false)
  end
  memory.read_s8 = function(addr)
    local addr,t = decode_addr(addr)
    return emu.read(addr, t, true)
  end
  memory.read_u16_le = function(addr)
    local addr,t = decode_addr(addr)
    return emu.read(addr, t, false) + 0x100*emu.read(addr+1, t, false)
  end
  memory.read_s16_le = function(addr)
    local addr,t = decode_addr(addr)
    return emu.readWord(addr, t, true)
  end
  memory.read_u24_le = function(addr)
    local addr,t = decode_addr(addr)
    return (emu.read(addr, t, false) + 0x100*emu.read(addr+1, t, false)
           + 0x10000*emu.read(addr+2, t, false))
  end
  memory.read_s24_le = function(addr)
    local val = memory.read_u24_le(addr)
    if (val > 0x7fffff) then val = val - 0x800000 - 0x800000 end
    return val
  end
  memory.read_u32_le = function(addr)
    local addr,t = decode_addr(addr)
    return (emu.read(addr, t, false) + 0x100*emu.read(addr+1, t, false)
           + 0x10000*emu.read(addr+2, t, false)
           + 0x1000000*emu.read(addr+3, t, false))
  end
  memory.read_s32_le = function(addr)
    local val = memory.read_u32_le(addr)
    if (val > 0x7fffffff) then val = val - 0x80000000 - 0x80000000 end
    return val
  end
  memory.read_u16_be = function(addr) return bit.rshift(bit.bswap(memory.read_u16_le(addr)),16) end
  memory.readbyterange = function(addr,len)
    res = {}
    local addr,t = decode_addr(addr)
    for i=0,len-1 do
      res[i] = emu.read(addr+i, t, false)
    end
    return res
  end
  memory.write_u8 = function(addr, val)
    local addr,t = decode_addr(addr)
    return emu.write(addr, val, t)
  end
  memory.write_u32_le = function(addr, val)
    local addr,t = decode_addr(addr)
    emu.write(addr,   bit.band(val,0xff), t)
    emu.write(addr+1, bit.band(bit.rshift(val,8),0xff), t)
    emu.write(addr+2, bit.band(bit.rshift(val,16),0xff), t)
    emu.write(addr+3, bit.band(bit.rshift(val,24),0xff), t)
  end
  local color_b2m = function(bizhawk_color)
    -- if numeric then same as bizhawk but alpha is inverse
    if bizhawk_color == nil then return nil end
    return bit.band(bizhawk_color,0x00ffffff)+(0xff000000-bit.band(bizhawk_color,0xff000000))
  end
  gui.drawText = function(x,y,text,color)
    emu.drawString(x,y,text,color_b2m(color))
  end
  gui.text = gui.drawText -- ???
  gui.drawLine = function(x1,y1,x2,y2,color)
    emu.drawLine(x1,y1,x2,y2,color_b2m(color))
  end
  gui.drawRectangle = function(x,y,w,h,outline_color,fill_color)
    if outline_color == fill_color then
      emu.drawRectangle(x,y,w,h,color_b2m(outline_color),true)
    elseif color_b2m(fill_color) then
      emu.drawRectangle(x,y,w,h,color_b2m(outline_color),false)
      emu.drawRectangle(x+1,y+1,w-2,h-2,color_b2m(fill_color),true)
    else
      emu.drawRectangle(x,y,w,h,color_b2m(outline_color),false)
    end
  end
  gui.drawBox = function(x1,y1,x2,y2,outline_color,fill_color)
    if x2<x1 then
        local tmp=x1; x1=x2; x2=tmp
    end
    if y2<y1 then
        local tmp=y1; y1=y2; y2=tmp
    end
    return gui.drawRectangle(x1,y1,x2-x1+1,y2-y1+1,outline_color,fill_color)
  end
  event.onframeend = function(luaf)
    emu.addEventCallback(luaf, emu.eventType.endFrame)
  end
elseif not event then
  -- detect snes9x by absence of 'event'
  is_snes9x = true
  memory.usememorydomain = function()
    -- snes9x always uses "System Bus" domain, which cannot be switched
  end
  memory.read_u8 = memory.readbyte
  memory.read_s8 = memory.readbytesigned
  memory.read_u16_le = memory.readword
  memory.read_s16_le = memory.readwordsigned
  memory.read_u32_le = memory.readdword
  memory.read_s32_le = memory.readdwordsigned
  memory.read_u24_le = function(addr) return memory.read_u16_le(addr) + 0x10000*memory.read_u8(addr+2) end
  memory.read_u16_be = function(addr) return bit.rshift(bit.bswap(memory.read_u16_le(addr)),16) end
  memory.write_u8 = memory.writebyte
  memory.write_u32_le = function(addr, val)
    memory.writebyte(addr,   bit.band(val,0xff))
    memory.writebyte(addr+1, bit.band(bit.rshift(val,8),0xff))
    memory.writebyte(addr+2, bit.band(bit.rshift(val,16),0xff))
    memory.writebyte(addr+3, bit.band(bit.rshift(val,24),0xff))
  end
  local color_b2s = function(bizhawk_color)
    if bizhawk_color == nil then return nil end
    return bit.rol(bizhawk_color,8)
  end
  gui.drawText = function(x,y,text,color)
    gui.text(x,y,text,color_b2s(color))
  end
  gui.drawLine = function(x1,y1,x2,y2,color)
    gui.line(x1,y1,x2,y2,color_b2s(color))
  end
  gui.drawBox = function(x1,y1,x2,y2,outline_color,fill_color)
    gui.box(x1,y1,x2,y2,color_b2s(fill_color),color_b2s(outline_color))
  end
  event = {}
  event.onframeend = function(luaf,name)
    local on_gui_update_old = gui.register(nil)
    local function on_gui_update_new()
      if on_gui_update_old then
        on_gui_update_old()
      end
      luaf()
    end
    gui.register(on_gui_update_new)
  end
else
  is_bizhawk = true
end

function DrawNiceText(text_x, text_y, str, color)
  --local sh = client.screenheight
  --local sw = client.screenwidth
  if is_snes9x or is_mesen then 
    gui.text(text_x, text_y, str, color)
  else
    local calc_x = client.transformPointX(text_x)
    local calc_y = client.transformPointY(text_y)
    gui.text(calc_x, calc_y, str, color)
  end
end

-- End of Bizhawk compatibility layer
-----------------------------------------------



memory.usememorydomain("System Bus")

local map_id
local camera_x
local camera_y
local trig_off_x
local trig_off_y
local frames0
local timer0
local emuframes = 0
local market_running = false

local function gameDrawBox(x1, y1, x2, y2, color1, color2)
  --console.writeline("x1 : "..x1.." : y1 : "..y1)
  gui.drawBox(x1 - camera_x, y1 - camera_y, x2 - camera_x, y2 - camera_y, color1, color2)
end

local function gameDrawPoint(x, y, color1, color2)
  --console.writeline("x1 : "..x1.." : y1 : "..y1)
  local r = 5
  gui.drawBox(x - camera_x - r, y - camera_y - r, x - camera_x + r, y - camera_y + r, color1, color2)
  gui.drawBox(x - camera_x, y - camera_y, x - camera_x, y - camera_y, color1, color2)
end

local function gameDrawText(x, y, text, color)
   if color == nil then -- default to freen
      if mesen then color=0x7700ff00 else color=0xff00ff00 end
   end
   DrawNiceText(x - camera_x, y - camera_y, text, color)
end

local function gameDrawLine(x1, y1, x2, y2, color)
   if color == nil then -- default to freen
      if mesen then color=0x7700ff00 else color=0xff00ff00 end
   end
   gui.drawLine(x1 - camera_x, y1 - camera_y, x2 - camera_x, y2 - camera_y, color)
end

local stype_to_name = {
  [0x0A70] = "Le_Dog",
  [0x0A26] = "Le_Boy",
  [0xD4D2] = "Bone Snake",
  [0xD6D8] = "Maggot",
  [0xD722] = "Moskito"
}

local function update_frame_rate()
	local current_time = os.clock()
	local too_old = current_time - seconds_for_averages
	
	local frame = {
		current_time = current_time
	}

	frames['current_frame'] = frame
	table.insert(frames, frame)
	
	for i, frame in pairs(frames) do
		if frame['current_time'] < too_old then
			table.remove(frames, i)
			--console.writeline("removed frame")
		end
	end
	
	return frame
end

-- 7E3DE5 to 7E4E88 = Monster/NPC data for the current room. Each Monster/NPC gets x8E bytes of data.
                  -- x00-x02 = Sprite/Animation script pointer
                  -- x03-x05 = Sprite/Animation script pointer
                  -- x06-x07 = Partial pointer to a ROM location with Monster/NPC data / likely gfx index
                  -- x1A-x1B = X position on map
                  -- x1C-x1D = Y position on map
                  -- x22-x23 = Used to determine the direction creature is facing
                  -- x24-x25 = Pointer to ram address of the target of the monster's attacks
                  -- x2A-x2B = Hit Points
                  -- x2E-x2F = Charge level for attack.
                  -- x5E-x5F = Pointer to data structure of next valid entity.  0 if end of list.
                  -- x60-x61 = Used to identify the type of monster/npc
                  -- x62-x63 = X,Y position on the map in terms of tiles
                  -- x66-x67 = Dialog/Event indicator
                  -- x68-x69 = Flags that determine when Event specified in x66-x67 is triggered
                            -- (0040 = occurs when player presses talk/activate in proximity to NPC)
                            -- (0100 = occurs when NPC takes damage)
                            -- (0200 = occurs when NPC is killed)
                  -- x76-x77 = damage taken from last attack


local function hit_raw(sprite, value)
	value = value or "evasion"

	local boy_hit = memory.read_u16_le(0x7E0A47)
	local sprite_rom_offset = bit.band(((sprite[value] + 1) / 2), 0xFFFE)
	local evasion_rom = memory.read_u16_le(0x8fbaaf + sprite_rom_offset)
	local boy_hit_offset = bit.band(boy_hit + 1, 0xFFFC) / 2
	
	-- console.writeline(string.format("%s = boy_hit=%04X, sprite_evasion=%04X, sprite_rom_offset=%04X, boy_hit_offset=%04X, evasion_rom=%04X, sum=%04X, boy_sprite_hit=%04f",  sprite['name'],  boy_hit,  sprite['evasion'], sprite_rom_offset, boy_hit_offset, evasion_rom, sum, percentage))
  
	return memory.read_u16_le(0x8F0000 + boy_hit_offset + evasion_rom)
end

local function hit_percentage(sprite, value)
	local sum = hit_raw(sprite, value)
	
	return sum / 0x7FFF * 100
end

local function join_data_map(map, devider, string_format)
	devider = devider or ","
	string_format = string_format or "% 4X"
	local result = ""

	for i, number in pairs(map) do
		result = result .. string.format(string_format, number) .. devider
	end
	
	return result
end

function math.average(t)
	local sum = 0
	for _,v in pairs(t) do -- Get the sum of all numbers in t
		sum = sum + v
	end
	return sum / #t
end


local function attack_modifier_boy(attack, energy)
	if energy < 0x200 then
		return bit.rshift(attack, 2)
	end
	if energy < 0x400 then
		return bit.rshift(attack, 1)
	end
	
	return bit.rshift(attack, 0)
end

local damage_range_for_enemies = {}
local function damage_from_boy(sprite, attack, energy, monster_type)
	attack_modified = bit.band(attack_modifier_boy(attack, energy), 0xffff)
	index = string.format("%d_%d", monster_type, attack_modified)
	
	monster_resistence = memory.read_u16_le(0x8e001b + monster_type)
	
	wram0012 = bit.band(bit.bnot(bit.band(bit.rshift(monster_resistence, 2) - attack_modified, 0xffff) - 1), 0xffff)
	if wram0012 >= 0x8000 then wram0012 = 1 end
	wram0002 = wram0012 + 1
	
	damage = {}
	
	if damage_range_for_enemies[index] == nil then
		for i=0x0000, 0xffff do
			wram0010 = bit.band(i, 0xff)
			wram0011 = bit.band(bit.rshift(i, 8), 0xff)
			
			wram000a = bit.band(wram0002 * wram0010, 0xffff)
			wram000a_2 = bit.band(wram0002 * wram0011, 0xffff)
			wram000a_3 = bit.band(wram000a_2 + bit.band(bit.rshift(wram000a, 8), 0xff), 0xffff)
			
			wram000c = bit.band(bit.rshift(wram000a_3, 8), 0xff)
			
			damage_seed = wram000c
			
			dmg = bit.band(bit.rshift(bit.band(bit.band(bit.lshift(bit.band(damage_seed + wram0012, 0xffff), 1), 0xffff) + wram0012, 0xffff), 2), 0xffff)
			
			--if dmg > 0xffff then dmg = dmg % 0xffff end
			if dmg > 999 then dmg = 999 end
			
			table.insert(damage, dmg)
		end
		
		table.sort(damage)
		
		atlas = damage[#damage] >= 999
		damage_range = ""
		console.writeline(string.format("%d-%d", damage[1], damage[#damage]))

		if not atlas then
			j = 0
			last_dmg = -1
			for i, dmg in ipairs(damage) do
				if dmg == last_dmg and i < #damage then
					j = j + 1
				else
					--console.writeline(last_dmg .. "->" .. dmg)
					if j > 0 then
						damage_range = string.format("%s%s%d(%d%%)", damage_range, string.len(damage_range) > 0 and "," or "", last_dmg, 100.0*j/#damage)
					end
					j = 1
					last_dmg = dmg
				end
			end
		else
			j = 0
			for i, dmg in ipairs(damage) do
				if dmg >= 999 then
					j = j + 1
				end
			end
			chance = 100.0*j/#damage
			
			damage_range = string.format("%d (%d%%)", damage[#damage], chance)
		end

		if false and monster_type == 0xd5fa then
			damage_string = join_data_map(damage, ",", "%4X")
		
			--damage_beautified = string.format("\ndmg=%d seed=%X (0012=%X/%X, rng=%X/%X, 000a=%X/%X/%X, 000c=%X)", dmg, damage_seed, wram0012, wram0002, wram0010, wram0011, wram000a, wram000a_2, wram000a_3, wram000c)
			--damage_beautified = string.format("damage[%X]=%s (%d, %d, %d, %d, %d, ... %d, %d, %d) = %s", damage[1], damage[2], damage[3], damage[4], damage[5], damage[#damage - 2], damage[#damage - 1], damage[#damage], damage_string)
			damage_beautified = string.format("%d[%X][%d] = %s", sprite["slot"], #damage, chance, damage_string)
			
			console.writeline(damage_beautified)
		end
		
		damage_range_for_enemies[index] = damage_range
	end
	
	debug_string = string.format("idx=%d, attack=%X (%X), energy=%X, type=%X (%X), wram[0012]=%X (%X), %s",
		sprite["slot"],
		attack, attack_modified, energy,
		monster_type, monster_resistence,
		wram0012, wram0002,
		damage_beautified or damage_range_for_enemies[index] or "nope"
		)
	
	--console.writeline(debug_string)
	
	return damage_range_for_enemies[index]
end

local function load_sprite(idx)
	local sprite = {
		name = "none",
		slot = (idx - 0x3DE5) / 0x8E,
		index = idx,
		anim_ptr1 = memory.read_u24_le(0x7E0000 + idx),
		anim_ptr2 = memory.read_u24_le(0x7E0000 + idx + 3),
		rom_ptr = mainmemory.read_u16_le(idx + 6),
		boy_hit = mainmemory.read_u16_le(idx + 0x10),
		z_layer = mainmemory.read_u16_le(idx + 0x18),
		unknow = {},
		--unknown[1] = mainmemory.read_u16_le(idx + 0x8), -- 00 
		--unknown[2] = mainmemory.read_u16_le(idx + 0xA), -- 00 when moving
		--unknown[3] = mainmemory.read_u16_le(idx + 0xC),
		--unknown[4] = mainmemory.read_u16_le(idx + 0xE), -- counter
		pos_x = mainmemory.read_u16_le(idx + 0x1A),
		pos_y = mainmemory.read_u16_le(idx + 0x1C),
		--unknown[5] = mainmemory.read_u16_le(idx + 0x1E),
		z_pos = mainmemory.read_u16_le(idx + 0x1E),
		--evasion = mainmemory.read_u16_le(idx + 0x1F),
		--unknown[6] = mainmemory.read_u16_le(idx + 0x20),
		hit_rate = mainmemory.read_u16_le(idx + 0x21),
		direction = mainmemory.read_u16_le(idx + 0x22),
		target = mainmemory.read_u16_le(idx + 0x24),
		--unknown[7] = mainmemory.read_u16_le(idx + 0x26),
		--unknown[8] = mainmemory.read_u16_le(idx + 0x28),
		hp = mainmemory.read_u16_le(idx + 0x2A),
		--unknown[9] = mainmemory.read_u16_le(idx + 0x2C),
		charge_lvl = mainmemory.read_u16_le(idx + 0x2E),
		--unknown[10] = mainmemory.read_u16_le(idx + 0x30),
		--unknown[11] = mainmemory.read_u16_le(idx + 0x32),
		--unknown[12] = mainmemory.read_u16_le(idx + 0x34),
		--unknown[13] = mainmemory.read_u16_le(idx + 0x36),
		ptr_next = mainmemory.read_u16_le(idx + 0x5E),
		stype = mainmemory.read_u16_le(idx + 0x60),
		x_tile = mainmemory.read_u8(idx + 0x62),
		y_tile = mainmemory.read_u8(idx + 0x63),
		diagev = mainmemory.read_u16_le(idx + 0x66),
		diagev_flag = mainmemory.read_u16_le(idx + 0x68),
		dmg_taken = mainmemory.read_u16_le(idx + 0x76)
	}
	local piko = memory.read_u24_le(0xCE0000 + sprite['stype'])
	--console.writeline(string.format("%04X %06X", sprite['stype'] + 0xCE0000 + 0xB678 - 0xA26, piko))
	local bytesname = memory.readbyterange(piko, 32)
	local strname = ''
	for i=0, (32 - 1) do
		--console.write(string.format("%d :  %d", bytesname[i], tonumber(bytesname[i], 16)))
		--console.write('-')
		if bytesname[i] == 0 or bytesname[i] == nil then
			break
		end
		strname = strname .. string.char(bytesname[i])
	end
	--console.writeline(strname)
	--console.writeline(memory.read_u16_le(0xCE0000 + sprite['stype'] + 0xD))
	sprite['name'] = strname
	sprite['unknown'] = {}
	sprite['unknown'][1] = mainmemory.read_u16_le(idx + 0x8) -- 00
	sprite['unknown'][2] = mainmemory.read_u16_le(idx + 0xA)
	sprite['unknown'][3] = mainmemory.read_u16_le(idx + 0xC)
	sprite['unknown'][4] = mainmemory.read_u16_le(idx + 0xE) -- counter
	sprite['unknown'][5] = mainmemory.read_u16_le(idx + 0x1E)
	sprite['unknown'][6] = mainmemory.read_u16_le(idx + 0x20)
	sprite['unknown'][7] = mainmemory.read_u16_le(idx + 0x26)
	sprite['unknown'][8] = mainmemory.read_u16_le(idx + 0x28)
	sprite['unknown'][9] = mainmemory.read_u16_le(idx + 0x2C)
	for i = 0, 23 do
		sprite['unknown'][i + 10] = mainmemory.read_u16_le(idx + 0x30 + i * 2)
	end
	sprite['unknown'][34] = mainmemory.read_u16_le(idx + 0x6A)
	sprite['unknown'][35] = mainmemory.read_u16_le(idx + 0x6C)
	sprite['unknown'][36] = mainmemory.read_u16_le(idx + 0x6E)
	sprite['unknown'][37] = mainmemory.read_u16_le(idx + 0x70)
	sprite['unknown'][38] = mainmemory.read_u16_le(idx + 0x72)
	sprite['unknown'][39] = mainmemory.read_u16_le(idx + 0x74)
	sprite['unknown'][40] = mainmemory.read_u16_le(idx + 0x78)
	sprite['unknown'][41] = mainmemory.read_u16_le(idx + 0x7A)
	sprite['unknown'][42] = mainmemory.read_u16_le(idx + 0x7C)
	sprite['unknown'][43] = mainmemory.read_u16_le(idx + 0x7E)
	sprite['unknown'][44] = mainmemory.read_u16_le(idx + 0x80)
	sprite['unknown'][45] = mainmemory.read_u16_le(idx + 0x82)
	sprite['unknown'][46] = mainmemory.read_u16_le(idx + 0x84)
	sprite['unknown'][47] = mainmemory.read_u16_le(idx + 0x86)
	sprite['unknown'][48] = mainmemory.read_u16_le(idx + 0x88)
	sprite['unknown'][49] = mainmemory.read_u16_le(idx + 0x8A)
	sprite['unknown'][50] = mainmemory.read_u16_le(idx + 0x8C)
	sprite['unknown'][51] = mainmemory.read_u16_le(idx + 0x8E)

	sprite['evasion'] = memory.read_u16_le(0x8E001F + sprite['stype'])

	sprite['evasion_rom'] = hit_raw(sprite)
	sprite['evasion_%'] = hit_percentage(sprite)


	sprite['x_avg'] = 0
	sprite['y_avg'] = 0
	
	if #frames > 1 then
		--console.writeline("###############" .. string.format("frames=%d", #frames))
		local x = {}
		local y = {}
		for i, f in pairs(frames) do
			if f['sprites'] ~= nil then
				--console.writeline(string.format("time=%d, #sprites=%d", f['current_time'], #f['sprites']))
				for i, s in pairs(f['sprites']) do
					if s['index'] == sprite['index'] then
						--console.writeline(string.format("x=%d", sprite['pos_x']))
						table.insert(x, s['pos_x'])
						table.insert(y, s['pos_y'])
					end
				end
			end
		end
		
		if #x > 1 and #y > 1 then
			sprite['x_avg'] = (x[#x] - x[1]) / seconds_for_averages
			sprite['y_avg'] = (y[#y] - y[1]) / seconds_for_averages
		
			--console.writeline(string.format("[%04X] delta=%d/%d, 0=%d/%d - 1=%d/%d", sprite['index'], sprite['x_avg'], sprite['y_avg'], x[1], y[1], x[#x], y[#y]))
		else
			--console.writeline(string.format("[%04X] #x=%d #y=%d", sprite['index'], #x, #y))
		end
	end
	
	if show_damage_rolls then
		sprite['damage_range'] = damage_from_boy(sprite, mainmemory.read_u16_le(0x0A3F), mainmemory.read_u16_le(0x4EB7), sprite['stype'])
	end
	
	-- print_sprite_info(idx)
	return sprite
end

local function print_sprite_info(idx)
    console.writeline(string.format("=====%04X=====", idx))
  for i = 0, 8 do
     local bytes = mainmemory.readbyterange(idx + i * 16, 16)
     for k,v in pairs(bytes) do
         console.write(string.format("%02X ", v))
       end
     console.writeline("")
  end
end

local function load_all_sprites()
	local sprites = {}
	local sprite_start = mainmemory.read_u16_le(0x3DDF)
	
	repeat
		local sprite = load_sprite(sprite_start)
		table.insert(sprites, sprite)
		sprite_start = sprite['ptr_next']
	until (sprite['ptr_next'] == 0)
	
	return sprites
end

local function load_trigger(ptr)
  return {
    pos_y = (memory.read_u8(ptr+0)-trig_off_y)*16,
    pos_x = (memory.read_u8(ptr+1)-trig_off_x)*16,
    h = (memory.read_u8(ptr+2)-memory.read_u8(ptr+0)-1)*16,
    w = (memory.read_u8(ptr+3)-memory.read_u8(ptr+1)-1)*16,
    script = memory.read_u16_le(ptr+4)
  }
end

local function load_all_btriggers()
  triggers = {}
  local dataptr = memory.read_u24_le(0x9ffde7 + map_id*4);
  --local mscriptlistptr = dataptr+0x0d+2;
  local mscriptlistlen = memory.read_u16_le(dataptr+0x0d);
  local bscriptlistptr = dataptr+0x0d+2+mscriptlistlen+2;
  local bscriptlistlen = memory.read_u16_le(dataptr+0x0d+2+mscriptlistlen);
  for ptr=bscriptlistptr,bscriptlistptr+bscriptlistlen-1,6 do
    table.insert(triggers, load_trigger(ptr))
  end
  return triggers
end

local function load_all_steptriggers()
  triggers = {}
  local dataptr = memory.read_u24_le(0x9ffde7 + map_id*4);
  local mscriptlistptr = dataptr+0x0d+2;
  local mscriptlistlen = memory.read_u16_le(dataptr+0x0d);
  for ptr=mscriptlistptr,mscriptlistptr+mscriptlistlen-1,6 do
    table.insert(triggers, load_trigger(ptr))
  end
  return triggers
end

local function draw_map()
  local startx = -(camera_x % 16)
  local starty = -(camera_y % 16)
  local box_x1 = startx
  local box_y1 = starty
  while box_x1 < 260 do
    box_y1 = starty
    while box_y1 < 230 do
      gui.drawBox(box_x1, box_y1, box_x1+16, box_y1 + 16, 0xCCFF0000, 0x11FF0000)
    --gui.drawBox(box_x1, box_y1 + 1, box_x1+16, box_y1 + 16 + 1, 0xCC0000FF, 0x11FF0000)
    box_y1 = box_y1 + 16
    end
    box_x1 = box_x1 + 16
  end
end


local function draw_boy(frame)
	local boy = {
		x = memory.read_s16_le(0x7E4EA3),
		y = memory.read_s16_le(0x7E4EA5),
	}
	
	--gameDrawBox(boy['x'] - 8, boy['y'] - 8, boy['x'] + 8, boy['y'] + 8, 0xFFFFFFFF, 0x7777FFFF)
	--gameDrawBox(boy['x'] - 0, boy['y'] - 0, boy['x'] + 0, boy['y'] + 0, 0xFFFFFFFF, 0x7777FFFF)
	
	frame['boy'] = boy
end

local function draw_sprites(frame)
    frame['sprites'] = load_all_sprites()
    gui.text(0, 0, string.format("Number of sprites:%2d",#frame['sprites']))
    for i, sprite in pairs(frame['sprites']) do
        if show_sprite_data then
            gui.text(0, 50 + i * 60, string.format("%d|%X - stype : %04X/%04X - pos[% 4d, % 4d] - HP: %02d - Tile Pos[% 2d, % 2d]",
                     i, sprite['index'], sprite['stype'], sprite['rom_ptr'], sprite['pos_x'], sprite['pos_y'], sprite['hp'], sprite['x_tile'], sprite['y_tile']), 0xFFFF0000)
            local tmpstr = ""
            for j = 1, 51 do
                tmpstr = tmpstr .. string.format("[%d]% 4X,", j, sprite['unknown'][j])
				if j == 20 or j == 40 then
					tmpstr = tmpstr .. "\n"
				end
            end
            gui.text(0, 50 + (i * 60 + 15), tmpstr)
        end
		
		local labels = {
			left = {
				{ text = string.format("% 4X", sprite['index']), color = 0xFFFFFFFF },
				{ text = string.format("% 4X", sprite['diagev']), color = 0xFFFFFFFF },
				
				{ text = string.format("dx=%3d", sprite['x_avg']), color = 0xFFFF0000 },
				{ text = string.format("dy=%3d", sprite['y_avg']), color = 0xFFFF0000 },
			},
			right = {
				{ text = "\""..sprite['name'].."\"", color = 0xFFFFFFFF },
				{ text = string.format("%3d/%3d/%2d", sprite['pos_x'], sprite['pos_y'], sprite['z_layer']), color = 0xFFFFFF00 },
				{ text = string.format("%dhp", sprite['hp']), color = 0xFFFFFF00 },
				{ text = string.format("%3.1f%%", sprite['evasion_%']), color = 0xFFFFFF00 },
			},
		}
		
		if show_damage_rolls then
			table.insert(labels["right"], { text = string.format("%s", sprite['damage_range']), color = 0xFFFF0000 })
		end
		
		gameDrawBox(sprite['pos_x'] - 8*fontw , sprite['pos_y'] - 8*fonth, sprite['pos_x'] + 8 , sprite['pos_y'] + 8, 0xFFFFFFFF, 0x7777FFFF)
		gameDrawBox(sprite['pos_x'], sprite['pos_y'], sprite['pos_x'], sprite['pos_y'], 0xFFFFFFFF, 0x7777FFFF)
		
		for i, label in ipairs(labels['left']) do
			gameDrawText(sprite['pos_x'] - 8*fontw, sprite['pos_y'] + (-12 + i*4)*fonth, label['text'], label['color'])
		end
		for i, label in ipairs(labels['right']) do
			gameDrawText(sprite['pos_x'] + 8*fontw, sprite['pos_y'] + (-12 + i*4)*fonth, label['text'], label['color'])
		end
		
        if show_script_ids and sprite['diagev_flag'] ~= 0 then
            --gameDrawText(sprite['pos_x'] + 8*fontw, sprite['pos_y'] - 12*fonth, string.format("%04X", sprite['diagev']));
        end
    end
end

local function draw_triggers(triggers, color)
  for i, trigger in pairs(triggers) do
    gameDrawBox(trigger['pos_x'], trigger['pos_y'], trigger['pos_x']+trigger['w']+15, trigger['pos_y']+trigger['h']+15,
                0xFF000000+color, 0x77000000+color)
    if show_script_ids then
      gameDrawText(trigger['pos_x'], trigger['pos_y'], string.format("%X",trigger['script']), 0x77000000+color)
    end
  end
end

local function draw_btriggers()
  local triggers = load_all_btriggers()
  return draw_triggers(triggers, 0xffff00)
end

local function draw_steptriggers()
  local triggers = load_all_steptriggers()
  return draw_triggers(triggers, 0xff00ff)
end

local function seconds2str(t)
   local mn = math.floor(t/60)
   local sc = math.floor(t-60*mn)
   t = math.floor((t- 60*mn - sc)*10)
   return string.format("%02d:%02d.%d", mn,sc,t)
end

local function draw_timing()
   local market = memory.read_u16_le(0x7E2513);
   local timer  = memory.read_u24_le(0x7E0B19);
   local frame = memory.read_u24_le(0x7E0100);
   local dTimer = (timer-timer0)
   if market>0 then -- market timer started
      if not market_running then
        emuframes = 0
        frames0 = frame
        timer0 = timer
        dTimer = 0
        market_running = true
      end
      if bit.band(memory.read_u8(0x7e225f),0x20)==0 then -- not vigor dead
         local s = "Market: "
         if bit.band(memory.read_u8(0x7e225d),0x08)==0x08 then -- market timer expired
            s = s.."00:00.0"
         else
            s = s..seconds2str((bit.band(0xffff,market-timer+0xc4e0))/FPS)
         end
         if show_actual_market_time then
            s = s.."/"..seconds2str((0xc4e0+(emuframes-dTimer))/FPS)
         end
         if show_lag then gui.text(190,35,s) else gui.text(0,35,s) end
      else
         market_running = false
      end
   else
      market_running = false
   end
   if show_lag then
      local dFrames = (frame-frames0)
      -- NOTE: depending on where we start the script, we may have a diff of 1 in frame count
      if emuframes-dFrames > 1 and show_lag_details then
         gui.text(0, 35, string.format(ext_lag_fmt,
            dFrames-dTimer, emuframes-dFrames, (emuframes-dTimer)/FPS))
      elseif show_lag_details then
         gui.text(0, 35, string.format(det_lag_fmt,
            dFrames-dTimer, (dFrames-dTimer)/FPS))
      else
         gui.text(0, 35, string.format(lag_fmt,
            (emuframes-dTimer)/FPS))
      end
   end
   
	 gui.text(0, 50, string.format("Emulator fps: %d", #frames))
end

local function load_script(idx, sprites)
	local script = {
		location = memory.read_u24_le(0x7E28FC + idx * 0x4f + 0x00), -- x00-x02 = Script location
		state = memory.read_u16_le(0x7E28FC + idx * 0x4f + 0x03), -- x03-x04 = 4 = Standby (Timer); 2 = Executing
		timer1 = memory.read_u16_le(0x7E28FC + idx * 0x4f + 0x05), -- x05-x08 = Timer value for trigger
		timer2 = memory.read_u16_le(0x7E28FC + idx * 0x4f + 0x07), -- x05-x08 = Timer value for trigger
		timer3 = memory.read_u16_le(0x7E28FC + idx * 0x4f + 0x09), -- x09-0A
		next_script = memory.read_u16_le(0x7E28FC + idx * 0x4f + 0x0B), -- x0B-x0C = Pointer to data structure of next valid entity; 0 if end of list
		entity = memory.read_u16_le(0x7E28FC + idx * 0x4f + 0x0D), -- x0D-x0E = Responsible entity
		unknown = {}, -- x05-x4F
		
		-- misc
		unknown_string = "",
		entity_name = "[unknown]",
		next_slot = "--",
		
		color = 0xFFFFFFFF
	}
	
	if show_scripts_unknown then
		for i=0xf, 0x4F - 1 do
			local value = memory.read_u8(0x7E28FC + idx * 0x4f + i)
			table.insert(script['unknown'], value)
		end
		script['unknown_string'] = join_data_map(script['unknown'], "", "% 2X")
	else
		script['unknown_string'] = "-"
	end
	
	script['known_string'] = string.format("% 4X% 2X% 3X", script['timer1'], script['timer2'], script['timer3'])
	
	script['entity_name'] = string.format("%04X", script['entity'])
	for i, sprite in pairs(sprites) do
		if sprite['index'] == script['entity'] then
			script['entity_name'] = script['entity_name'] .. string.format("/\"%s\"", sprite['name'])
		end
	end
	
	if script['state'] == 4 then
		script['color'] = 0xFFFFFF00 --"Standby"
	elseif script['state'] == 2 then
		script['color'] = 0xFF00FF00 --"Executing"
	elseif script['state'] == 0 then
		script['color'] = 0xFFFF0000
	end
	
	if not(script['next_script'] == 0) then
		script['next_slot'] = string.format("%2d", (script['next_script'] - 0x28FC) / 0x4F)
	end
	
	return script
end

local function load_all_scripts(frame)
    local scripts = {}
	
	for i=0, 20 - 1 do
		local script = load_script(i, frame['sprites'])
		
		--console.writeline(script['location'])
		if not (script['location'] == 0) then
			scripts[i] = script
		end
	end
	
	frame['scripts'] = scripts
	
    return scripts
end

local function draw_scripts(frame)
	if not show_scripts then return end
	
    scripts = load_all_scripts(frame)
	local x = 0
	local y = screen_height - 21 * 16
	
    gui.text(x, y, string.format("Number of scripts:% 2d/20 ([slot], location, [args], id/\"name\")", #scripts + 1))
    for i, script in pairs(scripts) do
		-- console.writeline(string.format("script[%d](location=%03X, active=%02X, timer=%03X, next=%02X, entity=%02X", i, script['location'], script['active'], script['timer'], script['next_script'], script['entity']))
        gui.text(x, y + 15*(i + 1), string.format("[%2d][%s](% 6X, [%s][%s][%s]",
				i,
				script['next_slot'],
				script['location'],
				script['known_string'],
				script['unknown_string'],
				script['entity_name']),
			script['color']);
    end
end

local watchers = {
	[-1] = { -- template for random boss battles
		function() return string.format("0x23bf = %04X\n(?)", mainmemory.read_u16_le(0x23bf)) end,

		function() return string.format("0x242f = %04X\n(?)", mainmemory.read_u16_le(0x242f)) end,
		function() return string.format("0x242b = %04X\n(?)", mainmemory.read_u16_le(0x242b)) end,
		function() return string.format("0x242d = %04X\n(?)", mainmemory.read_u16_le(0x242d)) end,
		function() return string.format("0x24ab = %04X\n(?)", mainmemory.read_u16_le(0x24ab)) end,
		function() return string.format("0x24a5 = %04X\n(?)", mainmemory.read_u16_le(0x24a5)) end,
		function() return string.format("0x24a7 = %04X\n(?)", mainmemory.read_u16_le(0x24a7)) end,
		function() return string.format("0x24af = %04X\n(?)", mainmemory.read_u16_le(0x24af)) end,
		function() return string.format("0x24b3 = %04X\n(?)", mainmemory.read_u16_le(0x24b3)) end,
		function() return string.format("0x24b5 = %04X\n(?)", mainmemory.read_u16_le(0x24b5)) end,
		function() return string.format("0x24b7 = %04X\n(?)", mainmemory.read_u16_le(0x24b7)) end,
		function() return string.format("0x24db = %04X\n(?)", mainmemory.read_u16_le(0x24db)) end,
		
		function() return string.format("0x2834 = %04X\n(?)", mainmemory.read_u16_le(0x2834)) end,
		function() return string.format("0x2837 = %04X\n(?)", mainmemory.read_u16_le(0x2837)) end,
		function() return string.format("0x284b = %04X\n(?)", mainmemory.read_u16_le(0x284b)) end,
	},
	
	-- Act 1
	[0x18] = { -- thraxx,
		--function() return string.format("Thraxx = %04X\n(-)", mainmemory.read_u16_le(0x2869)) end,
		
		function()
			gameDrawPoint(0xb8, 0xf0, 0x77008080, 0x77FFFFFF) --0x17, 0x2a?
			
			return string.format("Hit counter = %2d\n(Bonus = counter * 1|2|9|10)", mainmemory.read_u16_le(0x2863))
		end,
		function() return string.format("Cage bonus = %d\n(Opens for >= 5 dmg)", mainmemory.read_u16_le(0x2861)) end,
		
		function() return string.format("Thraxx HP old = %3d\n(-)", mainmemory.read_u16_le(0x2841)) end,
		function() return string.format("Bonus dmg = %d\n(Hit * 1,2,9,10, >hp_old?)", mainmemory.read_u16_le(0x283f)) end,
		
		function() return string.format("0x2853 = %04X\n(<4?)", mainmemory.read_u16_le(0x2853)) end,
		function() return string.format("0x286d = %04X\n(==1?)", mainmemory.read_u16_le(0x286d)) end,
		function() return string.format("0x286b = %04X\n(==1?)", mainmemory.read_u16_le(0x286b)) end,
		function() return string.format("0x2834 = %04X\n(cutscene flags?)", mainmemory.read_u16_le(0x2834)) end,
	},
	[0x27] = { -- viper commander graveyard
		function() return string.format("0x284b = %04X\n(?)", mainmemory.read_u16_le(0x284b)) end,
		function() return string.format("0x24b3 = %04X\n(?)", mainmemory.read_u16_le(0x24b3)) end,
		function() return string.format("0x24b5 = %04X\n(?)", mainmemory.read_u16_le(0x24b5)) end,
		function() return string.format("0x24b7 = %04X\n(?)", mainmemory.read_u16_le(0x24b7)) end,
		function() return string.format("0x24af = %04X\n(?)", mainmemory.read_u16_le(0x24af)) end,
		function() return string.format("0x24a7 = %04X\n(?)", mainmemory.read_u16_le(0x24a7)) end,
		function() return string.format("0x24db = %04X\n(?)", mainmemory.read_u16_le(0x24db)) end,
		function() return string.format("0x24a5 = %04X\n(?)", mainmemory.read_u16_le(0x24a5)) end,
		function() return string.format("0x2837 = %04X\n(?)", mainmemory.read_u16_le(0x2837)) end,
		function() return string.format("0x2834 = %04X\n(?)", mainmemory.read_u16_le(0x2834)) end,
	},
	[0x66] = { -- swamp entrance
		function() return string.format("0x2835 = %04X\n(>5?)", mainmemory.read_u16_le(0x2835)) end,
	},
	[0x01] = { -- salabog
		--function() return string.format("salabog = %04X\n(-)", mainmemory.read_u16_le(0x24e5)) end,
		
		function()
			local x = mainmemory.read_u16_le(0x24d9)
			local y = mainmemory.read_u16_le(0x24db)
			
			gameDrawPoint(0x48, 0x110, 0x77008080, 0x77FFFFFF)
			gameDrawPoint(0xb8, 0x110, 0x77008080, 0x77FFFFFF)
			gameDrawPoint(0xf0, 0x110, 0x77008080, 0x77FFFFFF)
			gameDrawPoint(0x130, 0x110, 0x77008080, 0x77FFFFFF)
			gameDrawPoint(0x1d8, 0x110, 0x77008080, 0x77FFFFFF)
			
			gameDrawPoint(x, y, 0x77ff0000, 0x77FFFFFF)
		
			return string.format("Spawn = %3d/%3d\n(X=72,184,240,472)", x, y)
		end,
		function() return string.format("Salabog diving = %d\n(20, 32?)", mainmemory.read_u16_le(0x22f3)) end,
		function() return string.format("Monster count = %d\n(<3 = spawn?)", mainmemory.read_u16_le(0x2841)) end,
		
		function() return string.format("0x24e3 = %04X\n(==0? ==4?)", mainmemory.read_u16_le(0x24e3)) end,
		function() return string.format("0x225e = %04X\n(?)", mainmemory.read_u16_le(0x225e)) end,
		function() return string.format("0x23bf = %04X\n(?)", mainmemory.read_u16_le(0x23bf)) end,
		function() return string.format("0x2834 = %04X\n(?)", mainmemory.read_u16_le(0x2834)) end,
		function() return string.format("0x2837 = %04X\n(?)", mainmemory.read_u16_le(0x2837)) end,
		function() return string.format("0x284b = %04X\n(?)", mainmemory.read_u16_le(0x284b)) end,
		function() return string.format("0x242b = %04X\n(?)", mainmemory.read_u16_le(0x242b)) end,
		function() return string.format("0x242d = %04X\n(?)", mainmemory.read_u16_le(0x242d)) end,
		function() return string.format("0x242f = %04X\n(?)", mainmemory.read_u16_le(0x242f)) end,
		function() return string.format("0x23db = %04X\n(?)", mainmemory.read_u16_le(0x23db)) end,
		
	},
	[0x3F] = { -- magmar
		--function() return string.format("Entity = %04X\n(FE?)", mainmemory.read_u16_le(0x2842)) end,
		--function() return string.format("Entity = %04X\n(?)", mainmemory.read_u16_le(0x2848)) end,
		--function() return string.format("Magmar = %04X\n(?)", mainmemory.read_u16_le(0x2846)) end,
		
		function()
			local x1 = mainmemory.read_u16_le(0x249d)
			local y1 = mainmemory.read_u16_le(0x249f)
			local x2 = mainmemory.read_u16_le(0x24a1)
			local y2 = mainmemory.read_u16_le(0x24a3)
			
			gameDrawPoint(0x28, 0xc8, 0x77008080, 0x77FFFFFF)
			gameDrawText(0x28 - 5, 0xc8 - 5, "never", 0x77008080)
			gameDrawPoint(0x58, 0xd8, 0x77008080, 0x77FFFFFF)
			gameDrawText(0x58 - 5, 0xd8 - 5, "1/3", 0x77008080)
			gameDrawPoint(0x98, 0xf8, 0x77008080, 0x77FFFFFF)
			gameDrawText(0x98 - 5, 0xf8 - 5, "0/2", 0x77008080)
			gameDrawPoint(0xe8, 0xf8, 0x77008080, 0x77FFFFFF)
			gameDrawText(0xe8 - 5, 0xf8 - 5, "never", 0x77008080)
			gameDrawPoint(0x128, 0xd8, 0x77008080, 0x77FFFFFF)
			gameDrawText(0x128 - 5, 0xd8 - 5, "4", 0x77008080)
			gameDrawPoint(0x158, 0xd8, 0x77008080, 0x77FFFFFF)
			gameDrawText(0x158 - 5, 0xd8 - 5, "5", 0x77008080)
			
			gameDrawPoint(0x48, 0x138, 0x77008080, 0x77FFFFFF)
			gameDrawText(0x48 - 5, 0x138 - 5, "5", 0x77008080)
			gameDrawPoint(0x98, 0x148, 0x77008080, 0x77FFFFFF)
			gameDrawText(0x98 - 5, 0x148 - 5, "4", 0x77008080)
			gameDrawPoint(0xa8, 0x128, 0x77008080, 0x77FFFFFF)
			gameDrawText(0xa8 - 5, 0x128 - 5, "never", 0x77008080)
			gameDrawPoint(0xd8, 0x128, 0x77008080, 0x77FFFFFF)
			gameDrawText(0xd8 - 5, 0x128 - 5, "1/3", 0x77008080)
			gameDrawPoint(0xe8, 0x148, 0x77008080, 0x77FFFFFF)
			gameDrawText(0xe8 - 5, 0x148 - 5, "0/2", 0x77008080)
			gameDrawPoint(0x128, 0x168, 0x77008080, 0x77FFFFFF)
			gameDrawText(0x128 - 5, 0x168 - 5, "never", 0x77008080)
			
			gameDrawPoint(x1, y1, 0x77ff0000, 0x77FFFFFF)
			gameDrawText(x1 - 5, y1 - 5, "start", 0x77ff0000)
			gameDrawPoint(x2, y2, 0x77ff0000, 0x77FFFFFF)
			gameDrawText(x2 - 5, y2 - 5, "end", 0x77ff0000)
			gameDrawLine(x1, y1, x2, y2, 0x77ff0000)
			
			return string.format("Jump = %3d/%3d -> %3d/%3d\n(Jump ltr: 1/3, 0/2, 4, 5)", x1, y1, x2, y2)
		end,
		function() return string.format("0x2834 = %04X\n(? 2 = no heatwave)", mainmemory.read_u16_le(0x2834)) end,
		function()
			local rng = mainmemory.read_u16_le(0x2835)
			return string.format("Spawn/jump rng = %1d (%02X)\n(Spawn ltr: 1/3, 0/2, 4, 5)", bit.band(rng, 0x5), rng)
		end,
		function() return string.format("Out of lava timer = %2d\n(==4 = out, >=20 = in)", mainmemory.read_u16_le(0x284a)) end,
		function() return string.format("Unused timer = %d\n(>80 = reset)", mainmemory.read_u16_le(0x284c)) end,
		function() return string.format("Magmar HP old = %3d\n(<750,<500 = heatwave)", mainmemory.read_u16_le(0x2852)) end,
		function() return string.format("Heatwave flags = %X\n(&3 = 2 flags)", bit.band(mainmemory.read_u16_le(0x2834), 0x3)) end,
		function() return string.format("Hit counter = %2d\n(not used?)", mainmemory.read_u16_le(0x284e)) end,
		function() return string.format("Screen shaking timer = %2d\n(<4, >$283e = shaking)", mainmemory.read_u16_le(0x2854)) end,
		function() return string.format("0x283e = %3d\n(shaking threshold?)", mainmemory.read_u16_le(0x283e)) end,
		
		function() return string.format("0x242b = %04X\n(?)", mainmemory.read_u16_le(0x242b)) end,
		function() return string.format("0x242d = %04X\n(?)", mainmemory.read_u16_le(0x242d)) end,
		
		
		--function() return string.format("0x2836 = %04X\n(?)", mainmemory.read_u16_le(0x2836)) end,
		--function() return string.format("0x2838 = %04X\n(?)", mainmemory.read_u16_le(0x2838)) end,
		--function() return string.format("0x283a = %04X\n($2836<<4 / $283e?)", mainmemory.read_u16_le(0x283a)) end,
		--function() return string.format("0x283c = %04X\n($2838<<4 / $283e?)", mainmemory.read_u16_le(0x283c)) end,
		function() return string.format("0x23b9 = %04X\n(+=x283a?)", mainmemory.read_u16_le(0x23b9)) end,
		function() return string.format("0x23bb = %04X\n(+=x283c?)", mainmemory.read_u16_le(0x23bb)) end,
		
		
	},
	
	-- Act 2
	[0x4f] = { -- blimp
		function()
			return string.format("Status #1 = %04X/%3d/%3d\n(Has to be poison (x90))",
				mainmemory.read_u16_le(0x4ECF),
				mainmemory.read_u16_le(0x4ED1),
				mainmemory.read_u16_le(0x4ED3))
		end,
		function() return string.format("Status #2 = %04X/%3d/%3d\n(Has to be confound/plague)",
				mainmemory.read_u16_le(0x4ED5),
				mainmemory.read_u16_le(0x4ED7),
				mainmemory.read_u16_le(0x4ED9))
		end,
		function()
			return string.format("Status #3 = %04X/%3d/%3d\n(Has to be pixie dust)",
				mainmemory.read_u16_le(0x4EDB),
				mainmemory.read_u16_le(0x4EDD),
				mainmemory.read_u16_le(0x4EDF))
		end,
		function() return string.format("Status #4 = %04X/%3d/%3d\n(Has to be defend and atlas)",
				mainmemory.read_u16_le(0x4EE1),
				mainmemory.read_u16_le(0x4EE3),
				mainmemory.read_u16_le(0x4EE5))
		end,
		function() return string.format("Boy Attack = % 4d\n(Underflows to % 5d)",
				mainmemory.read_u16_le(0x0A3F),
				mainmemory.read_u16_le(0x0A3F) - mainmemory.read_u16_le(0x4ED3))
		end,
	},
	[0x0b] = { -- nobilia - palace
		function() return string.format("0x2843 = %04X\n(well enter steps?)", mainmemory.read_u16_le(0x2843)) end,
		function() return string.format("0x2834 = %04X\n(well enter steps?)", mainmemory.read_u16_le(0x2834)) end,
	},
	[0x1B] = { -- desert of doom
		function()
			--local screen = mainmemory.read_u8(0x22fc)
			
			--[0x96e4a4] (09) IF ((($22fd)&0xff) == 4) == FALSE THEN SKIP 113 (to 0x96e51e)
			--[0x96e4ad] (09) IF ((($22fc)&0xff) == 0) == FALSE THEN SKIP 11 (to 0x96e4c1)
			--[0x96e4b6] (29) CALL 0x96e625 Unnamed ABS script 0x96e625
			--[0x96e4ba] (29) CALL 0x96e606 Unnamed ABS script 0x96e606
			
			--[0x96e515] (29) CALL 0x96e5ea Unnamed ABS script 0x96e5ea
			--[0x96e519] (29) CALL 0x96e60a Unnamed ABS script 0x96e60a
			
			--[0x9786bb] (09) IF ((((signed arg8 > signed arg0) && (signed arg8 < signed arg4)) && (signed arg10 > signed arg2)) && (signed arg10 < signed arg6)) == FALSE THEN SKIP 3 (to 0x9786df)
			--[0x9786dc] (a4) CALL 0x03f6 -> 0x9782d6
			
			--[0x978332] (09) IF ((((signed arg1 < signed arg5) || (signed arg3 < signed arg7)) || (signed arg1 > signed arg9)) || (signed arg3 > signed arg11)) == FALSE THEN SKIP 3 (to 0x978356)
			--[0x978353] (04) SKIP 414 (to 0x9784f4)
			
			--[0x9783eb] (09) IF ((((signed arg1 < signed arg5) || (signed arg3 < signed arg7)) || (signed arg1 > signed arg9)) || (signed arg3 > signed arg11)) == FALSE THEN SKIP 3 (to 0x97840f)
			--[0x97840c] (04) SKIP 39 (to 0x978436)
 
			gameDrawBox(0xa9, 0x210, 0xa9 + 0x2d, 0x210 + 0xf, 0x77008080, 0x77FFFFFF)
			gameDrawText(0xa9, 0x210, "warp up", 0x77008080)
			gameDrawBox(0x189, 0x670, 0x1b6, 0x67f, 0x77008080, 0x77FFFFFF)
			gameDrawText(0x189, 0x670, "warp down", 0x77008080)
			
			return string.format("Desert screen = %02d/%02d\n(sting=5/4 and 6/11)",
				mainmemory.read_u8(0x22fd),
				mainmemory.read_u8(0x22fc))
		end,
		function()
			return string.format("screen copy? = %02d/%02d\n(X/Y, debug only?)",
				mainmemory.read_u16_le(0x2537),
				mainmemory.read_u16_le(0x2539))
		end,
		function() return string.format("0x2847 = %04X\n(boat guy? flags? &x4?)", mainmemory.read_u16_le(0x2847)) end,
		function() return string.format("0x22f3 = %04X\n(flags? &=xf7)", mainmemory.read_u16_le(0x22f3)) end,
		function() return string.format("0x2834 = %04X\n(last entity? &x4?)", mainmemory.read_u16_le(0x2834)) end,
		function() return string.format("0x23d5 = %04X\n(?)", mainmemory.read_u16_le(0x23d5)) end,
		function() return string.format("0x2851 = %04X\n(entity?)", mainmemory.read_u16_le(0x2851)) end,
		function() return string.format("0x242f = %04X\n(entity?)", mainmemory.read_u16_le(0x242f)) end,
	},
	[0x0A] = { -- nobilia
		function() return string.format("Old man rng = %04X\n(1-3=mandetory, 6-8=armor)", mainmemory.read_u16_le(0x244f)) end,
		function() return string.format("Egg rng = % 2d\n(0-15, 7 = Egg)", mainmemory.read_u16_le(0x289f)) end,
	},
	[0x1d] = { -- vigor
		--function() return string.format("*Vigor = %04X\n(?)", mainmemory.read_u16_le(0x2835)) end,
		
		function() return string.format("Current AI = %04X\n(0-3, dmg = RAND&5 = 0,1,4,5)", mainmemory.read_u16_le(0x284b)) end,
		function() return string.format("0x2477 = %04X\n(garbage throwing?)", mainmemory.read_u16_le(0x2477)) end,
		function() return string.format("0x2849 = %04X\n(rng=12,14,16,18?)", mainmemory.read_u16_le(0x2849)) end,
		function() return string.format("*(Vigor+x22) = %04X\n(?)", mainmemory.read_u16_le(mainmemory.read_u16_le(0x2835) + 0x22)) end,
		
		function() return string.format("0x2845 = %04X\n(?)", mainmemory.read_u16_le(0x2845)) end,
		function() return string.format("0x2479 = %04X\n(?)", mainmemory.read_u16_le(0x2479)) end,
		function() return string.format("0x2847 = %04X\n(?)", mainmemory.read_u16_le(0x2847)) end,
	},
	[0x2a] = { -- megataur
		--function() return string.format("0x242f = %04X\n(?)", mainmemory.read_u16_le(0x242f)) end,
		--function() return string.format("0x242b = %04X\n(?)", mainmemory.read_u16_le(0x242b)) end,
		--function() return string.format("0x242d = %04X\n(?)", mainmemory.read_u16_le(0x242d)) end,
		
		--function() return string.format("*megataur = %04X\n(-)", mainmemory.read_u16_le(0x2834)) end,
		
		function() return string.format("0x23bf = %04X\n(?)", mainmemory.read_u16_le(0x23bf)) end,
		function() return string.format("0x24e9 = %04X\n(?)", mainmemory.read_u16_le(0x24e9)) end,
		function() return string.format("0x24eb = %04X\n(?)", mainmemory.read_u16_le(0x24eb)) end,
		
		function() return string.format("0x2465 = %04X\n(?)", mainmemory.read_u16_le(0x2465)) end,
		function() return string.format("0x2467 = %04X\n(?)", mainmemory.read_u16_le(0x2467)) end,
	},
	[0x58] = { -- rimsala
		--function() return string.format("*rimsala top = %04X\n(-)", mainmemory.read_u16_le(0x2839)) end,
		--function() return string.format("*rimsala bottom = %04X\n(-)", mainmemory.read_u16_le(0x2839)) end,
		--function() return string.format("*statue #1 = %04X\n(rimsale heal)", mainmemory.read_u16_le(0x283d)) end,
		--function() return string.format("*statue #2 = %04X\n(rimsale heal)", mainmemory.read_u16_le(0x283f)) end,
		--function() return string.format("*statue #3 = %04X\n(rimsale heal)", mainmemory.read_u16_le(0x2841)) end,
		--function() return string.format("*statue #4 = %04X\n(rimsale heal)", mainmemory.read_u16_le(0x2843)) end,
		
		function() return string.format("Damage phase timer = %2d\n(4s)", mainmemory.read_u16_le(0x2835)) end,
		function() return string.format("Statue heal timer = %2d\n(>18s)", mainmemory.read_u16_le(0x2837)) end,
		function() return string.format("0x2849 = %2d\n(timer?)", mainmemory.read_u16_le(0x2849)) end,
		function() return string.format("0x284b = %04X\n(<damge phase timer?)", mainmemory.read_u16_le(0x284b)) end,
	
		function() return string.format("0x242f = %04X\n(?)", mainmemory.read_u16_le(0x242f)) end,
		function() return string.format("0x242b = %04X\n(?)", mainmemory.read_u16_le(0x242b)) end,
		function() return string.format("0x242d = %04X\n(?)", mainmemory.read_u16_le(0x242d)) end,
		
		function() return string.format("0x249d = %04X\n(?)", mainmemory.read_u16_le(0x249d)) end,
		function() return string.format("0x249f = %04X\n(?)", mainmemory.read_u16_le(0x249f)) end,
		function() return string.format("0x24ab = %04X\n(?)", mainmemory.read_u16_le(0x24ab)) end,
		function() return string.format("0x24af = %04X\n(?)", mainmemory.read_u16_le(0x24af)) end,
		function() return string.format("0x24af = %04X\n(?)", mainmemory.read_u16_le(0x24af)) end,
		
		function() return string.format("0x22d8 = %04X\n(?)", mainmemory.read_u16_le(0x22d8)) end,
		function() return string.format("0x23d3 = %04X\n(?)", mainmemory.read_u16_le(0x23d3)) end,
		function() return string.format("0x2264 = %04X\n(DE flags?)", mainmemory.read_u16_le(0x2264)) end,
	},
	[0x09] = { -- aegis
		--function() return string.format("aegis = %04X\n(?)", mainmemory.read_u16_le(0x2862)) end,
		
		function() return string.format("Monster count = %d\n(-)", mainmemory.read_u16_le(0x2868)) end,
		function() return string.format("Active monster = %04X\n(Must be dead)", mainmemory.read_u16_le(0x2870)) end,
		
		function() return string.format("0x23bf = %04X\n(?)", mainmemory.read_u16_le(0x23bf)) end,
		function() return string.format("0x2866 = %04X\n(?)", mainmemory.read_u16_le(0x2866)) end,
		function() return string.format("0x24ab = %04X\n(?)", mainmemory.read_u16_le(0x24ab)) end,
		function() return string.format("0x24af = %04X\n(?)", mainmemory.read_u16_le(0x24af)) end,
		function() return string.format("0x2872 = %04X\n(?)", mainmemory.read_u16_le(0x2872)) end,
		function() return string.format("0x2874 = %04X\n(?)", mainmemory.read_u16_le(0x2874)) end,
	},
	[0x6d] = { -- aquagoth
		function()
			local entity = mainmemory.read_u16_le(mainmemory.read_u16_le(0x283b) + 0x2A)
			return string.format("Boss hp = % 4d\n(<1k + rng&7 = Oglin)", entity)
		end,
		function() return string.format("AI reaction triggered = %1X\n(rng: spell or oglin)", mainmemory.read_u16_le(0x2845)) end,
		
		function() return string.format("0x242b = %04X\n(?)", mainmemory.read_u16_le(0x242b)) end,
		function() return string.format("0x242d = %04X\n(?)", mainmemory.read_u16_le(0x242d)) end,
		function() return string.format("0x242f = %04X\n(?)", mainmemory.read_u16_le(0x242f)) end,
		function() return string.format("0x2863 = %04X\n(?)", mainmemory.read_u16_le(0x2863)) end,
	},
	
	-- Act 3
	[0x19] = { -- footknight
		--function() return string.format("*Footknight = %04X\n(?)", mainmemory.read_u16_le(0x2834)) end,
		
		function() return string.format("0x283c = %04X\n(?)", mainmemory.read_u16_le(0x283c)) end,
		function() return string.format("0x283e = %04X\n(?)", mainmemory.read_u16_le(0x283e)) end,
		function() return string.format("0x2840 = %04X\n(?)", mainmemory.read_u16_le(0x2840)) end,
		function() return string.format("0x2842 = %04X\n(?)", mainmemory.read_u16_le(0x2842)) end,
		function() return string.format("0x242f = %04X\n(?)", mainmemory.read_u16_le(0x242f)) end,
		function() return string.format("0x242b = %04X\n(?)", mainmemory.read_u16_le(0x242b)) end,
		function() return string.format("0x242d = %04X\n(?)", mainmemory.read_u16_le(0x242d)) end,
		function() return string.format("0x242d = %04X\n(?)", mainmemory.read_u16_le(0x242d)) end,
		function() return string.format("0x242b = %04X\n(?)", mainmemory.read_u16_le(0x242b)) end,
	},
	[0x1f] = { -- bad boys
		function() return string.format("x/y = %04d", mainmemory.read_u16_le(0x2835)) end,
		function() return string.format("room = %04d", mainmemory.read_u16_le(0x2839)) end,

		--function() return string.format("*bad boy = %04X\n(?)", mainmemory.read_u16_le(0x2840)) end,
		
		function() return string.format("Boss phase = %d\n(1=crush, 2=storm, 3=nitro)", mainmemory.read_u16_le(0x2842)) end,
		function() return string.format("0x23b9 = %04X\n(RAND&3, 0=boy, 1-3=both? 34s?)", mainmemory.read_u16_le(0x23b9)) end,
		function() return string.format("0x23bb = %04X\n(dog+2a?)", mainmemory.read_u16_le(0x23bb)) end,
		function() return string.format("0x23db = %04X\n(?)", mainmemory.read_u16_le(0x23db)) end,
		function() return string.format("0x2840 = %04X\n(?)", mainmemory.read_u16_le(0x2840)) end,
	},
	[0x22] = { -- dark forest
		function() return string.format("x/y = %04d\n(x +- 1, y +- 10)\n(boys=119, drake=146)\n(alchemist=095, coin=155)", mainmemory.read_u16_le(0x2835)) end,
		-- function() return string.format("room = %04d", mainmemory.read_u16_le(0x2839)) end,
	},
	[0x20] = { -- forest drake
		function() return string.format("x/y = %04d", mainmemory.read_u16_le(0x2835)) end,
		function() return string.format("room = %04d", mainmemory.read_u16_le(0x2839)) end,

		--function() return string.format("*Boss = %04X\n(?)", mainmemory.read_u16_le(0x2835)) end,
		
		function() return string.format("0x23bf = %04X\n(?)", mainmemory.read_u16_le(0x23bf)) end,
	},
	[0x5e] = { -- verminator
		function() return string.format("0x2839 = %2d\n(timer? Spell rng?)", mainmemory.read_u16_le(0x2839)) end,
		function() return string.format("0x23b9 = %04X\n(>10, >5, ==2, ==3?)", mainmemory.read_u16_le(0x23b9)) end,
		function() return string.format("0x2437 = %04X\n(?)", mainmemory.read_u16_le(0x2437)) end,
		function() return string.format("0x23bf = %04X\n(?)", mainmemory.read_u16_le(0x23bf)) end,
		function() return string.format("0x2835 = %04X\n(?)", mainmemory.read_u16_le(0x2835)) end,
	},
	[0x37] = { -- sterling
		function() return string.format("Fireball timer = %3d\n(Timer = RAND&ff+200)", mainmemory.read_u16_le(0x2849)) end,
		function() return string.format("Sterling dead check timer = %2d\n(Timer = 1E)", mainmemory.read_u16_le(0x284b)) end,
		function() return string.format("0x23b9 = %04X\n(throwing? 0,1,2,3)", mainmemory.read_u16_le(0x23b9)) end,
		function() return string.format("0x249d = %04X\n(?)", mainmemory.read_u16_le(0x249d)) end,
		function() return string.format("0x249f = %04X\n(?)", mainmemory.read_u16_le(0x249f)) end,
		function() return string.format("0x242f = %04X\n(?)", mainmemory.read_u16_le(0x242f)) end,
		function() return string.format("0x242b = %04X\n(?)", mainmemory.read_u16_le(0x242b)) end,
		function() return string.format("0x242d = %04X\n(?)", mainmemory.read_u16_le(0x242d)) end,
		
		function() return string.format("0x24ab = %04X\n(boy+26?)", mainmemory.read_u16_le(0x24ab)) end,
		function() return string.format("0x24af = %04X\n(boy+28?)", mainmemory.read_u16_le(0x24af)) end,
	},
	[0x77] = { -- mungola
		function() return string.format("Combat phase = %1d\n(0-3)", mainmemory.read_u16_le(0x283d)) end,
		function() return string.format("Puppet bonus hp = %4d\n(250/kill, up to 5k)", mainmemory.read_u16_le(0x2851)) end,
		function() return string.format("Boss phase = %d\n(0-3)", mainmemory.read_u16_le(0x283d)) end,
		
		function() return string.format("*Puppet = %04X\n(gains upward momentum?)", mainmemory.read_u16_le(0x283b)) end,
		
		function() return string.format("0x242b = %04X\n(?)", mainmemory.read_u16_le(0x242b)) end,
		function() return string.format("0x242d = %04X\n(?)", mainmemory.read_u16_le(0x242d)) end,
		function() return string.format("0x242f = %04X\n(?)", mainmemory.read_u16_le(0x242f)) end,
	},
	
	-- Act 4
	[0x4A] = { -- carltron
		function() return string.format("0x23d9 = %04X\n(?)", mainmemory.read_u16_le(0x23d9)) end,
		function() return string.format("0x285b = %04X\n(<16?)", mainmemory.read_u16_le(0x285b)) end,
		function() return string.format("0x23b9 = %04X\n(<x28, <20, <30?)", mainmemory.read_u16_le(0x23b9)) end,
		
		function() return string.format("0x23bf = %04X\n(?)", mainmemory.read_u16_le(0x23bf)) end,
		function() return string.format("0x238f = %04X\n(?)", mainmemory.read_u16_le(0x238f)) end,
		function() return string.format("0x242b = %04X\n(?)", mainmemory.read_u16_le(0x242b)) end,
		function() return string.format("0x242d = %04X\n(?)", mainmemory.read_u16_le(0x242d)) end,
		function() return string.format("0x2857 = %04X\n(?)", mainmemory.read_u16_le(0x2857)) end,
		function() return string.format("0x24ab = %04X\n(?)", mainmemory.read_u16_le(0x24ab)) end,
		function() return string.format("0x24af = %04X\n(?)", mainmemory.read_u16_le(0x24af)) end,
		function() return string.format("0x24ad = %04X\n(?)", mainmemory.read_u16_le(0x24ad)) end,
		function() return string.format("0x24b1 = %04X\n(?)", mainmemory.read_u16_le(0x24b1)) end,
		function() return string.format("0x2861 = %04X\n(?)", mainmemory.read_u16_le(0x2861)) end,
		function() return string.format("0x2863 = %04X\n(?)", mainmemory.read_u16_le(0x2863)) end,
		function() return string.format("0x285d = %04X\n(?)", mainmemory.read_u16_le(0x285d)) end,
		function() return string.format("0x285f = %04X\n(?)", mainmemory.read_u16_le(0x285f)) end,
		function() return string.format("0x23bb = %04X\n(?)", mainmemory.read_u16_le(0x23bb)) end,
		function() return string.format("0x242f = %04X\n(?)", mainmemory.read_u16_le(0x242f)) end,
		function() return string.format("0x2413 = %04X\n(?)", mainmemory.read_u16_le(0x2413)) end,
		
		--TODO: main loop
	},
}
local function draw_watchers(frame)
	if not show_watchers then return end
	
	local x = screen_width - 250
	local y = 100
	
	local map_id = memory.read_u8(0x7E0ADB);
	local current_watchers = watchers[map_id] or {}
		
    gui.text(x, y, string.format("Watchers[%02X]:", map_id))
    for i, watcher in ipairs(current_watchers) do
        gui.text(x, y + 15 + 45 * (i - 1), watcher(), 0xFF008080);
    end
	
	frame['watchers'] = watchers
	frame['watchers_current'] = current_watchers
end

local function load_alchemy_animation(idx)
	local spell = {
		active = (memory.read_u16_le(0x7E3364 + idx * 0x40 + 0x14) == 0) and 0 or 1,
		
		color = 0xFF00FF00,
	}
	
	return spell
end
local function load_alchemy_projectile(idx)
	local spell = {
		active = (memory.read_u8(0x7E3564 + idx * 0x76 + 0x14) == 0) and 0 or 1,
		
		color = 0xFFFF0000,
	}
	
	return spell
end

local function load_all_spells()
    local spells = {
		projectile = {},
		animation = {}
	}
	
	for i=0, 8 - 1 do
		table.insert(spells['projectile'], load_alchemy_projectile(i))
		table.insert(spells['animation'], load_alchemy_animation(i))
	end
	
    return spells
end

local function load_projectile(idx)
	local projectile = {
		active = (memory.read_u16_le(0x7E6387 + idx * 44 + 0x10) == 0) and 0 or 1,
		
		owner = memory.read_u16_le(0x7E6387 + idx * 44 + 0x10), -- x10-x11 = Pointer to Owner
		
		x = memory.read_u16_le(0x7E6387 + idx * 44 + 0x14), -- x14-x15 = X Position
		y = memory.read_u16_le(0x7E6387 + idx * 44 + 0x16), -- x16-x17 = Y Position
		z = memory.read_u16_le(0x7E6387 + idx * 44 + 0x18), -- x18-x19 = Z Position
		
		lifespan = memory.read_u16_le(0x7E6387 + idx * 44 + 0x1E), -- x1E-x1F = Lifespan
		
		color = 0xFFFF0000,
	}
	
	return projectile
end

local function load_all_projectiles()
    local projectiles = {}
	
	for i=0, 8 - 1 do
		table.insert(projectiles, load_projectile(i))
	end
	
    return projectiles
end


local function draw_alchemy_stack()
	if not show_alchemy then return end
	
	local x = screen_width - 250
	local y = 00
	
	local spells = load_all_spells()
	local projectiles = load_all_projectiles()
	
    gui.text(x, y, string.format("Alchemy:"))
    for i, spell in pairs(spells['projectile']) do
		gui.text(x + 10 * (i - 1), y + 20, string.format("%X", spell['active']), spell['color']);
    end
    for i, spell in pairs(spells['animation']) do
		gui.text(x + 10 * (i - 1), y + 40, string.format("%X", spell['active']), spell['color']);
    end
	
	if not show_projectiles then return end
	
    for i, projectile in pairs(projectiles) do
		gui.text(x + 10 * (i - 1), y + 60, string.format("%d", projectile['active']));
		if projectile['active'] == 1 then
			--gameDrawPoint(projectile['x'], projectile['y'], 0x77FFFFFF, 0x77ff0000)
		end
    end
end

local function draw_projectiles()
	if not show_projectiles then return end
	
	local projectiles = load_all_projectiles()
	
	local x = 1700
	local y = 00
	
	local spells = load_all_spells()
	
    gui.text(x, y, string.format("Projectiles:"))
    for i, projectil in pairs(projectiles) do
		local p_x = bit.band(projectil['x'], 0xffff)
		local p_y = bit.band(projectil['y'], 0xffff)
		gui.text(x, y + 15 * i, string.format("[%d] %3d/%3d %2X/%2X", projectil['active'], p_x, p_y, p_x, p_y));
		gameDrawPoint(p_x, p_x, 0x77FFFFFF, 0x77ff0000)
		
		local r = 5
		gui.drawBox(trig_off_x + p_x - r, trig_off_y + p_y - r, trig_off_x + p_x + r, trig_off_y + p_y + r, 0x77FFFFFF, 0x77ff0000)
		--console.writeline(string.format("%d/%d %d/%d -> %d/%d", p_x, p_y, trig_off_x,trig_off_y, trig_off_x+p_x,trig_off_y+p_y))
    end
end

local function draw_poison()
	local x = 20
	local y = 10
	local w = 200
	local h = 11
	
	local status_effect_1_id = mainmemory.read_u8(0x4ECF)
	local status_effect_1_timer = mainmemory.read_u16_le(0x4ED1)
	local status_effect_1_boost = mainmemory.read_u16_le(0x4ED3)
	
	if not (status_effect_1_id == 0x90) then
		return
	end
	
	local boy_attack = mainmemory.read_u16_le(0x0A3F)
	local safe_range = boy_attack + 60
	
	local function draw_tick(second)
		local dx = w/30*second

		gui.drawLine(x+dx, y, x+dx, y+h, 0xFF000000)
		
		gui.drawText(dx+3, y-2, string.format("%2d", second), 0xFF000000)
	end
	
	local function draw_safe_zone(second, current_second)		
		local dx = w/30*second

		gui.drawBox(x+dx, y, x+dx+(w/30/60)*safe_range, y+h, 0x00000000, 0xFFFFFF00)
	end
	
	gui.drawBox(x, y, x+w, y+h, 0xFF000000, 0xFFFFFFFF)
	
	draw_safe_zone(0)
	draw_safe_zone(8)
	draw_safe_zone(16)
	draw_safe_zone(24)
	
	gui.drawBox(x, y, x+(w/30/60)*status_effect_1_timer, y+h, 0x00000000, (status_effect_1_boost > safe_range) and 0xFF00FF00 or 0xFFFF0000)
	
	draw_tick(8)
	draw_tick(16)
	draw_tick(24)
	draw_tick(30)
end

cheated = false
local my_draw = function()
	local frame = update_frame_rate()

	map_id = memory.read_u8(0x7E0ADB)
	camera_x = memory.read_s16_le(0x7E0112)
	camera_y = memory.read_s16_le(0x7E0114)
	trig_off_x = memory.read_s16_le(0x7E0F86)
	trig_off_y = memory.read_s16_le(0x7E0F88)
	
	frame['map_id'] = map_id
	
	if show_tiles then draw_map() end -- draw map first as text is not always-on-top in mesen
	draw_btriggers()
	draw_steptriggers()
	draw_boy(frame)
	draw_sprites(frame)
	draw_timing()
	draw_scripts(frame)
	draw_watchers(frame)
	draw_alchemy_stack()
	--draw_projectiles()
	draw_poison()
	if show_mapdata then gui.text(0, 20, string.format("Map ID: %02x, Trig Off: %02x %02x", map_id, trig_off_x, trig_off_y)) end
	emuframes = emuframes+1
   
	if cheat and not cheated then
		-- NOTE: mesen will crash (on linux) when attempting to write memory without waiting for frameend first :S
		cheated = true
		memory.write_u8(0x7E22DA, 0xfe) -- unlock weapons
		memory.write_u32_le(0x7E0A49, 0x00ffffff) -- give boy exp
		memory.write_u32_le(0x7E0A93, 0x00ffffff) -- give dog exp
		
		for i=0x22FF, 0x2347 do
			memory.write_u8(0x7E0000 + i, 0xff)
		end
	end
end

frames0 = memory.read_u24_le(0x7E0100)
timer0  = memory.read_u24_le(0x7E0B19)

if is_snes9x or is_mesen then
  event.onframeend(my_draw)
else
  while true do
    my_draw()
    emu.frameadvance()
  end
end