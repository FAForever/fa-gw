# Galactic War
This is the Lua code of the **Galactic War support mod** for the [Forged Alliance Forever](https://www.faforever.com/).

## Launching a game
The game is set up by a very similar way as a ladder game. It doesn't open the normal game lobby where players could change anything, instead just shows the "Setting up Automatch" screen and everything happens in the background. Once all players are connected, the game starts.

### Required files
This is the list of files for the GW mod to work. They need to be downloaded from the server into the correct folders:
1. `init_gw.lua` [Init file](init_gw.lua) of the mod placed in `\bin` folder.
2. `gw_mod.gw` The actual mod, placed in the `\gamedata` folder. All folders and files from this repo packed into a `.zip` file and renamed to `.gw`. The file extension is used by the init file to load only the files we need for the GW.
3. `gw_reinforcements.gw` A Lua file with the in-game unit [reinforcements](lua/gwReinforcementList.lua) that will be generated before every game. Again packed into `.zip` and renamed, placed in the `\gamedata` folder. I will specify later what structure it needs to work...
4. Similar as above, a file with the map scenario. Again I will have to figure out how exactly this needs to be set and if it can be done directly in the game without the need of generating it at all.

### Reguired command line arguments
To properly set up a GW game, several **command line arguments** needs to be provided at the game start by the FAF client.

* Common
  * `/init init_gw.lua` The init file for the GW mod, in the `\bin` folder of the FAF game patch.
  * `/players number` Total number of players required to launch the game.
* Per player
  * `/faction` Faction of the player. Example: `/uef` (This one is kinda an exception, when it's not using a number to set the faction, but the name of the argument directly.)
  * `/team number` Number of the team, the player belong to.
  * `/rank number` Rank of the player.
  * `/StartSpot number` Starting position of the player.

## Game to Server communication
The game uses the standard `GPGNetSend()` protocol to send information back to the server. It's used to imform about players dying, reinforcements being used, game end, etc...

### GW specific messages
TODO: A proper list with all the things that the game sends.
* `GpgNetSend('ArmyCalled', armyIndex, groupidx)` When a group of units from the reinforcements is used.
* `GpgNetSend('GameResult', armyIndex, result)` Army brain reporting a result. Result is a string containing a result type and the score. GW adds two new result types `recall` and `autorecall`. Example: `GpgNetSend('GameResult', 1, 'recall -10')`.

## Offline testing
To debug many thing, make and test new features the game can be started offline as well. It just needs to be provided with correct data.
TODO: Proper guide for offline testing.
