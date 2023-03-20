# sourcemod-nt-spawnpoint-rescue
Experimental SourceMod plugin for Neotokyo. If a player spawns to incorrect location, move them to a valid spawn point.

The plugin will attempt to avoid stacking players in the same spawn to some extent, but sometimes this will be unavoidable.

## Logging

The server will log the error, and also notifies players (max. once per map) about the invalid spawn point, to hopefully get the attention of the map maker:

![spawn-rescue-example](https://user-images.githubusercontent.com/6595066/226464794-09104505-33ed-4cd5-ad6c-0f9fe59bea17.png)

## Build requirements
* SourceMod 1.11 or newer
  * Older versions may work, but you'll need to appropriate [DHooks extension](https://forums.alliedmods.net/showpost.php?p=2588686) for your version of SourceMod. SM 1.11 and newer do not require this extension.
* [Neotokyo include](https://github.com/softashell/sourcemod-nt-include)

## Installation
* Move the compiled .smx binary to `addons/sourcemod/plugins`
* Move the [gamedata file](addons/sourcemod/gamedata/neotokyo/spawnpoint_rescue.txt) to `addons/sourcemod/gamedata/neotokyo`
