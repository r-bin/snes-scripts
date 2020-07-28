-- internal
--BUTTONS = { "U", "D", "L", "R", "s", "S", "Y", "B", "X", "A", "l", "r", "0", "1", "2", "3" }
BUTTONS = { "P1 Up", "P1 Down", "P1 Left", "P1 Right", "P1 Select", "P1 Start", "P1 Y", "P1 B", "P1 X", "P1 A", "P1 L", "P1 R" }
STATE = {
	count = 1,
	current_frame = 0,
	best_result = -1
}
RESULT = {}

-- config
SETTING_SETS = {
	{
		allow_empty_input = true,
		allow_more_than_one_button = false,
	}
}
SETTINGS = SETTING_SETS[0]

RNG_BYTES = { 0x0133, 0x0134, 0x0135, 0x0136, 0x0137, 0x0138, 0x0139, 0x013A }

--RNG_BUTTONS = { "U", "D", "L", "R", "B" }
RNG_BUTTONS = { "P1 Up", "P1 Down", "P1 Left", "P1 Right", "P1 B" } --, "/wait", "/end"
MEMORY_WATCHER = {
	{
		address = 0x2210,
		name = "boy_firstLetter",
		win = function(value) return value == string.byte("p") end,
		reset = function(value) return not (value == 0) end
	}
}

function set_rng_buttons(button, random_button)
	if random_button == "/wait" then
		return false
	elseif STATE.allow_more_than_one_button then
		return math.random() == 1
	else
		return button == random_button
	end
end
function progress_rng()
	random_button = RNG_BUTTONS[math.random(#RNG_BUTTONS)]
	--print("random input=" .. random_button)

	local buttons = joypad.get()
	for i = 1, #RNG_BUTTONS do
		local button = RNG_BUTTONS[i]
		buttons[button] = set_rng_buttons(button, random_button)
    end
	joypad.set(buttons)
	
	--print(joypad.get())
end

function check_cond()	
	for i = 1, #MEMORY_WATCHER do
		local watcher = MEMORY_WATCHER[i]
		local value = mainmemory.readbyte(watcher.address)
		
		--print(watcher.name .. "=" .. value)
		STATE.win = watcher.win(value)
		STATE.reset = watcher.reset(value)
		
		return STATE.win, STATE.reset
    end
end

function advance_frames(count)
	for i=1,count,1 do
		--print("+advance frame")
		emu.frameadvance();
		--print("-advance frame")
	end
	
	STATE.current_frame = STATE.current_frame + count
end

-- Sets up the save states
savestate.loadslot(4);
--client.unpause()
tastudio.setrecording(true);

emu.limitframerate(false);
	
-- Initialize some variables
mycount = 0;

function renderOverlay()
	gui.drawText(5,5,string.format("COUNT:   %d", STATE.count));
	gui.drawText(5,20,string.format("FRAME:   %d", STATE.current_frame));
	gui.drawText(5,35,string.format("BEST:    %d", STATE.best_result));
	for i = 1, #MEMORY_WATCHER do
		gui.drawText(5,35 + i*15,
			string.format("WATCHER: %d == %s",
				MEMORY_WATCHER[i].address,
				MEMORY_WATCHER[i].name
			));
    end
end

function rng_string()
	local rng_bytes = {}

	for i = 1, #RNG_BYTES do
		local value = mainmemory.readbyte(RNG_BYTES[i])
		
		rng_bytes[i] = string.format("%02X", value)
    end
	
	return table.concat(rng_bytes, ",")
end
function updateBest()
	if STATE.current_frame < STATE.best_result or STATE.best_result == -1 then
		STATE.best_result = STATE.current_frame
		
		RESULT = {
			frames = STATE.best_result,
			RNG_BYTES = rng_string()
		}
		
		print("New record!\n  - "..STATE.best_result.." frames\n  - "..rng_string())
		savestate.saveslot(6)
	end
end
function rewind()
	STATE.count = STATE.count + 1
	STATE.current_frame = 0
	
	STATE.win = null
	STATE.reset = null
	
	savestate.loadslot(5)
end
while true do
	--print("do sth.")
	renderOverlay()
	
	progress_rng()
	advance_frames(1)
	
	local win, reset = check_cond()
	--print("win="..tostring(win)..", reset="..tostring(reset))
	if win then
		--print("yay")
		updateBest()
		rewind()
	elseif reset then
		--print("ney")
		rewind()
	end
end
	
emu.limitframerate(true);