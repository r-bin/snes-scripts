// Secret of Evermore AutoSplitter, hosted at:
// https://github.com/r-bin/snes-scripts/
// 
// Basic format of the script is based on:
// https://github.com/UNHchabo/AutoSplitters/blob/master/SuperMetroid
// https://github.com/Spiraster/ASLScripts/tree/master/LiveSplit.ALttP
// 
// Most of the RAM values taken from:
// https://datacrystal.romhacking.net/wiki/Secret_of_Evermore:RAM_map
// http://assassin17.brinkster.net/soe_guides/soe-monster.txt
//
// Manual installation guide:
// https://github.com/LiveSplit/LiveSplit/blob/master/Documentation/Auto-Splitters.md#testing-your-script
// https://github.com/LiveSplit/LiveSplit/blob/master/Documentation/Auto-Splitters.md#debugging
//
// CAVEAT:
// - Either "Auto Start" or "Auto Reset" is required because the split progress has to be reset
// - Recommended start time is -4.00s
// - GameTime is "frames - lag_frames" and is not accepted for leaderboard submissions
// - "init" contains a list of supported emulators (Some are deprecated and don't receive updates)

state("higan"){}
state("bsnes"){}
state("snes9x"){}
state("snes9x-x64"){}
state("emuhawk"){} // EmuHawk/Bizhawk (BSNES core)
state("lsnes-bsnes"){}

