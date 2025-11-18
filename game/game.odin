package game

import common "../common"

Color       :: common.Color
COLS        :: common.COLS
ROWS        :: common.ROWS
GameInput   :: common.GameInput
ButtonState :: common.ButtonState

/***********
 * Globals *
 ***********/

black          := Color{0, 0, 0, 1}
yellow         := Color{1, 1, 0, 1}

/**********************
 * Game API functions *
 **********************/

GameState :: struct {
	player_pos : [2]int
}

GameMemory :: struct {
	game_state : GameState,
	initialized : bool,
	platform : common.PlatformAPI,
}

@(export)
game_state_init :: proc(platform_api:common.PlatformAPI) -> rawptr {
	game_memory := new(GameMemory)
	game_memory.platform = platform_api
	return game_memory
}

/* SEC: GS Destroy */

@(export)
game_state_destroy :: proc(memory:^GameMemory) {
	free(memory)
}

@(export)
game_update :: proc(time_delta:f32, memory:^GameMemory, input:GameInput) -> bool {
	/***************
	 * LOOP LOCALS *
	 ***************/

	state := &memory.game_state
	plot_tile := memory.platform.plot_tile

	/***************
	 * Memory Init *
	 ***************/

	if !memory.initialized {
		memory.game_state.player_pos = {COLS/2, ROWS/2}
		setup_dummy_screen(memory)
		memory.initialized = true
	}

	/****************
	 * INPUT HANDLE *
	 ****************/

	if input.mouse.moved {
		old := input.mouse.previous_tile
		nw := input.mouse.tile
		plot_tile(old.x, old.y, black, black, .BLANK)
		plot_tile(nw.x, nw.y, black, white, .BLANK)
	}

	if released(input.mouse.lmb) do plot_tile(input.mouse.tile.x, input.mouse.tile.y, yellow, black, .SIG)

	plot_tile(state.player_pos.x, state.player_pos.y, black, black, .BLANK)

	released :: proc(btn:ButtonState) -> bool { return !btn.is_down && btn.was_down }

	if released(input.keyboard[.UP])    do state.player_pos.y -= 1
	if released(input.keyboard[.DOWN])  do state.player_pos.y += 1
	if released(input.keyboard[.LEFT])  do state.player_pos.x -= 1
	if released(input.keyboard[.RIGHT]) do state.player_pos.x += 1

	plot_tile(state.player_pos.x, state.player_pos.y, yellow, black, .AT)
	return true
}
