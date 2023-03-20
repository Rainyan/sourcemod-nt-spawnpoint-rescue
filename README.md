# sourcemod-nt-spawnpoint-rescue
Experimental SourceMod plugin for Neotokyo. If a player spawns to incorrect location, move them to a valid spawn point.

The plugin will attempt to avoid stacking players in the same spawn to some extent, but sometimes this will be unavoidable.

## Logging

The server will log the error, and also notifies players (max. once per map) about the invalid spawn point, to hopefully get the attention of the map maker:

![spawn-rescue-example](https://user-images.githubusercontent.com/6595066/226464794-09104505-33ed-4cd5-ad6c-0f9fe59bea17.png)

The server's error log will contain more detailed info, with potentially problematic spawn points:
```

L 03/20/2023 - 22:58:48: [SPAWN RESCUE] MAP ERROR: Player spawned outside a valid spawn point! This is an error with map's spawn points being too close to each other or the surrounding geometry; please let the mapper know so they can fix the problem!
L 03/20/2023 - 22:58:48: 	Possibly problematic spawn(s):
L 03/20/2023 - 22:58:48: 	info_player_defender: position 388.473999, -118.125999, -476.000000
L 03/20/2023 - 22:58:48: 	info_player_attacker: position 68.473800, -118.125999, -512.000000
L 03/20/2023 - 22:58:48: 	info_player_attacker: position 83.000000, -104.000000, -512.000000
L 03/20/2023 - 22:58:48: 	info_player_attacker: position 57.000000, -88.000000, -512.000000
L 03/20/2023 - 22:58:48: 	info_player_defender: position 364.000000, -109.000000, -476.000000
L 03/20/2023 - 22:58:48: 	info_player_defender: position 379.000000, -90.000000, -476.000000
```

Please note that any pair of spawn points closer than 128 units, with both spawns being occupied by a player, will be considered invalid by the engine,
so the error is usually more about positional relation between multiple spawn points, rather than a specific spawn.

## Build requirements
* SourceMod 1.11 or newer
  * Older versions may work, but you'll need to appropriate [DHooks extension](https://forums.alliedmods.net/showpost.php?p=2588686) for your version of SourceMod. SM 1.11 and newer do not require this extension.
* [Neotokyo include](https://github.com/softashell/sourcemod-nt-include)
