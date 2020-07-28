local opacity = 0x80
local fg_color = 0x00FFFFFF
local bg_color = 0x00000000
local x_padding = 0
local y_padding = 0

local SCREEN = {
	x = 0,
	y = 0,
	width = 256 * 2,
	height = 224 * 2
}
local RIGHT = {
	x = SCREEN.width,
	y = 0,
	width = 142,
	height = SCREEN.height
}
local LEFT = {
	x = -RIGHT.width,
	y = 0,
	width = RIGHT.width,
	height = SCREEN.height
}

local function trans(color)
	return color + (opacity * 0x1000000)
end
local function text(x, y, message)
	gui.text(x+x_padding, y+y_padding, message, trans(fg_color), trans(bg_color))
end


function memoryRect(start, size, amount, rows, offset, active, text, color, text_color)
	projectiles = {}
	for i=1, amount do
		local row = (i-1) % rows
		local column = math.floor((i-1) / rows)
	
		local memory = memory.readregion("WRAM", start + (i-1)*size, size) 

		--local address = string.format("%04X", (start + (i-1)*size))
		--print("i="..i..", address="..address..", projectile=")
		--print(memory)
		
		local element = {
			width = math.floor(RIGHT.width / rows),
			height = 20
		}
		local offset = {
			x = row * element.width,
			y = offset + column * element.height
		}
		if rows > 1 and row == (rows-1) then
			element.width = RIGHT.width - element.width * (rows-1)
		end
		
		--print("row="..row.."/colum="..column..", element="..element.width.."/"..element.height..", offset="..offset.x.."/"..offset.y)
		
		local is_active = active(memory)
		
		gui.solidrectangle(RIGHT.x + offset.x, RIGHT.y + offset.y, element.width, element.height, color(is_active))
		gui.rectangle(RIGHT.x + offset.x, RIGHT.y + offset.y, element.width, element.height, 1, text_color(is_active))
		gui.text(RIGHT.x + offset.x, RIGHT.y + offset.y, text(memory), text_color(is_active))
	end
end
function draw_box()
	gui.right_gap(RIGHT.width)
	
	gui.solidrectangle(RIGHT.x, RIGHT.y, RIGHT.width, RIGHT.height, 0x00DDDDDD)
	
	local offset = 23
	
	gui.text(RIGHT.x + 2, LEFT.y + 5, "Alchemy Memory", 0x00000000)
	memoryRect(0x3294, 0x1A, 8, 4, 0 + offset,
		function(memory) return memory[24] == 1 end,
		function(memory) return string.format(" %02X", memory[24]) end,
		function(active) return active and 0x00FF5555 or 0xDDFF0000 end,
		function(active) return 0x00000000 end
	)
	memoryRect(0x3364, 0x40, 8, 1, 40 + offset,
		function(memory) return memory[16] == 0 end,
		function(memory) return string.format("     %02X%02X", memory[17], memory[16]) end,
		function(active) return active and 0xDD00FF00 or 0x0033FF33 end,
		function(active) return 0x00000000 end
	)
	memoryRect(0x3364, 0x1A, 1, 4, 40 + offset,
		function(memory) return memory[24] == 1 end,
		function(memory) return string.format(" %02X", memory[24]) end,
		function(active) return active and 0x00FF5555 or 0xFF000000 end,
		function(active) return active and 0x00000000 or 0xFF000000 end
	)
	
	memoryRect(0x3564, 0x76, 8, 1, 220 + offset,
		function(memory) return memory[20] == 0 end,
		function(memory) return string.format("       %02X%02X", memory[20], memory[21]) end,
		function(active) return active and 0xDD3333FF or 0x005555FF end,
		function(active) return 0x00000000 end
	)
end

SWAP = {
	active_char = "Boy",
	count = 0
}
STATE = {
	uninitialized = false,
	human_readable = false
}

BEAUTIFY = {
	byte = function(address)
		local value = memory2.WRAM:byte(address)
		
		if STATE.uninitialized then
			return "--"
		else
			return string.format(STATE.human_readable and "%02d" or "%02x", value)
		end
	end,
	word = function(address)
		local value = memory2.WRAM:word(address)
		
		if STATE.uninitialized then
			return "----"
		else
			return string.format(STATE.human_readable and "%04d" or "%04x", value)
		end
	end,
	dword = function(address)
		local value = memory2.WRAM:dword(address)
		
		if STATE.uninitialized then
			return "--------"
		else
			return string.format(STATE.human_readable and "%08d" or "%08x", value)
		end
	end,
	character = function()
		local active_char_memory = memory2.WRAM:word(0x0F42)
		
		if STATE.uninitialized or active_char_memory == 0x0000 then
			return "---"
		end
		
		return active_char_memory
	end
}

