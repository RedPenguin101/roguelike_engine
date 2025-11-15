package common

Color :: [4]f32

// Defines the number of tiles that will be shown on the screen
COLS :: 100
ROWS :: 34

PlatformPlotTileFn :: proc(x,y:int, fg,bg:Color, glyph:DisplayGlyph)

PlatformAPI :: struct {
	plot_tile : PlatformPlotTileFn
}

DisplayGlyph :: enum {
	NULL,
	N_0, N_1, N_2, N_3, N_4, N_5, N_6, N_7, N_8, N_9,
	AT,
	A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z,
}
