package common

/*

*/

Color :: [4]f32

// Defines the number of tiles that will be shown on the screen
COLS :: 100
ROWS :: 34

PlatformPlotTileFn :: proc(x,y:int, fg,bg:Color, glyph:DisplayGlyph)

PlatformAPI :: struct {
	plot_tile : PlatformPlotTileFn
}

DisplayGlyph :: enum {}
