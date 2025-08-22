# FAF Galactic War game mod

This is Lua game mod for [Forged Alliance Forever](https://www.faforever.com/) Galactic War

## Related repositories
- [Galactic War client](https://github.com/speed2CZ/speed-faf-client) - A FAF client capable of communicating with this server. Provides galaxy editor, testing and playing the Galactic War.
- [Galactic War server](https://github.com/faForever/faf-gw-server) - A Node.js WebSocket server for managing the universe state, core logic and set up games.

## Launching a game
The game is set up by a very similar way as a ladder game. It doesn't open the normal game lobby where players could change anything, instead just shows the "Setting up Automatch" screen and everything happens in the background. Once all players are connected, the game starts.

### Required files
This is the list of files for the GW mod to work. They need to be downloaded from the server into the correct folders:
1. `init_gw.lua` [Init file](init_gw.lua) of the mod placed in `\bin` folder.
2. `gw_mod.gw` The actual mod, placed in the `\gamedata` folder. All folders and files from this repo packed into a `.zip` file and renamed to `.gw`. The file extension is used by the init file to load only the files we need for the GW.
3. `gw_reinforcements.gw` A Lua file with the in-game unit [reinforcements](lua/gwReinforcementList.lua) that will be generated before every game. Again packed into `.zip` and renamed, placed in the `\gamedata` folder. I will specify later what structure it needs to work...
4. `gw_scenario.gw` Generated maps's `_scenario.lua` file to be hooked for the reinforcements functionality. See `EXAMPLE_MAP_scenario.lua`.

### Reguired command line arguments
To properly set up a GW game, several **command line arguments** needs to be provided at the game start by the FAF client.

* Common
  * `/init init_gw.lua` The init file for the GW mod, in the `\bin` folder of the FAF game patch.
  * `/players number` Total number of players required to launch the game.
* Per player
  * `/faction number` Faction of the player. Example: `/faction 0` for UEF.
  * `/team number` Number of the team, the player belong to.
  * `/rank number` GW Rank of the player.
  * `/startspot number` Starting position of the player.

## Communication with the lobby server
The game uses the standard `GPGNetSend()` protocol to send information back to the server. It's used to imform about players dying, reinforcements being used, game end, etc...

### GW specific messages
TODO: A proper list with all the things that the game sends.
* `GpgNetSend('ArmyCalled', armyIndex, groupidx)` When a group of units from the reinforcements is used.
* `GpgNetSend('GameResult', armyIndex, result)` Army brain reporting a result. Result is a string containing a [result type and the score](mods/galacticWar/hook/lua/aibrain.lua#L3-L5). GW adds two new result types `recall` and `autorecall`. Example: `GpgNetSend('GameResult', 1, 'recall -10')`.

## Offline testing
Currently a very crude way for testing:
1. Init file to load this mod with in-game unit [reinforcements](lua/gwReinforcementList.lua) file.
2. Edited map scenario.lua file that adds support armies. `ExtraArmies = "SUPPORT_1 SUPPORT_2"`