startup
{
	vars.debug = true;
	vars.debugStart = false;
	vars.debugUpdate = false;
	vars.debugReset = false;
	
	if(vars.debug) print("startup");
	
	vars.split = new Dictionary<string, ExpandoObject>();
	var currentAct = "";
	
	Action<int, string> AddAct = (act, name) => {
		if(vars.debug) print("+act (act="+act+", name="+name+")");
		currentAct = "act"+act;
		settings.Add("act"+act, true, "Act "+act+" - "+name);
	};
	Action<string, string, string, bool> AddOptionalSplit = (key, name, description, activated) => {
		if(vars.debug) print("+split (key="+key+", name="+name+", description="+description+", activated="+activated+")");
		
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
	AddOptionalSplit ("raptors", "Raptors", "Split on leaving the map", false);
	AddSplit ("thraxx", "Thraxx", "Split on leaving the room");
	AddOptionalSplit ("graveyard", "Graveyard", "Split on fanfare", false);
	AddOptionalSplit ("salabog", "Salabog", "Split on fanfare", false);
	AddOptionalSplit ("volcano", "Enter Volcano", "Split on entering the map", false);
	AddSplit ("magmar", "Magmar", "Split on fanfare");
	
	AddAct(2, "Antiqua");
	AddSplit("enterNobilia", "Enter Nobilia", "Split on resting pose of the boy, after entering Nobilia for the first time");
	AddSplit("marketTimer", "Market Timer", "Split on resting pose of the boy, after leaving the market post Market Timer");
	AddSplit("vigor", "Vigor", "Split on fanfare");
	AddOptionalSplit("temple", "Enter Temple", "Split on entering the temple", false);
	AddSplit("megataur", "Megataur", "Split on fanfare");
	AddSplit("rimsala", "Rimsala", "Split on fanfare");
	AddSplit("aegis", "Aegis", "Split on fanfare");
	AddSplit("aquagoth", "Aquagoth", "Split on fanfare");
	
	AddAct(3, "Gothica");
	AddOptionalSplit("dogMaze", "Dog Maze", "Split on entering the map", false);
	AddSplit("footknight", "FootKnight", "Split on fanfare");
	AddSplit("badBoy", "Bad Boy", "Split on fanfare");
	AddSplit("timberdrake", "Timberdrake", "Split on fanfare");
	AddSplit("verminator", "Verminator", "Split on fanfare");
	AddSplit("sterling", "Sterling", "Split on fanfare");
	AddSplit("mungola", "Mungola", "Split on fanfare");
	AddOptionalSplit("glassFight", "Glass Fight", "Split on fanfare", false);
	AddOptionalSplit("windwalker", "Windwalker", "Split on leaving the screen", false);
	AddOptionalSplit("tiny", "Tiny", "Split on fanfare", false);
	AddOptionalSplit("coleoptera", "Coleoptera", "Split on leaving the room", false);
	AddSplit("gauge", "Gauge #1", "Split on landing the Wind Walker");
	AddSplit("rocket", "Rocket", "Split on leaving the screen");
	
	AddAct(4, "Omnitopia");
	AddOptionalSplit("professor", "Professor", "Split on entering the map", false);
	AddOptionalSplit("face", "Face", "Split on fanfare", false);
	AddOptionalSplit("saturn", "Saturn Skip", "Split on entering the boss rush room", false);
	AddSplit("carltron", "Carltron's Robot", "Split on Carltron reaching 0 HP");
}

init
{
	if(vars.debug) print("init");
	
	IntPtr memoryOffset = IntPtr.Zero;
	var emulatorName = "unknown emulator";
	
	Action<long, int, string> InitMemoryOffset = (address, indirect, name) => {
		if(indirect > 0) {
			memoryOffset = memory.ReadPointer((IntPtr)address);
		} else {
			memoryOffset = (IntPtr)address;
		}
		
		emulatorName = name;
	};
	
	if (memory.ProcessName.ToLower().Contains("snes9x")
		|| memory.ProcessName.ToLower().Contains("higan")
		|| memory.ProcessName.ToLower().Contains("bsnes")
		|| memory.ProcessName.ToLower().Contains("lsnes")
		|| memory.ProcessName.ToLower().Contains("emuhawk")) {
		var versions = new Dictionary<int, Tuple<long, int, string>>{
			// lsnes
			{ 35414016,		new Tuple<long, int, string>(0x23A1BF0,		0,	"lsnes rr2-β23") },
			{ 35545088,		new Tuple<long, int, string>(0x23C0C70,		0,	"lsnes rr2-β24") },

			// EmuHawk/Bizhawk (BSNES core)
			{ 6152192,		new Tuple<long, int, string>(0x08EB0000,	0,	"EmuHawk/Bizhawk 1.6 (BSNES core)") },
			{ 7249920,		new Tuple<long, int, string>(0x36F11500240,	0,	"EmuHawk/Bizhawk 2.3.1 (BSNES core)") },
			{ 6938624,		new Tuple<long, int, string>(0x36F11500240,	0,	"EmuHawk/Bizhawk 2.3.2 (BSNES core)") },
			{ 5406720,		new Tuple<long, int, string>(0x36F11500240,	0,	"EmuHawk/Bizhawk 2.4.0 (BSNES core)") },
			{ 5054464,		new Tuple<long, int, string>(0x36F11500240,	0,	"EmuHawk/Bizhawk 2.4.1/2.4.2 (BSNES core)") },
			{ 4784128,		new Tuple<long, int, string>(0x36F08F92040,	0,	"EmuHawk/Bizhawk 2.5.0/2.5.1 (BSNES core)") },
			{ 4759552,		new Tuple<long, int, string>(0x36F08F92040,	0,	"EmuHawk/Bizhawk 2.5.2 (BSNES core)") },
			{ 4538368,		new Tuple<long, int, string>(0x36F05F94040,	0,	"EmuHawk/Bizhawk 2.6.0/2.6.2 (BSNES core)") },
			{ 4546560,		new Tuple<long, int, string>(0x36F05F94040,	0,	"EmuHawk/Bizhawk 2.6.1 (BSNES core)") },

			// snes9x
			{ 10330112,		new Tuple<long, int, string>(0x789414,		1,	"snes9x 1.52-rr") },
			{ 7729152,		new Tuple<long, int, string>(0x890EE4,		1,	"snes9x 1.54-rr") },
			{ 5914624,		new Tuple<long, int, string>(0x6EFBA4,		1,	"snes9x 1.53") },
			{ 6909952,		new Tuple<long, int, string>(0x140405EC8,	1,	"snes9x 1.53 (x64)") },
			{ 6447104,		new Tuple<long, int, string>(0x7410D4,		1,	"snes9x 1.54/1.54.1") },
			{ 7946240,		new Tuple<long, int, string>(0x1404DAF18,	1,	"snes9x 1.54/1.54.1 (x64)") },
			{ 6602752,		new Tuple<long, int, string>(0x762874,		1,	"snes9x 1.55") },
			{ 8355840,		new Tuple<long, int, string>(0x1405BFDB8,	1,	"snes9x 1.55 (x64)") },
			{ 6856704,		new Tuple<long, int, string>(0x78528C,		1,	"snes9x 1.56/1.56.2") },
			{ 9003008,		new Tuple<long, int, string>(0x1405D8C68,	1,	"snes9x 1.56 (x64)") },
			{ 6848512,		new Tuple<long, int, string>(0x7811B4,		1,	"snes9x 1.56.1") },
			{ 8945664,		new Tuple<long, int, string>(0x1405C80A8,	1,	"snes9x 1.56.1 (x64)") },
			{ 9015296,		new Tuple<long, int, string>(0x1405D9298,	1,	"snes9x 1.56.2 (x64)") },
			{ 6991872,		new Tuple<long, int, string>(0x7A6EE4,		1,	"snes9x 1.57") },
			{ 9048064,		new Tuple<long, int, string>(0x1405ACC58,	1,	"snes9x 1.57 (x64)") },
			{ 7000064,		new Tuple<long, int, string>(0x7A7EE4,		1,	"snes9x 1.58") },
			{ 9060352,		new Tuple<long, int, string>(0x1405AE848,	1,	"snes9x 1.58 (x64)") },
			{ 8953856,		new Tuple<long, int, string>(0x975A54,		1,	"snes9x 1.59.2") },
			{ 12537856,		new Tuple<long, int, string>(0x1408D86F8,	1,	"snes9x 1.59.2 (x64)") },
			{ 9646080,		new Tuple<long, int, string>(0x97EE04,		1,	"Snes9x-rr 1.60") },
			{ 13565952,		new Tuple<long, int, string>(0x140925118,	1,	"Snes9x-rr 1.60 (x64)") },
			{ 9027584,		new Tuple<long, int, string>(0x94DB54,		1,	"snes9x 1.60") },
			{ 12836864,		new Tuple<long, int, string>(0x1408D8BE8,	1,	"snes9x 1.60 (x64)") },
			
			// bsnes (deprecated)
			{ 10096640,		new Tuple<long, int, string>(0x72BECC,		0,	"bsnes v107") },
			{ 10338304,		new Tuple<long, int, string>(0x762F2C,		0,	"bsnes v107.1") },
			{ 47230976,		new Tuple<long, int, string>(0x765F2C,		0,	"bsnes v107.2/107.3") },
			{ 142282752,	new Tuple<long, int, string>(0xA65464,		0,	"bsnes v108") },
			{ 131354624,	new Tuple<long, int, string>(0xA6ED5C,		0,	"bsnes v109") },
			{ 131543040,	new Tuple<long, int, string>(0xA9BD5C,		0,	"bsnes v110") },
			{ 51924992,		new Tuple<long, int, string>(0xA9DD5C,		0,	"bsnes v111") },
			{ 52056064,		new Tuple<long, int, string>(0xAAED7C,		0,	"bsnes v112") },
			//{ 52477952,		new Tuple<long, int, string>(/*???*/,	0,	"bsnes v115") },
			{ 9662464,		new Tuple<long, int, string>(0x67dac8,		1,	"bsnes+ 0.5") },

			// higan (deprecated)
			{ 12509184,		new Tuple<long, int, string>(0x915304,		0,	"higan v102") },
			{ 13062144,		new Tuple<long, int, string>(0x937324,		0,	"higan v103") },
			{ 15859712,		new Tuple<long, int, string>(0x952144,		0,	"higan v104") },
			{ 16756736,		new Tuple<long, int, string>(0x94F144,		0,	"higan v105tr1") },
			{ 16019456,		new Tuple<long, int, string>(0x94D144,		0,	"higan v106") },
			{ 15360000,		new Tuple<long, int, string>(0x8AB144,		0,	"higan v106.112") },
			//{ 23781376,		new Tuple<long, int, string>(/*???*/,	0,	"higan v110") },
		};

		Tuple<long, int, string> emulatorProperties;
		if (versions.TryGetValue(modules.First().ModuleMemorySize, out emulatorProperties)) {
			var address = emulatorProperties.Item1;
			var indirect = emulatorProperties.Item2;
			var name = emulatorProperties.Item3;
			
			InitMemoryOffset(address, indirect, name);
		}
	}

	if (memoryOffset == IntPtr.Zero) {	
		throw new Exception("Emulator could not be identified. (\"" + emulatorName + "\", 0x"+ modules.First().ModuleMemorySize.ToString("X4") + "/" + modules.First().ModuleMemorySize + " not found!)");
	} else {
		if(vars.debug) print("Emulator detected: \"" + emulatorName + "\" (0x" + modules.First().ModuleMemorySize.ToString("X4") + "/" + modules.First().ModuleMemorySize + ")");
	}

	modules.First().BaseAddress = memoryOffset;
	
	vars.watchers = new MemoryWatcherList
	{
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x2210) { Name = "boy_firstLetter" },
		new MemoryWatcher<ushort>((IntPtr)memoryOffset + 0x4EA3) { Name = "boy_x" },
		new MemoryWatcher<ushort>((IntPtr)memoryOffset + 0x4EA5) { Name = "boy_y" },
		new MemoryWatcher<uint>((IntPtr)memoryOffset + 0x0A49) { Name = "boy_xp" },
		new MemoryWatcher<ushort>((IntPtr)memoryOffset + 0x4EB3) { Name = "boy_hp" },
		
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0ADB) { Name = "map" },
		new MemoryWatcher<ushort>((IntPtr)memoryOffset + 0x0E4B) { Name = "music" },
		new MemoryWatcher<ushort>((IntPtr)memoryOffset + 0x0E4F) { Name = "sound" },
		
		new MemoryWatcher<ushort>((IntPtr)memoryOffset + 0x2355) { Name = "windwalker" },
		
		new MemoryWatcher<uint>((IntPtr)memoryOffset + 0x0B19) { Name = "timer" },
	};
	
	vars.timer0 = -1;
}

