package game

import "../common"
import "core:log"

Color       :: common.Color
COLS        :: common.COLS
ROWS        :: common.ROWS
GameInput   :: common.GameInput
ButtonState :: common.ButtonState
Glyph       :: common.DisplayGlyph

DBG :: log.debug
INFO :: log.info

/* Colors */

black := Color{0,0,0,1}
white := Color{1,1,1,1}
red   := Color{1,0,0,1}
green := Color{122.0/255,226.0/255,125.0/255,1}
blue  := Color{0,0,1,1}
yellow := Color{1,1,0,1}
grey := Color{0.3,0.3,0.3,1}
pink  := Color{ 1, 109.0/255, 194.0/255, 1 }

pale_red       := Color{239.0/255, 134.0/255, 118.0/255, 1}
dark_blue      := Color{26.0/255, 18.0/255, 90.0/255, 1}
purple         := Color{141.0/255, 58.0/255, 173.0/255, 1}
lavender       := Color{123.0/255, 103.0/255, 222.0/255, 1}
dark_lavender  := Color{50.0/255, 46.0/255, 98.0/255, 1}
light_lavender := Color{201.0/255, 185.0/255, 250.0/255, 1}
light_grey     := Color{192.0/255, 182.0/255, 179.0/255, 1}
mid_grey       := Color{111.0/255, 111.0/255, 111.0/255, 1}

/***************
 * SEC: Camera *
 ***************/

Camera :: struct {
	focus  : V3i,
	dims   : V3i,
}

Basis :: struct {
    origin,x,y:V2i
}

dot :: proc(v,w:V2i) -> int {
	return v.x*w.x + v.y*w.y
}

basis_xform_point :: proc(b:Basis, v:V2i) -> V2i
{
    v_b := -b.origin + V2i{dot(v, b.x), dot(v, b.y)}
    return v_b
}

camera_xform :: proc(cam:Camera, tile:V3i) -> (on_screen:bool, screen_tile:V2i) {
	// takes a map tile location and transforms it the screen tile location
	if tile.z != cam.focus.z do return false, {}

	rect := tile_rect_from_center_and_dim(cam.focus.xy, cam.dims.xy)

	if !in_rect(tile.xy, rect) do return false, {}

	camera_basis := Basis{
		origin = {rect.x, -rect.w},
		x = {1, 0},
		y = {0, -1}
	}

	xformed_tile := basis_xform_point(camera_basis, tile.xy)

	if !in_rect(xformed_tile, {0,0,COLS,ROWS}) do return false, {}
	return true, xformed_tile
}

map_xform :: proc(cam:Camera, tile:V2i) -> V3i {
	rect := tile_rect_from_center_and_dim(cam.focus.xy, cam.dims.xy)

	map_basis := Basis{
		origin = -rect.xw,
		x = {1, 0},
		y = {0, -1}
	}

	xformed_tile := basis_xform_point(map_basis, tile)

	xformed_tile3 := V3i{xformed_tile.x, xformed_tile.y, cam.focus.z}

	return xformed_tile3
}

/*******************
 * SEC: Misc Utils *
 *******************/

pressed :: proc(b:ButtonState) -> bool {return b.is_down && !b.was_down}
held :: proc(b:ButtonState) -> bool {return b.repeat > 30}
pressed_or_held :: proc(b:ButtonState) -> bool {return pressed(b) || held(b)}

write_string_to_screen :: proc(loc:V2i, str:string, text_col, bg_col:Color) {
	for x in 0..<len(str)
 	{
		plot_loc := loc+{x, 0}
		if !in_rect(plot_loc, {0,0,COLS, ROWS}) do continue
		rune := str[x]
		glyph := Glyph(int(rune))
		plot_tile(plot_loc, text_col, bg_col, glyph)
	}
}

/**************************
 * SEC: Gamestate structs *
 **************************/

plot_tile : common.PlatformPlotTileFn

GameState :: struct {
	player_pos : V3i,
	cam:Camera,
	hovered_tile:V3i,
}

