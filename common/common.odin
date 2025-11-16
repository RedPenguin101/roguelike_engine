package common

import "core:dynlib"
import "core:os"

/*************
 * Constants *
 *************/

// Defines the number of tiles that will be shown on the screen
COLS :: 100
ROWS :: 34

/**********
 * Basics *
 **********/

Color :: [4]f32

/************
 * Game API *
 ************/

GameUpdateFn :: proc(time_delta:f32, memory:rawptr, input:GameInput) -> bool
GameInitFn   :: proc(PlatformAPI) -> rawptr
GameDestroyFn :: proc(memory:rawptr)

GameAPI :: struct {
	update: GameUpdateFn,
	init: GameInitFn,
	destroy: GameDestroyFn,
	lib: dynlib.Library,
	write_time: os.File_Time,
}

/****************
 * Platform API *
 ****************/

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
/**************
 * Game Input *
 **************/

ButtonState :: struct {
	is_down: bool,
	was_down: bool,
	repeat: f32,
}

KeyboardKey :: enum {
	N_1, N_2, N_3, N_4, N_5, N_6, N_7, N_8, N_9, N_0,
	A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z,
	UP, DOWN, LEFT, RIGHT,
	CTRL,SHIFT,META,
}

KeyboardInput :: [KeyboardKey]ButtonState

MouseInput :: struct {
	position, previous_position:[2]f32,
	moved : bool,
	lmb : ButtonState,
	rmb : ButtonState,
	mmb : ButtonState,
}

GameInput :: struct {
	mouse : MouseInput,
	keyboard:KeyboardInput,
}
