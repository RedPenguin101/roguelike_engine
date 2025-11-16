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

		plot_tile(0, 0, pink, blue, .H)
		plot_tile(1, 0, white, black, .E)
		plot_tile(2, 0, white, black, .L)
		plot_tile(3, 0, white, black, .L)
		plot_tile(4, 0, white, black, .O)
		plot_tile(6, 0, white, black, .W)
		plot_tile(7, 0, white, black, .O)
		plot_tile(8, 0, white, black, .R)
		plot_tile(9, 0, white, black, .L)
		plot_tile(10, 0, white, black, .D)

		plot_tile(0, 1, white, black, .N_1)
		plot_tile(1, 1, white, black, .N_2)
		plot_tile(2, 1, white, black, .N_3)
		plot_tile(3, 1, white, black, .N_4)
		plot_tile(4, 1, white, black, .N_5)
		plot_tile(5, 1, white, black, .N_6)
		plot_tile(6, 1, white, black, .N_7)
		plot_tile(7, 1, white, black, .N_8)
		plot_tile(8, 1, white, black, .N_9)
		plot_tile(9, 1, white, black, .N_0)

		memory.initialized = true
	}


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
