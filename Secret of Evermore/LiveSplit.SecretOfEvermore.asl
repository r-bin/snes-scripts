// Secret of Evermore AutoSplitter, hosted at:
// #TODO#
// 
// Basic format of the script is based on:
// https://github.com/UNHchabo/AutoSplitters/blob/master/SuperMetroid
// https://github.com/Spiraster/ASLScripts/tree/master/LiveSplit.ALttP
// 
// Most of the RAM values taken from:
// https://datacrystal.romhacking.net/wiki/Secret_of_Evermore:RAM_map
//
// Installation guide:
// https://github.com/LiveSplit/LiveSplit/blob/master/Documentation/Auto-Splitters.md#testing-your-script
// https://github.com/LiveSplit/LiveSplit/blob/master/Documentation/Auto-Splitters.md#debugging

state("higan"){}
state("bsnes"){}
state("bsnes-plus"){}
state("snes9x"){}
state("snes9x-x64"){}
state("emuhawk"){}
state("retroarch"){}

startup
{
	print("startup");
	
	vars.split = new Dictionary<string, ExpandoObject>();
	var currentAct = "";
	
	Action<int, string> AddAct = (act, name) => {
		print("+act (act="+act+", name="+name+")");
		currentAct = "act"+act;
		settings.Add("act"+act, true, "Act "+act+" - "+name);
	};
	Action<string, string, string, bool> AddOptionalSplit = (key, name, description, activated) => {
		print("+split (key="+key+", name="+name+", description="+description+", activated="+activated+")");
		
		settings.Add(key, activated, name, currentAct);
		settings.SetToolTip(key, description);
		
		vars.split[key] = new ExpandoObject();
		vars.split[key].achieved = false;
	};
	Action<string, string, string> AddSplit = (key, name, description) => {
		AddOptionalSplit(key, name, description, true);
	};
	
	AddAct(1, "Prehistoria");
	AddSplit ("flowers", "Flowers", "Split on dog dragging the boy to the right, after entering the map with 0 HP");
	AddSplit ("thraxx", "Thraxx", "Split on leaving the room");
	AddSplit ("magmar", "Magmar", "Split on victory hymn");
	
	AddAct(2, "Antiqua");
	AddSplit("enterNobilia", "Enter Nobilia", "Split on resting pose of the boy, after entering Nobilia for the first time");
	AddSplit("marketTimer", "Market Timer", "Split on resting pose of the boy, after leaving the market post Market Timer");
	AddSplit("vigor", "Vigor", "Split on victory hymn");
	AddOptionalSplit("enterTemple", "Enter Temple", "Split on entering the temple", false);
	AddSplit("megataur", "Megataur", "Split on victory hymn");
	AddSplit("rimsala", "Rimsala", "Split on victory hymn");
	AddSplit("aegis", "Aegis", "Split on victory hymn");
	AddSplit("aquagoth", "Aquagoth", "Split on victory hymn");
	
	AddAct(3, "Gothica");
	AddSplit("footknight", "FootKnight", "Split on victory hymn");
	AddSplit("badBoy", "Bad Boy", "Split on victory hymn");
	AddSplit("timberdrake", "Timberdrake", "Split on victory hymn");
	AddSplit("verminator", "Verminator", "Split on victory hymn");
	AddSplit("sterling", "Sterling", "Split on victory hymn");
	AddSplit("mungola", "Mungola", "Split on victory hymn");
	AddOptionalSplit("glassFight", "Glass Fight", "Split on victory hymn", false);
	AddOptionalSplit("windwalker", "Windwalker", "Split on leaving the screen, at the beginning of the fading animation", false);
	AddSplit("gauge", "Gauge #1", "Split on landing the Wind Walker, at the beginning of the fading animation");
	AddSplit("rocket", "Rocket", "Split on leaving the screen, at the beginning of the fading animation");
	
	AddAct(4, "Omnitopia");
	AddOptionalSplit("saturn", "Saturn Skip", "Split on entering the boss rush room, at the beginning of the fading animation", false);
	AddSplit("carltron", "Carltron's Robot", "Split on xp gain (The boy can still be controlled)");
}