update
{
	vars.watchers.UpdateAll(game);

	if(vars.debug && vars.debugUpdate) print("update[" + vars.watchers.Count + "] = WRAM(" +
		"boy_x=" + vars.watchers["boy_x"].Current + ", " +
		"boy_y=" + vars.watchers["boy_y"].Current + ", " +
		"map=" + vars.watchers["map"].Current + ", " +
		"music=" + vars.watchers["music"].Current + ")");

}

start
{
	var flowerMap = vars.watchers["map"].Old != 56 && vars.watchers["map"].Current == 56;
	var nameNotEmpty = vars.watchers["boy_firstLetter"].Current > 0;
	
	var start = nameNotEmpty && flowerMap;

	if(vars.debug && vars.debugStart) print("start=" + start + " (" +
		"flowerMap[" + vars.watchers["map"].Current + "==56]==" + flowerMap + ", " +
		"nameNotEmpty==" + nameNotEmpty + ")");
	
	if(start) {
		if(vars.debug) print("+run");
	
		foreach(var split in vars.split)
		{
			vars.split[split.Key].achieved = false;
		}
	}
	
	vars.timer0 = vars.watchers["timer"].Current;
	
	return start;
}

reset
{
	var openingSequence = vars.watchers["map"].Old == 97 && vars.watchers["map"].Current == 97;

	var reset = openingSequence;
	
	if(vars.debug && vars.debugReset) print("reset=" + reset + " (" +
		"openingSequence[" + vars.watchers["map"].Current + "==97]==" + openingSequence + ")");
	
	if(reset) {
		if(vars.debug) print("-run");
	
		foreach(var split in vars.split)
		{
			vars.split[split.Key].achieved = false;
		}
	}
	
	return reset;
}

