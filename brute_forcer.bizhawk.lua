-- helpers
function clean_empty(array)
	local clean_array = {}
	for _,value in pairs(array) do
	  if not (value == "") then
		  clean_array[ #clean_array+1 ] = value
	  end
	end
	return clean_array
  end
  function split(s, delimiter)
	  result = {};
	  for match in (s..delimiter):gmatch("(.-)"..delimiter) do
		  table.insert(result, match);
	  end
	  return result;
  end
  
  -- internal
  function split_inputs(inputs_string)
	  local inputs = {}
	  
	  inputs = clean_empty(split(inputs_string, "\n"))
	  
	  for i = 1, #inputs do
		  --print("i="..i..", input="..inputs[i])
		  joypad.setfrommnemonicstr(inputs[i])
	  end
	  
	  return inputs
  end
  
  --BUTTONS = { "U", "D", "L", "R", "s", "S", "Y", "B", "X", "A", "l", "r", "0", "1", "2", "3" }
  BUTTONS = { "P1 Up", "P1 Down", "P1 Left", "P1 Right", "P1 Select", "P1 Start", "P1 Y", "P1 B", "P1 X", "P1 A", "P1 L", "P1 R" }
  STATE = {
	  count = 1,
	  current_frame = 0,
	  best_result = -1,
	  base_save_slot = 5,
	  save_slot = 5,
	  settings = -1
  }
  RESULT = {}
  
  -- config
  RNG_BYTES = { 0x0133, 0x0134, 0x0135, 0x0136, 0x0137, 0x0138, 0x0139, 0x013A }
  
  SETTING_SETS = {
	  {
		  name = "Camera Setup",
		  allow_empty_input = true,
		  allow_more_than_one_button = true,
		  watchers = {
			  {
				  address = 0x005A,
				  data_type = "ushort",
				  name = "camera_xy",
				  win = function(value) return value == 0x8101 end,
				  reset = function(value) return value < 0x8101 end
			  },
			  {
				  address = 0x4EB3,
				  data_type = "ushort",
				  name = "boy_hp",
				  win = nil,
				  reset = function(value) return value <= 20 end
			  }
		  },
		  rng_buttons = { "P1 Up", "P1 Left", "P1 Right" }, -- , "P1 Down"
		  inputs = nil
	  },
	  {
		  name = "Crash RNG Setup",
		  allow_empty_input = false,
		  allow_more_than_one_button = false,
		  rng_buttons = nil,
		  watchers = {
			  {
				  address = 0x005A,
				  data_type = "ushort",
				  name = "camera_xy",
				  win = nil,
				  reset = function(value) return value < 0x8101 end
			  },
			  {
				  address = 0x4EB3,
				  data_type = "ushort",
				  name = "boy_hp",
				  win = nil,
				  reset = function(value) return value <= 20 end
			  },
			  {
				  address = 0x3378,
				  data_type = "ushort",
				  name = "crash_rng",
				  win = function(value) return value == 0x005A end,
				  reset = function(value) return not (value == 0) end
			  }
		  },
		  rng_buttons = { "P1 L", "P1 R" },
		  inputs = split_inputs([[
  |..|......Y.....|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|.......B....|............|
  |..|............|............|
  |..|.......B....|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  |..|............|............|
  ]])
	  }
  }
  function nextState()
	  STATE.win = false
	  STATE.reset = false
	  STATE.input_index = 1
  
	  if STATE.settings == -1 then
		  STATE.settings = 1
		  SETTINGS = SETTING_SETS[STATE.settings]
	  elseif STATE.settings + 1 <= #SETTING_SETS then
		  STATE.settings = STATE.settings + 1
		  SETTINGS = SETTING_SETS[STATE.settings]
	  else
		  finish()
	  end
	  
	  --print("state="..STATE.settings.."\n - "..SETTINGS.name.."\n - #wachers="..#SETTINGS.watchers)
  end
  nextState()
  
  function set_rng_buttons(button, random_button)
	  if random_button == "/wait" then
		  return false
	  elseif SETTINGS.allow_more_than_one_button then
		  return math.random(2) == 1
	  else
		  return button == random_button
	  end
  end
  function progress_rng()
	  random_button = SETTINGS.rng_buttons[math.random(#SETTINGS.rng_buttons)]
	  --print("random input=" .. random_button)
  
	  local buttons = joypad.get()
	  for i = 1, #SETTINGS.rng_buttons do
		  local button = SETTINGS.rng_buttons[i]
		  buttons[button] = set_rng_buttons(button, random_button)
	  end
	  joypad.set(buttons)
	  
	  --print(joypad.get())
  end
  function progress_inputs()
	  if STATE.input_index > #SETTINGS.inputs then
		  return
	  end
  
	  local buttons = SETTINGS.inputs[STATE.input_index]
	  --print(STATE.input_index.."/"..#SETTINGS.inputs.." = "..buttons)
	  STATE.input_index = STATE.input_index + 1
	  
	  joypad.setfrommnemonicstr(buttons)	
  end
  function progress()
	  if (SETTINGS.inputs == nil) then
		  progress_rng()
	  else
		  progress_inputs()
	  end
  end
  
  function check_cond()
	  for _, watcher in pairs(SETTINGS.watchers) do
		  local value = mainmemory.read_u16_le(watcher.address)
		  
		  --print(watcher.name .. "=" .. value)
		  if watcher.win ~= nil then
			  STATE.win = STATE.win or watcher.win(value)
			  if watcher.win(value) then
				  --print(string.format("WATCHER: %s = %04X", watcher.name, value))
			  end
		  end
		  if watcher.reset ~= nil then
			  STATE.reset = STATE.reset or watcher.reset(value)
			  if watcher.reset(value) then
				  --print(string.format("WATCHER: %s = %04X", watcher.name, value))
			  end
		  end
	  end
	  
	  
	  return STATE.win, STATE.reset
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
  savestate.loadslot(5);
  --savestate.saveslot(5);
  --client.unpause()
  tastudio.setrecording(true);
  
  emu.limitframerate(false);
  
  
  function renderOverlay()
	  gui.drawText(5,5,string.format("COUNT:   %d", STATE.count));
	  gui.drawText(5,20,string.format("FRAME:   %d", STATE.current_frame));
	  gui.drawText(5,35,string.format("BEST:    %d", STATE.best_result));
	  gui.drawText(5,55,string.format("STATE:   [%d] %s", STATE.settings, SETTINGS.name));
	  for i = 1, #SETTINGS.watchers do
		  gui.drawText(5, 60 + i*15,
			  string.format("WATCHER: %s = %04X",
				  SETTINGS.watchers[i].name,
				  mainmemory.read_u16_le(SETTINGS.watchers[i].address)
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
	  RESULT = {
		  frames = STATE.current_frame,
		  RNG_BYTES = rng_string()
	  }
	  
	  print("Success!\n  - "..STATE.current_frame.." frames\n  - "..rng_string())
		  
	  if STATE.current_frame < STATE.best_result or STATE.best_result == -1 then
		  STATE.best_result = STATE.current_frame
		  
		  print("New record!")
		  savestate.saveslot(6)
	  end
  end
  function rewind()
	  STATE.settings = -1
	  STATE.count = STATE.count + 1
	  STATE.current_frame = 0
	  
	  STATE.win = null
	  STATE.reset = null
	  
	  nextState()
	  
	  savestate.loadslot(5)
  end
  function finish()
	  updateBest()
	  
	  rewind()
  end
  while true do
	  --print("do sth.")
	  renderOverlay()
	  
	  progress()
	  advance_frames(1)
	  
	  local win, reset = check_cond()
	  --print("win="..tostring(win)..", reset="..tostring(reset))
	  if win then
		  --print("yay")
		  nextState()
	  elseif reset then
		  --print("ney")
		  rewind()
	  end
  end
	  
  emu.limitframerate(true);