GameMemory :: struct {
	game_state : GameState,
	initialized : bool,
	platform : common.PlatformAPI,
}

/**********************
 * Game API functions *
 **********************/

@(export)
game_state_init :: proc(platform_api:common.PlatformAPI) -> rawptr {
	game_memory := new(GameMemory)
	game_memory.platform = platform_api
	plot_tile = platform_api.plot_tile
	return game_memory
}

@(export)
reinit :: proc(platform_api:common.PlatformAPI) {
	plot_tile = platform_api.plot_tile
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
	cam := &state.cam

	/*****************
 	 * SEC: MEM INIT *
 	 *****************/

	if !memory.initialized {
		state.player_pos = {COLS/2, ROWS/2, 0}
		cam.focus = {COLS/2,ROWS/2,0}
		cam.dims  = {COLS, ROWS, 1}
		memory.initialized = true
	}

	// clear screen
	for col in 0..<common.COLS {
		for row in 0..<common.ROWS {
			plot_tile({col, row}, black, black, .BLANK)
		}
	}

	/***********************
 	 * SEC: INPUT HANDLING *
 	 ***********************/

	state.hovered_tile = map_xform(cam^, input.mouse.tile)
	lmb := pressed(input.mouse.lmb)
	rmb := pressed(input.mouse.rmb)

	// SEC: Mouse

	if lmb do DBG("lmb pressed")
	if rmb do DBG("rmb pressed")

	// SEC: Keyboard

	{
		if pressed(input.keyboard[.UP])    do state.player_pos.y += 1
		if pressed(input.keyboard[.DOWN])  do state.player_pos.y -= 1
		if pressed(input.keyboard[.LEFT])  do state.player_pos.x -= 1
		if pressed(input.keyboard[.RIGHT]) do state.player_pos.x += 1
	}

	/*******************
 	 * SEC: DRAW MAP *
 	 *******************/

	visible, screen_tile := camera_xform(cam^, state.player_pos)
	if visible {
		plot_tile(screen_tile, yellow, black, .AT)
	}

	/****************
 	 * SEC: DRAW UI *
 	 ****************/

	visible, screen_tile = camera_xform(cam^, state.hovered_tile)
	if visible {
		plot_tile(screen_tile, black, white, .HAT)
	}

 	{
		plot_tile({0, 0}, yellow, black, .AT)
		write_string_to_screen({1,0}, ": You", white, black)
		write_string_to_screen({7,0}, "(lit)", yellow, black)
		write_string_to_screen({0,1}, "       Health       ", light_grey, blue)
		write_string_to_screen({0,2}, "     Nutrition      ", light_grey, dark_blue)
		write_string_to_screen({1,3}, "Str: 12  Armor:3", mid_grey, black)
		write_string_to_screen({1,4}, "Stealth range: 14", light_grey, black)

		plot_tile({0, 6}, yellow, black, .NOTE)
		write_string_to_screen({1,6}, ": A scroll entitled", white, black)

		write_string_to_screen({3,7}, "\"nugloflemgana\"", purple, black)

		plot_tile({0, 9}, yellow, pale_red, .HYPHEN)
		write_string_to_screen({1,9}, ": A door key", white, black)

		plot_tile({0, 11}, light_lavender, dark_lavender, .OMEGA)
		plot_tile({1, 11}, white, black, .COLON)
		write_string_to_screen({3,11}, "The Dungeon Exit", lavender, black)

		write_string_to_screen({2,33}, "-- Depth 1 --", white, black)

		write_string_to_screen({21,0}, "Hello and welcome, adventurer, to the Dungeons of Doom!", white, black)
		write_string_to_screen({21,1}, "Retrieve the", white, black)
		write_string_to_screen({34,1}, "Amulet of Yendor", yellow, black)
		write_string_to_screen({51,1}, "from the 26th floor and escape with it!", white, black)
		write_string_to_screen({21,2}, "Press <?> for help at any time.", purple, black)
	}

	return true
}