split
{
	var split = false;
	
	Action<string, bool> checkSplit = (key, condition) => {
		if (settings[key] && vars.split[key].achieved == false && condition) {
			vars.split[key].achieved = true;
			if(vars.debug) print("~split="+key);
			
			split = true;
		}
	};
	
	Func<byte, bool> Map = (map => vars.watchers["map"].Current == map);
	Func<byte, bool> Hp = (hp => vars.watchers["boy_hp"].Current == hp);
	Func<byte, byte, bool> MapTransition = ((previousMap, map) => vars.watchers["map"].Current == map && vars.watchers["map"].Old == previousMap);
	Func<ushort, bool> Music = (music => vars.watchers["music"].Current == music);
	Func<ushort, bool> Sound = (sound => vars.watchers["sound"].Current == sound);
	Func<int> XDelta = (() => (int) vars.watchers["boy_x"].Current - vars.watchers["boy_x"].Old);
	Func<ushort, bool> XReached = (x => vars.watchers["boy_x"].Current > vars.watchers["boy_x"].Old && vars.watchers["boy_x"].Current >= x);
	Func<ushort, bool> YReached = (y => vars.watchers["boy_y"].Current < vars.watchers["boy_y"].Old && vars.watchers["boy_y"].Current <= y);
	Func<uint, bool> XpGained = (xp => vars.watchers["boy_xp"].Current > vars.watchers["boy_xp"].Old && ((vars.watchers["boy_xp"].Current - vars.watchers["boy_xp"].Old) >= xp));
	Func<bool> Windwalker = (() => vars.watchers["windwalker"].Current > 0);
	Func<bool> Fanfare = (() => vars.watchers["music"].Current != vars.watchers["music"].Old && vars.watchers["music"].Current == 26);
	Func<ushort, bool> MonsterDead = ((id) => {
		var monsterSize = 0x8E;
		var monsterCount = 29;
		var monsters = memory.ReadBytes(modules.First().BaseAddress + 0x3DE5, monsterSize * monsterCount);

		for(var i = 0; i < monsterCount; i++)
		{
			var monster = monsters.Skip(i * monsterSize).Take(monsterSize);

			var hp = BitConverter.ToUInt16(monster.Skip(0x2A).Take(2).ToArray(), 0);
			var type = BitConverter.ToUInt16(monster.Skip(0x60).Take(2).ToArray(), 0);

			if(type == id)
			{
				if(hp <= 1)
				{
					return true;
				}
				break;
			}
		}
	
		return false;
	});
	
	// Act 1
	checkSplit("flowers", Map(92) && Hp(0) && XDelta() > 0 || MapTransition(92, 81) || MapTransition(92, 37));
	checkSplit("raptors", MapTransition(92, 81) || MapTransition(92, 37));
	checkSplit("thraxx", !Windwalker() && MapTransition(24, 103));
	checkSplit("graveyard", Map(39) && Fanfare());
	checkSplit("salabog", Map(1) && Fanfare());
	checkSplit("volcano", MapTransition(65, 60));
	checkSplit("magmar", Map(63) && Fanfare());
	
	// Act 2
	checkSplit("enterNobilia", Map(10) && XReached(88));
	checkSplit("marketTimer", Map(8) && Music(38) && XReached(56));
	checkSplit("vigor", Map(29) && Fanfare());
	checkSplit("temple", Map(41));
	checkSplit("megataur", Map(42) && Fanfare());
	checkSplit("rimsala", Map(88) && Fanfare());
	checkSplit("aegis", Map(9) && Fanfare());
	checkSplit("aquagoth", Map(109) && Fanfare());
	
	// Act 3
	checkSplit("dogMaze", MapTransition(113, 115));
	checkSplit("footknight", Map(25) && Fanfare());
	checkSplit("badBoy", Map(31) && Fanfare());
	checkSplit("timberdrake", Map(32) && Fanfare());
	checkSplit("verminator", Map(94) && Fanfare());
	checkSplit("sterling", Map(55) && Fanfare());
	checkSplit("mungola", Map(119) && Fanfare());
	checkSplit("glassFight", MapTransition(16, 20));
	checkSplit("windwalker", Map(57) && YReached(285));
	checkSplit("tiny", Map(87) && Fanfare());
	checkSplit("coleoptera", Windwalker() && MapTransition(24, 103));
	checkSplit("gauge", MapTransition(54, 57));
	checkSplit("rocket", MapTransition(57, 72));
	
	// Act 4
	checkSplit("professor", MapTransition(72, 70));
	checkSplit("face", Map(69) && Fanfare());
	checkSplit("saturn", MapTransition(72, 74));
	checkSplit("carltron", Map(74) && (MonsterDead(0xDF3A) || XpGained(100000) || Music(10280)));
	
	return split;
}

gameTime
{
	var deltaIgt = vars.watchers["timer"].Current - vars.timer0;
	var fpsNtsc = 60.098475521;
	var startOffset = timer.Run.Offset.TotalSeconds + 2.2;
	
	current.totalTime = deltaIgt / fpsNtsc + startOffset;
	
	return TimeSpan.FromSeconds(current.totalTime);
}

isLoading
{
	// From the AutoSplit documentation:
	// "If you want the Game Time to not run in between the synchronization interval and only ever return
	// the actual Game Time of the game, make sure to implement isLoading with a constant
	// return value of true."
	
	return true;
}
