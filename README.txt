Rouguelike Engine
=================

A simple SDL2 platform layer for the development of Roguelike games
with hot-reloading. The renderer is based on Brogue Community
edition[1]. The tileset png from the Brogue repo can be used as-is by
dropping it in the build folder. A simple demo screen is set up in
'demo.odin'. The player character can be moved with the arrow keys.

To use:

1. Install the Odin compiler[2].
2. create a 'build' folder in the project root directory.
3. Download the 'tiles.png' tileset from the Brogue repository and add
   it to the build folder
4. If you are on Windows, copy the [SDL DLLs] from your Odin vendor
   library directory to the build directory. Or if you are on Linux
   or Mac, use your package manager to install the SDL2 and SDL2_Image
   libraries.
5. Set the COLS and ROWS globals in common.odin to the number of tiles
   your screen will have. The default is 100 columns and 34 rows.
6. Write your game in the Game package folder, adding to the game
   state as necessary. The main game loop should be implemented in the
   `game_update` function.
7. Write glyphs to the 'Screen' using the platform API function
   `plot_tile`.

[1]: https://github.com/tmewett/BrogueCE
[2]: https://odin-lang.org
