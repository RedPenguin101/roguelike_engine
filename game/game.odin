package game

import c "../common"

Color :: c.Color
COLS :: c.COLS
ROWS :: c.ROWS
GameInput :: c.GameInput

black := Color{0,0,0,1}
white := Color{1,1,1,1}
pink := Color{245.0/255, 66.0/355, 209.0/255, 1}
blue := Color{36.0/255, 26.0/255, 122.0/255, 1}
dark_blue := Color{26.0/255, 18.0/255, 90.0/255, 1}

purple := Color{141.0/255, 58.0/255, 173.0/255, 1}

lavender := Color{123.0/255, 103.0/255, 222.0/255, 1}
dark_lavender := Color{50.0/255, 46.0/255, 98.0/255, 1}
light_lavender := Color{201.0/255, 185.0/255, 250.0/255, 1}

yellow := Color{1, 1, 0, 1}
pale_red := Color{239.0/255, 134.0/255, 118.0/255, 1}
light_grey := Color{192.0/255, 182.0/255, 179.0/255, 1}
mid_grey := Color{111.0/255, 111.0/255, 111.0/255, 1}


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

		plot_tile(0, 0, yellow, black, .AT)
		plot_tile(1, 0, white, black, .COLON)

		plot_tile(3, 0, white, black, .Y)
		plot_tile(4, 0, white, black, .o)
		plot_tile(5, 0, white, black, .u)

		plot_tile(7, 0, yellow, black, .PAREN_L)
		plot_tile(8, 0, yellow, black, .l)
		plot_tile(9, 0, yellow, black, .i)
		plot_tile(10, 0, yellow, black, .t)
		plot_tile(11, 0, yellow, black, .PAREN_R)

		plot_tile(0,  1, light_grey, blue, .BLANK)
		plot_tile(1,  1, light_grey, blue, .BLANK)
		plot_tile(2,  1, light_grey, blue, .BLANK)
		plot_tile(3,  1, light_grey, blue, .BLANK)
		plot_tile(4,  1, light_grey, blue, .BLANK)
		plot_tile(5,  1, light_grey, blue, .BLANK)
		plot_tile(6,  1, light_grey, blue, .BLANK)
		plot_tile(7,  1, light_grey, blue, .H)
		plot_tile(8,  1, light_grey, blue, .e)
		plot_tile(9,  1, light_grey, blue, .a)
		plot_tile(10, 1, light_grey, blue, .l)
		plot_tile(11, 1, light_grey, blue, .t)
		plot_tile(12, 1, light_grey, blue, .h)
		plot_tile(13, 1, light_grey, blue, .BLANK)
		plot_tile(14, 1, light_grey, blue, .BLANK)
		plot_tile(15, 1, light_grey, blue, .BLANK)
		plot_tile(16, 1, light_grey, blue, .BLANK)
		plot_tile(17, 1, light_grey, blue, .BLANK)
		plot_tile(18, 1, light_grey, blue, .BLANK)
		plot_tile(19, 1, light_grey, blue, .BLANK)

		plot_tile(0,  2, light_grey, dark_blue, .BLANK)
		plot_tile(1,  2, light_grey, dark_blue, .BLANK)
		plot_tile(2,  2, light_grey, dark_blue, .BLANK)
		plot_tile(3,  2, light_grey, dark_blue, .BLANK)
		plot_tile(4,  2, light_grey, dark_blue, .BLANK)
		plot_tile(5,  2, light_grey, dark_blue, .N)
		plot_tile(6,  2, light_grey, dark_blue, .u)
		plot_tile(7,  2, light_grey, dark_blue, .t)
		plot_tile(8,  2, light_grey, dark_blue, .r)
		plot_tile(9,  2, light_grey, dark_blue, .i)
		plot_tile(10, 2, light_grey, dark_blue, .t)
		plot_tile(11, 2, light_grey, dark_blue, .i)
		plot_tile(12, 2, light_grey, dark_blue, .o)
		plot_tile(13, 2, light_grey, dark_blue, .n)
		plot_tile(14, 2, light_grey, dark_blue, .BLANK)
		plot_tile(15, 2, light_grey, dark_blue, .BLANK)
		plot_tile(16, 2, light_grey, dark_blue, .BLANK)
		plot_tile(17, 2, light_grey, dark_blue, .BLANK)
		plot_tile(18, 2, light_grey, dark_blue, .BLANK)
		plot_tile(19, 2, light_grey, dark_blue, .BLANK)

		plot_tile(1, 3, mid_grey, black, .S)
		plot_tile(2, 3, mid_grey, black, .t)
		plot_tile(3, 3, mid_grey, black, .r)
		plot_tile(4, 3, mid_grey, black, .COLON)
		plot_tile(6, 3, mid_grey, black, .N_1)
		plot_tile(7, 3, mid_grey, black, .N_2)
		plot_tile(10, 3, mid_grey, black, .A)
		plot_tile(11, 3, mid_grey, black, .r)
		plot_tile(12, 3, mid_grey, black, .m)
		plot_tile(13, 3, mid_grey, black, .o)
		plot_tile(14, 3, mid_grey, black, .r)
		plot_tile(15, 3, mid_grey, black, .COLON)
		plot_tile(17, 3, mid_grey, black, .N_3)

		plot_tile(1,  4, light_grey, black, .S)
		plot_tile(2,  4, light_grey, black, .t)
		plot_tile(3,  4, light_grey, black, .e)
		plot_tile(4,  4, light_grey, black, .a)
		plot_tile(5,  4, light_grey, black, .l)
		plot_tile(6,  4, light_grey, black, .t)
		plot_tile(7,  4, light_grey, black, .h)
		plot_tile(9,  4, light_grey, black, .r)
		plot_tile(10,  4, light_grey, black, .a)
		plot_tile(11, 4, light_grey, black, .n)
		plot_tile(12, 4, light_grey, black, .g)
		plot_tile(13, 4, light_grey, black, .e)
		plot_tile(14, 4, light_grey, black, .COLON)
		plot_tile(16, 4, light_grey, black, .N_1)
		plot_tile(17, 4, light_grey, black, .N_4)

		plot_tile(0, 6, yellow, black, .NOTE)
		plot_tile(1, 6, white, black, .COLON)
		plot_tile(3, 6, white, black, .A)
		plot_tile(5, 6, white, black, .s)
		plot_tile(6, 6, white, black, .c)
		plot_tile(7, 6, white, black, .r)
		plot_tile(8, 6, white, black, .o)
		plot_tile(9, 6, white, black, .l)
		plot_tile(10, 6, white, black, .l)
		plot_tile(12, 6, white, black, .e)
		plot_tile(13, 6, white, black, .n)
		plot_tile(14, 6, white, black, .t)
		plot_tile(15, 6, white, black, .i)
		plot_tile(16, 6, white, black, .t)
		plot_tile(17, 6, white, black, .l)
		plot_tile(18, 6, white, black, .e)
		plot_tile(19, 6, white, black, .d)

		plot_tile(3, 7, purple, black, .D_QUOTE)
		plot_tile(4, 7, purple, black, .n)
		plot_tile(5, 7, purple, black, .u)
		plot_tile(6, 7, purple, black, .g)
		plot_tile(7, 7, purple, black, .l)
		plot_tile(8, 7, purple, black, .o)
		plot_tile(9, 7, purple, black, .f)
		plot_tile(10, 7, purple, black, .l)
		plot_tile(11, 7, purple, black, .e)
		plot_tile(12, 7, purple, black, .m)
		plot_tile(13, 7, purple, black, .g)
		plot_tile(14, 7, purple, black, .a)
		plot_tile(15, 7, purple, black, .n)
		plot_tile(16, 7, purple, black, .a)
		plot_tile(17, 7, purple, black, .D_QUOTE)

		plot_tile(0, 9, yellow, pale_red, .HYPHEN)
		plot_tile(1, 9, white, black, .COLON)
		plot_tile(3, 9, white, black, .A)
		plot_tile(5, 9, white, black, .d)
		plot_tile(6, 9, white, black, .o)
		plot_tile(7, 9, white, black, .o)
		plot_tile(8, 9, white, black, .r)
		plot_tile(10, 9, white, black, .k)
		plot_tile(11, 9, white, black, .e)
		plot_tile(12, 9, white, black, .y)

		plot_tile(0, 11, light_lavender, dark_lavender, .OMEGA)
		plot_tile(1, 11, white, black, .COLON)
		plot_tile(3, 11, lavender, black, .T)
		plot_tile(4, 11, lavender, black, .h)
		plot_tile(5, 11, lavender, black, .e)
		plot_tile(7, 11, lavender, black, .d)
		plot_tile(8, 11, lavender, black, .u)
		plot_tile(9, 11, lavender, black, .n)
		plot_tile(10, 11, lavender, black, .g)
		plot_tile(11, 11, lavender, black, .e)
		plot_tile(12, 11, lavender, black, .o)
		plot_tile(13, 11, lavender, black, .n)
		plot_tile(15, 11, lavender, black, .e)
		plot_tile(16, 11, lavender, black, .x)
		plot_tile(17, 11, lavender, black, .i)
		plot_tile(18, 11, lavender, black, .t)

		plot_tile(2, 33, white, black, .HYPHEN)
		plot_tile(3, 33, white, black, .HYPHEN)
		plot_tile(5, 33, white, black, .D)
		plot_tile(6, 33, white, black, .e)
		plot_tile(7, 33, white, black, .p)
		plot_tile(8, 33, white, black, .t)
		plot_tile(9, 33, white, black, .h)
		plot_tile(11, 33, white, black, .N_1)
		plot_tile(13, 33, white, black, .HYPHEN)
		plot_tile(14, 33, white, black, .HYPHEN)

		plot_tile(21, 0, white, black, .H)
		plot_tile(22, 0, white, black, .e)
		plot_tile(23, 0, white, black, .l)
		plot_tile(24, 0, white, black, .l)
		plot_tile(25, 0, white, black, .o)
		plot_tile(27, 0, white, black, .a)
		plot_tile(28, 0, white, black, .n)
		plot_tile(29, 0, white, black, .d)
		plot_tile(31, 0, white, black, .w)
		plot_tile(32, 0, white, black, .e)
		plot_tile(33, 0, white, black, .l)
		plot_tile(34, 0, white, black, .c)
		plot_tile(35, 0, white, black, .o)
		plot_tile(36, 0, white, black, .m)
		plot_tile(37, 0, white, black, .e)
		plot_tile(38, 0, white, black, .COMMA)
		plot_tile(40, 0, white, black, .a)
		plot_tile(41, 0, white, black, .d)
		plot_tile(42, 0, white, black, .v)
		plot_tile(43, 0, white, black, .e)
		plot_tile(44, 0, white, black, .n)
		plot_tile(45, 0, white, black, .t)
		plot_tile(46, 0, white, black, .u)
		plot_tile(47, 0, white, black, .r)
		plot_tile(48, 0, white, black, .e)
		plot_tile(49, 0, white, black, .r)
		plot_tile(50, 0, white, black, .COMMA)
		plot_tile(52, 0, white, black, .t)
		plot_tile(53, 0, white, black, .o)
		plot_tile(55, 0, white, black, .t)
		plot_tile(56, 0, white, black, .h)
		plot_tile(57, 0, white, black, .e)
		plot_tile(59, 0, white, black, .D)
		plot_tile(60, 0, white, black, .u)
		plot_tile(61, 0, white, black, .n)
		plot_tile(62, 0, white, black, .g)
		plot_tile(63, 0, white, black, .e)
		plot_tile(64, 0, white, black, .o)
		plot_tile(65, 0, white, black, .n)
		plot_tile(66, 0, white, black, .s)
		plot_tile(68, 0, white, black, .o)
		plot_tile(69, 0, white, black, .f)
		plot_tile(71, 0, white, black, .D)
		plot_tile(72, 0, white, black, .o)
		plot_tile(73, 0, white, black, .o)
		plot_tile(74, 0, white, black, .m)
		plot_tile(75, 0, white, black, .EXCL)

		plot_tile(21, 1, white, black, .R)
		plot_tile(22, 1, white, black, .e)
		plot_tile(23, 1, white, black, .t)
		plot_tile(24, 1, white, black, .r)
		plot_tile(25, 1, white, black, .e)
		plot_tile(26, 1, white, black, .i)
		plot_tile(27, 1, white, black, .v)
		plot_tile(28, 1, white, black, .e)
		plot_tile(30, 1, white, black, .t)
		plot_tile(31, 1, white, black, .h)
		plot_tile(32, 1, white, black, .e)
		plot_tile(34, 1, yellow, black, .A)
		plot_tile(35, 1, yellow, black, .m)
		plot_tile(36, 1, yellow, black, .u)
		plot_tile(37, 1, yellow, black, .l)
		plot_tile(38, 1, yellow, black, .e)
		plot_tile(39, 1, yellow, black, .t)
		plot_tile(41, 1, yellow, black, .o)
		plot_tile(42, 1, yellow, black, .f)
		plot_tile(44, 1, yellow, black, .Y)
		plot_tile(45, 1, yellow, black, .e)
		plot_tile(46, 1, yellow, black, .n)
		plot_tile(47, 1, yellow, black, .d)
		plot_tile(48, 1, yellow, black, .o)
		plot_tile(49, 1, yellow, black, .r)
		plot_tile(51, 1, white, black, .f)
		plot_tile(52, 1, white, black, .r)
		plot_tile(53, 1, white, black, .o)
		plot_tile(54, 1, white, black, .m)
		plot_tile(56, 1, white, black, .t)
		plot_tile(57, 1, white, black, .h)
		plot_tile(58, 1, white, black, .e)
		plot_tile(60, 1, white, black, .N_2)
		plot_tile(61, 1, white, black, .N_6)
		plot_tile(62, 1, white, black, .t)
		plot_tile(63, 1, white, black, .h)
		plot_tile(65, 1, white, black, .f)
		plot_tile(66, 1, white, black, .l)
		plot_tile(67, 1, white, black, .o)
		plot_tile(68, 1, white, black, .o)
		plot_tile(69, 1, white, black, .r)
		plot_tile(71, 1, white, black, .a)
		plot_tile(72, 1, white, black, .n)
		plot_tile(73, 1, white, black, .d)
		plot_tile(75, 1, white, black, .e)
		plot_tile(76, 1, white, black, .s)
		plot_tile(77, 1, white, black, .c)
		plot_tile(78, 1, white, black, .a)
		plot_tile(79, 1, white, black, .p)
		plot_tile(80, 1, white, black, .e)
		plot_tile(82, 1, white, black, .w)
		plot_tile(83, 1, white, black, .i)
		plot_tile(84, 1, white, black, .t)
		plot_tile(85, 1, white, black, .h)
		plot_tile(87, 1, white, black, .i)
		plot_tile(88, 1, white, black, .t)
		plot_tile(89, 1, white, black, .EXCL)

		plot_tile(21, 2, purple, black, .P)
		plot_tile(22, 2, purple, black, .r)
		plot_tile(23, 2, purple, black, .e)
		plot_tile(24, 2, purple, black, .s)
		plot_tile(25, 2, purple, black, .s)
		plot_tile(27, 2, purple, black, .LT)
		plot_tile(28, 2, purple, black, .QMARK)
		plot_tile(29, 2, purple, black, .GT)
		plot_tile(31, 2, purple, black, .f)
		plot_tile(32, 2, purple, black, .o)
		plot_tile(33, 2, purple, black, .r)
		plot_tile(35, 2, purple, black, .h)
		plot_tile(36, 2, purple, black, .e)
		plot_tile(37, 2, purple, black, .l)
		plot_tile(38, 2, purple, black, .p)
		plot_tile(40, 2, purple, black, .a)
		plot_tile(41, 2, purple, black, .t)
		plot_tile(43, 2, purple, black, .a)
		plot_tile(44, 2, purple, black, .n)
		plot_tile(45, 2, purple, black, .y)
		plot_tile(47, 2, purple, black, .t)
		plot_tile(48, 2, purple, black, .i)
		plot_tile(49, 2, purple, black, .m)
		plot_tile(50, 2, purple, black, .e)
		plot_tile(51, 2, purple, black, .PERIOD)

		memory.initialized = true
	}


	/****************
	 * INPUT HANDLE *
	 ****************/

	plot_tile(state.player_pos.x, state.player_pos.y, black, black, .BLANK)

	released :: proc(btn:c.ButtonState) -> bool { return !btn.is_down && btn.was_down }

	if released(input.keyboard[.UP]) do state.player_pos.y -= 1
	if released(input.keyboard[.DOWN]) do state.player_pos.y += 1
	if released(input.keyboard[.LEFT]) do state.player_pos.x -= 1
	if released(input.keyboard[.RIGHT]) do state.player_pos.x += 1

	plot_tile(state.player_pos.x, state.player_pos.y, yellow, black, .AT)
	return true
}