init
{
	print("init");
	
	IntPtr memoryOffset = IntPtr.Zero;
	
	if (memory.ProcessName.ToLower().Contains("snes9x")
		|| memory.ProcessName.ToLower().Contains("higan")
		|| memory.ProcessName.ToLower().Contains("bsnes")
		|| memory.ProcessName.ToLower().Contains("emuhawk")) {
		var versions = new Dictionary<int, Tuple<long, int>>{
			{ 10330112, new Tuple<long, int>(0x789414, 1) },	 	// snes9x 1.52-rr
			{ 7729152, new Tuple<long, int>(0x890EE4, 1) },			// snes9x 1.54-rr
			{ 5914624, new Tuple<long, int>(0x6EFBA4, 1) },			// snes9x 1.53
			{ 6909952, new Tuple<long, int>(0x140405EC8, 1) }, 		// snes9x 1.53 (x64)
			{ 6447104, new Tuple<long, int>(0x7410D4, 1) },			// snes9x 1.54/1.54.1
			{ 7946240, new Tuple<long, int>(0x1404DAF18, 1) }, 		// snes9x 1.54/1.54.1 (x64)
			{ 6602752, new Tuple<long, int>(0x762874, 1) },			// snes9x 1.55
			{ 8355840, new Tuple<long, int>(0x1405BFDB8, 1) },	 	// snes9x 1.55 (x64)
			{ 6856704, new Tuple<long, int>(0x78528C, 1) },			// snes9x 1.56/1.56.2
			{ 9003008, new Tuple<long, int>(0x1405D8C68, 1) },	 	// snes9x 1.56 (x64)
			{ 6848512, new Tuple<long, int>(0x7811B4, 1) },	 	 	// snes9x 1.56.1
			{ 8945664, new Tuple<long, int>(0x1405C80A8, 1) }, 		// snes9x 1.56.1 (x64)
			{ 9015296, new Tuple<long, int>(0x1405D9298, 1) }, 		// snes9x 1.56.2 (x64)
			{ 6991872, new Tuple<long, int>(0x7A6EE4, 1) },			// snes9x 1.57
			{ 9048064, new Tuple<long, int>(0x1405ACC58, 1) }, 		// snes9x 1.57 (x64)
			{ 7000064, new Tuple<long, int>(0x7A7EE4, 1) },			// snes9x 1.58
			{ 9060352, new Tuple<long, int>(0x1405AE848, 1) }, 		// snes9x 1.58 (x64)
			{ 8953856, new Tuple<long, int>(0x975A54, 1) },			// snes9x 1.59.2
			{ 12537856, new Tuple<long, int>(0x1408D86F8, 1) },		// snes9x 1.59.2 (x64)
			{ 9646080, new Tuple<long, int>(0x97EE04, 1) },			// Snes9x-rr 1.60
			{ 13565952, new Tuple<long, int>(0x140925118, 1) },		// Snes9x-rr 1.60 (x64)
			{ 9027584, new Tuple<long, int>(0x94DB54, 1) },			// snes9x 1.60
			{ 12836864, new Tuple<long, int>(0x1408D8BE8, 1) },		// snes9x 1.60 (x64)
			{ 12509184, new Tuple<long, int>(0x915304, 0) },		// higan v102
			{ 13062144, new Tuple<long, int>(0x937324, 0) },		// higan v103
			{ 15859712, new Tuple<long, int>(0x952144, 0) },		// higan v104
			{ 16756736, new Tuple<long, int>(0x94F144, 0) },		// higan v105tr1
			{ 16019456, new Tuple<long, int>(0x94D144, 0) }, 		// higan v106
			{ 15360000, new Tuple<long, int>(0x8AB144, 0) },		// higan v106.112
			{ 10096640, new Tuple<long, int>(0x72BECC, 0) },		// bsnes v107
			{ 10338304, new Tuple<long, int>(0x762F2C, 0) },		// bsnes v107.1
			{ 47230976, new Tuple<long, int>(0x765F2C, 0) },	 	// bsnes v107.2/107.3
			{ 142282752, new Tuple<long, int>(0xA65464, 0) },	 	// bsnes v108
			{ 131354624, new Tuple<long, int>(0xA6ED5C, 0) },	 	// bsnes v109
			{ 131543040, new Tuple<long, int>(0xA9BD5C, 0) },	 	// bsnes v110
			{ 51924992, new Tuple<long, int>(0xA9DD5C, 0) },		// bsnes v111
			{ 52056064, new Tuple<long, int>(0xAAED7C, 0) }, 		// bsnes v112
			{ 9662464, new Tuple<long, int>(0x67dac8, 1) },			// bsnes+ 0.5
			{ 7061504, new Tuple<long, int>(0x36F11500240, 0) }, 	// BizHawk 2.3
			{ 7249920, new Tuple<long, int>(0x36F11500240, 0) }, 	// BizHawk 2.3.1
			{ 6938624, new Tuple<long, int>(0x36F11500240, 0) }, 	// BizHawk 2.3.2
		};

		Tuple<long, int> emulatorProperties;
		if (versions.TryGetValue(modules.First().ModuleMemorySize, out emulatorProperties)) {
			var address = emulatorProperties.Item1;
			var indirect = emulatorProperties.Item2 > 0;
			
			if(indirect) {
				memoryOffset = memory.ReadPointer((IntPtr)address);
			} else {
				memoryOffset = (IntPtr)address;
			}
		}
	}

	if (memoryOffset == IntPtr.Zero)
		throw new Exception("Memory not yet initialized.");
	
	vars.watchers = new MemoryWatcherList
	{
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x2210) { Name = "boy_firstLetter" },
		new MemoryWatcher<ushort>((IntPtr)memoryOffset + 0x4EA3) { Name = "boy_x" },
		new MemoryWatcher<ushort>((IntPtr)memoryOffset + 0x4EA5) { Name = "boy_y" },
		new MemoryWatcher<uint>((IntPtr)memoryOffset + 0x0A49) { Name = "boy_xp" },
		new MemoryWatcher<ushort>((IntPtr)memoryOffset + 0x4EB3) { Name = "boy_hp" },
		
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0ADB) { Name = "map" },
		new MemoryWatcher<ushort>((IntPtr)memoryOffset + 0x0E4B) { Name = "music" },
		
		new MemoryWatcher<ushort>((IntPtr)memoryOffset + 0x0100) { Name = "frame" },
	};
}