function get_active_char()
	local active_char_memory = memory2.WRAM:word(0x0F42)
	
	if active_char_memory == 0x0000 or active_char_memory == 0x5555 then
		return "---"
	end
	
	local active_char = active_char_memory == 0x4E89 and "Boy" or "Dog"
	
	--print(string.format("Dog:    %04x", active_char_memory))
	
	if not (SWAP.active_char == active_char) then
		SWAP.active_char = active_char
		SWAP.count = SWAP.count + 1
	end
	
	return SWAP.active_char
end
function get_projectile_count()
	local count = 0
	local value = nil
	
	for i=0, 15 do
		local value = memory2.WRAM:byte(0x3294 + i*0x1A + 24)
		
		if value == 1 then
			count = count + 1
		else
			return count
		end
	end
	
	return count
end
function draw_quest()
	local highlight_color = 0x00FF0000
	local line_height = 18
	local curser = 0
	local function add_text(line, color)
		gui.text(LEFT.x + 2, LEFT.y + 5 + (curser * line_height), line, color or 0x00000000)
		curser = curser + 1
	end
	local function add_box(line_count)
		gui.solidrectangle(LEFT.x, LEFT.y + 5 + (curser * line_height), LEFT.width, line_count * line_height, 0x00FFFFFF)
		gui.rectangle(LEFT.x, LEFT.y + 5 + (curser * line_height), LEFT.width, line_count * line_height, 1, 0x00000000)
	end

	gui.left_gap(LEFT.width)
	gui.solidrectangle(LEFT.x, LEFT.y, LEFT.width, LEFT.height, 0x00DDDDDD)
	
	
	add_text("General")
	add_box(6)
	add_text(string.format("Active:  %s (%02d)", get_active_char(), SWAP.count))
	add_text(string.format("Boy:    %s|%s", BEAUTIFY.word(0x4EA3), BEAUTIFY.word(0x4EA5)))
	add_text(string.format("Dog:    %s|%s", BEAUTIFY.word(0x4F51), BEAUTIFY.word(0x4F53)), highlight_color)
	add_text(string.format("Cam:    %s|%s", BEAUTIFY.word(0x0059), BEAUTIFY.word(0x005B)), highlight_color)
	add_text(string.format("Frame:   %s", BEAUTIFY.dword(0x0100)))
	add_text(string.format("Extra Drop #:  %s", BEAUTIFY.byte(0x2461)))
	
	add_text("")
	add_text("Quest")
	add_box(6)
	add_text(string.format("Clay:       %s/%02d", BEAUTIFY.byte(0x230F), 9))
	add_text(string.format("Crystals:   %s/%02d", BEAUTIFY.byte(0x230E), 9))
	add_text(string.format("Formula #1: %02X/%02X", memory2.WRAM:byte(0x0ADA), 0x22))
	add_text(string.format("Projectiles:%02X/%02X", get_projectile_count(), 9))
	add_text(string.format("Credit #1:  %02X/%02X", memory2.WRAM:byte(0x22F1), 0xFF), highlight_color)
	add_text(string.format("Credit #2:  %02X/%02X", memory2.WRAM:byte(0x22EB), 0xFF), highlight_color)
	
	add_text("")
	add_text("ACE", highlight_color)
	add_box(3)
	add_text(string.format("Crash:  %04X/%04X", memory2.WRAM:word(0x3378), 0x005A), highlight_color)
	add_text(string.format("Cam YX: %04X/%04X", memory2.WRAM:word(0x005A), 0x8104), highlight_color)
	add_text(string.format("Joy #1: %04X/%04X", memory2.WRAM:word(0x0104), 0x421A), highlight_color)
end


function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function on_paint(sync)
	
	--print("on_paint("..tostring(sync)..")")
	
	--gui.solidrectangle(SCREEN.x, SCREEN.y, SCREEN.width, SCREEN.height, 0x00FF0000)
	draw_box()
	draw_quest()
end