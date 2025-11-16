package game

import c "../common"

Color :: c.Color
COLS :: c.COLS
ROWS :: c.ROWS
GameInput :: c.GameInput

black := Color{0,0,0,1}
white := Color{1,1,1,1}
pink := Color{245.0/255, 66.0/355, 209.0/255, 1}
blue := Color{0, 0, 1, 1}
yellow := Color{1, 1, 0, 1}

/**********************
 * Game API functions *
 **********************/

V2i :: [2]int

GameState :: struct {
	player_pos : V2i
}

GameMemory :: struct {
	game_state : GameState,
	initialized : bool,
	platform : c.PlatformAPI,
}

@(export)
game_state_init :: proc(platform_api:c.PlatformAPI) -> rawptr {
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

	if !memory.initialized {
		memory.initialized = true
		memory.game_state.player_pos = {COLS/2, ROWS/2}
	}

	/***************
	 * LOOP LOCALS *
	 ***************/

	state := &memory.game_state
	plot_tile := memory.platform.plot_tile

	/****************
	 * INPUT HANDLE *
	 ****************/

	plot_tile(state.player_pos.x, state.player_pos.y, black, black, .NULL)

	released :: proc(btn:c.ButtonState) -> bool { return !btn.is_down && btn.was_down }

	if released(input.keyboard[.UP]) do state.player_pos.y -= 1
	if released(input.keyboard[.DOWN]) do state.player_pos.y += 1
	if released(input.keyboard[.LEFT]) do state.player_pos.x -= 1
	if released(input.keyboard[.RIGHT]) do state.player_pos.x += 1

	plot_tile(state.player_pos.x, state.player_pos.y, pink, blue, .AT)
	return true
}
