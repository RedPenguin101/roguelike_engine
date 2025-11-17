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

black          := Color{0,0,0,1}
white          := Color{1,1,1,1}
pink           := Color{245.0/255, 66.0/355, 209.0/255, 1}
yellow         := Color{1, 1, 0, 1}
pale_red       := Color{239.0/255, 134.0/255, 118.0/255, 1}
blue           := Color{36.0/255, 26.0/255, 122.0/255, 1}
dark_blue      := Color{26.0/255, 18.0/255, 90.0/255, 1}
purple         := Color{141.0/255, 58.0/255, 173.0/255, 1}
lavender       := Color{123.0/255, 103.0/255, 222.0/255, 1}
dark_lavender  := Color{50.0/255, 46.0/255, 98.0/255, 1}
light_lavender := Color{201.0/255, 185.0/255, 250.0/255, 1}
light_grey     := Color{192.0/255, 182.0/255, 179.0/255, 1}
mid_grey       := Color{111.0/255, 111.0/255, 111.0/255, 1}

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

	plot_tile(state.player_pos.x, state.player_pos.y, black, black, .BLANK)

	released :: proc(btn:ButtonState) -> bool { return !btn.is_down && btn.was_down }

	if released(input.keyboard[.UP])    do state.player_pos.y -= 1
	if released(input.keyboard[.DOWN])  do state.player_pos.y += 1
	if released(input.keyboard[.LEFT])  do state.player_pos.x -= 1
	if released(input.keyboard[.RIGHT]) do state.player_pos.x += 1

	plot_tile(state.player_pos.x, state.player_pos.y, yellow, black, .AT)
	return true
}