update
{
	vars.watchers.UpdateAll(game);
}

start
{
	var introStarted = vars.watchers["map"].Old != 49 && vars.watchers["map"].Current == 49;
	var nameNotEmpty = vars.watchers["boy_firstLetter"].Current > 0;
	
	var start = nameNotEmpty && introStarted;
	
	if(start) {
		print("+run");
	
		foreach(var split in vars.split)
		{
			vars.split[split.Key].achieved = false;
		}
	}
	
	
	return start;
}

reset
{
	var openingSequence = vars.watchers["map"].Old == 97 && vars.watchers["map"].Current == 97;

	var reset = openingSequence;
	
	if(reset) {
		print("-run");
	}
	
	return reset;
}

split
{
	var split = false;
	
	Action<string, bool> checkSplit = (key, condition) => {
		if (settings[key] && vars.split[key].achieved == false && condition) {
			vars.split[key].achieved = true;
			print("~split="+key);
			
			split = true;
		}
	};
	
	Func<byte, bool> Map = (map => vars.watchers["map"].Current == map);
	Func<byte, byte, bool> MapTransition = ((previousMap, map) => vars.watchers["map"].Current == map && vars.watchers["map"].Old == previousMap);
	Func<ushort, bool> Music = (music => vars.watchers["music"].Current == music);
	Func<bool> Hymn = (() => vars.watchers["music"].Current != vars.watchers["music"].Old && vars.watchers["music"].Current == 26);
	Func<ushort, bool> XReached = (x => vars.watchers["boy_x"].Current > vars.watchers["boy_x"].Old && vars.watchers["boy_x"].Current >= x);
	Func<ushort, bool> YReached = (y => vars.watchers["boy_y"].Current < vars.watchers["boy_y"].Old && vars.watchers["boy_y"].Current <= y);
	Func<uint, bool> XpGained = (xp => vars.watchers["boy_xp"].Current > vars.watchers["boy_xp"].Old && ((vars.watchers["boy_xp"].Current - vars.watchers["boy_xp"].Old) >= xp));
	
		
	// Act 1
	checkSplit("flowers", Map(92) && XReached(234));
	checkSplit("thraxx", MapTransition(24, 103));
	checkSplit("magmar", Map(63) && Hymn());
	
	// Act 2
	checkSplit("enterNobilia", Map(10) && XReached(88));
	checkSplit("marketTimer", Map(8) && Music(38) && XReached(56));
	checkSplit("vigor", Map(29) && Hymn());
	checkSplit("enterTemple", Map(41));
	checkSplit("megataur", Map(42) && Hymn());
	checkSplit("rimsala", Map(88) && Hymn());
	checkSplit("aegis", Map(9) && Hymn());
	checkSplit("aquagoth", Map(109) && Hymn());
	
	// Act 3
	checkSplit("footknight", Map(25) && Hymn());
	checkSplit("badBoy", Map(31) && Hymn());
	checkSplit("timberdrake", Map(32) && Hymn());
	checkSplit("verminator", Map(94) && Hymn());
	checkSplit("sterling", Map(55) && Hymn());
	checkSplit("mungola", Map(119) && Hymn());
	checkSplit("glassFight", MapTransition(16, 20));
	checkSplit("windwalker", Map(57) && YReached(285));
	checkSplit("gauge", MapTransition(54, 57));
	checkSplit("rocket", MapTransition(57, 72));
	
	// Act 4
	checkSplit("saturn", MapTransition(72, 74));
	checkSplit("carltron", Map(74) && XpGained(100000));
	
	return split;
}
