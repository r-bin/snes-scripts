local opacity = 0x80
local fg_color = 0x00FFFFFF
local bg_color = 0x00000000
local x_padding = 0
local y_padding = 0

local screen = {
	x = 0,
	y = 0,
	width = 256 * 2,
	height = 224 * 2
}
local box = {
	x = screen.width,
	y = 0,
	width = 142,
	height = screen.height
}
local quest = {
	x = -box.width,
	y = 0,
	width = box.width,
	height = screen.height
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
			width = math.floor(box.width / rows),
			height = 20
		}
		local offset = {
			x = row * element.width,
			y = offset + column * element.height
		}
		if rows > 1 and row == (rows-1) then
			element.width = box.width - element.width * (rows-1)
		end
		
		--print("row="..row.."/colum="..column..", element="..element.width.."/"..element.height..", offset="..offset.x.."/"..offset.y)
		
		local is_active = active(memory)
		
		gui.solidrectangle(box.x + offset.x, box.y + offset.y, element.width, element.height, color(is_active))
		gui.rectangle(box.x + offset.x, box.y + offset.y, element.width, element.height, 1, text_color(is_active))
		gui.text(box.x + offset.x, box.y + offset.y, text(memory), text_color(is_active))
	end
end
function draw_box()
	gui.right_gap(box.width)
	
	gui.solidrectangle(box.x, box.y, box.width, box.height, 0x00DDDDDD)
	
	memoryRect(0x3294, 0x1A, 8, 4, 0,
		function(memory) return memory[24] == 1 end,
		function(memory) return string.format(" %02X", memory[24]) end,
		function(active) return active and 0x00FF5555 or 0xDDFF0000 end,
		function(active) return 0x00000000 end
	)
	memoryRect(0x3364, 0x40, 8, 1, 40,
		function(memory) return memory[16] == 0 end,
		function(memory) return string.format("     %02X%02X", memory[17], memory[16]) end,
		function(active) return active and 0xDD00FF00 or 0x0033FF33 end,
		function(active) return 0x00000000 end
	)
	memoryRect(0x3364, 0x1A, 1, 4, 40,
		function(memory) return memory[24] == 1 end,
		function(memory) return string.format(" %02X", memory[24]) end,
		function(active) return active and 0x00FF5555 or 0xFF000000 end,
		function(active) return active and 0x00000000 or 0xFF000000 end
	)
	
	memoryRect(0x3564, 0x76, 8, 1, 220,
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
	human_readable = true
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
function draw_quest()
	local line_height = 18
	local curser = 0
	local function add_text(line)
		gui.text(quest.x + 2, quest.y + 5 + (curser * line_height), line, 0x00000000)
		curser = curser + 1
	end
	local function add_box(line_count)
		gui.solidrectangle(quest.x, quest.y + 5 + (curser * line_height), quest.width, line_count * line_height, 0x00FFFFFF)
		gui.rectangle(quest.x, quest.y + 5 + (curser * line_height), quest.width, line_count * line_height, 1, 0x00000000)
	end

	gui.left_gap(quest.width)
	gui.solidrectangle(quest.x, quest.y, quest.width, quest.height, 0x00DDDDDD)
	
	
	add_text("Misc")
	add_box(5)
	add_text(string.format("Char:    %s (%02d)", get_active_char(), SWAP.count))
	add_text(string.format("Camera: %s/%s", BEAUTIFY.word(0x0059), BEAUTIFY.word(0x005B)))
	add_text(string.format("Boy:    %s/%s", BEAUTIFY.word(0x4EA3), BEAUTIFY.word(0x4EA5)))
	add_text(string.format("Dog:    %s/%s", BEAUTIFY.word(0x4F51), BEAUTIFY.word(0x4F53)))
	add_text(string.format("Frame:  0%s", BEAUTIFY.dword(0x0100)))
	
	add_text("")
	add_text("Quest")
	add_box(5)
	add_text(string.format("Clay:       %s/%02d", BEAUTIFY.byte(0x230F), 9))
	add_text(string.format("Crystals:   %s/%02d", BEAUTIFY.byte(0x230E), 9))
	add_text(string.format("Formula:    %02X/%02X", memory2.WRAM:byte(0x0ADA), 0x22))
	add_text(string.format("Credit #1:  %02X/%02X", memory2.WRAM:byte(0x22EB), 0xFF))
	add_text(string.format("Credit #2:  %02X/%02X", memory2.WRAM:byte(0x22F1), 0xFF))
	
	add_text("")
	add_text("ACE")
	add_box(3)
	add_text(string.format("Crash:  %04X/%04X", memory2.WRAM:word(0x3378), 0x005A))
	add_text(string.format("Cam XY: %04X/%04X", memory2.WRAM:word(0x005A), 0x8104))
	add_text(string.format("Joy #1: %04X/%04X", memory2.WRAM:word(0x0104), 0x421A))
end
function on_paint(sync)
	
	--print("on_paint("..tostring(sync)..")")
	
	--gui.solidrectangle(screen.x, screen.y, screen.width, screen.height, 0x00FF0000)
	draw_box()
	draw_quest()
end

