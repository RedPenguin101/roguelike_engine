package platform

import "core:fmt"
import "core:log"
import "core:mem"
import "core:dynlib"
import "core:os"
import "core:os/os2"

import SDL "vendor:sdl2"

import c "../common"

Color :: c.Color
DisplayGlyph :: c.DisplayGlyph
COLS :: c.COLS
ROWS :: c.ROWS

PlatformTile :: struct {
	fg,bg : Color,
	glyph : DisplayGlyph,
	needs_update : bool,
}

/***********
 * GLOBALS *
 ***********/

TILES : [COLS][ROWS]PlatformTile

set_tile :: proc(x,y:int, fg,bg:Color, glyph:DisplayGlyph) {
	TILES[x][y].fg = fg
	TILES[x][y].bg = bg
	TILES[x][y].glyph = glyph
	TILES[x][y].needs_update = true
}

WIN : ^SDL.Window

// see create_textures proc for why we have 4 textures
TEXTURE : [4]^SDL.Texture

GLYPH_LOOKUP := [c.DisplayGlyph]int{
		.NULL=0,
		.N_0=48,
		.N_1=49,
		.N_2=50,
		.N_3=51,
		.N_4=52,
		.N_5=53,
		.N_6=54,
		.N_7=55,
		.N_8=56,
		.N_9=57,
		.AT=64,
		.A=65, .B=66, .C=67, .D=68, .E=69, .F=70, .G=71, .H=72, .I=73, .J=74, .K=75, .L=76, .M=77, .N=78, .O=79, .P=80, .Q=81, .R=82, .S=83, .T=84, .U=85, .V=86, .W=87, .X=88, .Y=89, .Z=90
}

/*****************
 * SDL Functions *
 *****************/

sdl_get_seconds_elapsed :: proc(old, current:u64) -> f32 {
	return f32(current-old) / f32(SDL.GetPerformanceFrequency())
}

color_to_sdl :: proc(c:Color) -> [4]u8 {
	sdl_col : [4]u8
	for i in 0..<4 {
		sdl_col[i] = u8(255*c[i])
	}
	return sdl_col
}

/*

Textures will be sized so the sprites are the same size as the rects
they will be rendrered to.

We make four copies of the spritesheet texture. They all have the same
characters on them, but at slightly different sizes:

Where W is the native sprite width (128) and H is the native height
(232)

- 1st texture: tiles are   W   x   H   pixels
- 2nd texture: tiles are (W+1) x   H   pixels
- 3rd texture: tiles are   W   x (H+1) pixels
- 4th texture: tiles are (W+1) x (H+1) pixels

Since the window width is usually not a multiple of 100 (the `COLS`
constant), and height not a multiple of 34 (`ROWS`), and tiles must
have integer dimensions, that means some tiles must be larger by 1
pixel than others, so that we can span the window without black
padding on the sides nor columns/rows of blank pixels between tiles.

*/

sdl_create_textures :: proc(r:^SDL.Renderer, output_width, output_height: int) {
	assert(r!=nil)

	SDL.SetHint(SDL.HINT_RENDER_SCALE_QUALITY, "best");
	TEXTURE[0] = SDL.CreateTextureFromSurface(r, PNG)
	SDL.SetTextureBlendMode(TEXTURE[0], .BLEND)
}

sdl_render :: proc() {
	if WIN == nil  do return

	renderer := SDL.GetRenderer(WIN)

	if renderer == nil {
		renderer = SDL.CreateRenderer(WIN, -1, {})
		if renderer == nil do panic("couldn't create renderer")
	}

	width, height : i32
	if SDL.GetRendererOutputSize(renderer, &width, &height) < 0 do panic("couldn't get renderer size")
	if width == 0 || height == 0 do return

	SDL.SetRenderDrawColor(renderer, 0, 0, 0, 255)
	SDL.RenderClear(renderer)

	tw := f32(width) / COLS
	th := f32(height) / ROWS

	for y in 0..<ROWS {
		for x in 0..<COLS {
			dest : SDL.Rect
			dest.x = i32(f32(x)*tw)
			dest.y = i32(f32(y)*th)
			dest.w = i32(tw)
			dest.h = i32(th)

			tile := &TILES[x][y]
			SH :: 232
			SW :: 128
			TPR :: 16

			idx := GLYPH_LOOKUP[tile.glyph]
			src : SDL.Rect
			src.w = SW
			src.h = SH
			src.x = SW * i32(idx%TPR)
			src.y = SH * i32(idx/TPR)

			bg := color_to_sdl(tile.bg)
			SDL.SetRenderDrawColor(renderer, bg.r, bg.g, bg.b, bg.a)
			SDL.RenderFillRect(renderer, &dest)

			if tile.glyph != .NULL {
				fg := color_to_sdl(tile.fg)
				SDL.SetTextureColorMod(TEXTURE[0], fg.r, fg.g, fg.b)
				SDL.RenderCopy(renderer, TEXTURE[0], &src, &dest)
			}
		}
	}

	SDL.RenderPresent(renderer)
}

sdl_resize_window :: proc(width, height:i32)
{
	if (WIN==nil) {
		flags := SDL.WindowFlags{ .RESIZABLE, .ALLOW_HIGHDPI, }
		WIN = SDL.CreateWindow("MY_ROGUELIKE",
							   SDL.WINDOWPOS_CENTERED, SDL.WINDOWPOS_CENTERED,
							   width, height,
							   flags)
		assert(WIN!=nil)
	}
}

SDL_KEYMAP : map[SDL.Scancode]c.KeyboardKey
GAME_INPUT : c.GameInput

setup_keymap :: proc() {
	sdl_a := int(SDL.SCANCODE_A)
	lib_a := int(c.KeyboardKey.A)
	for i in 0..<26 {
		sdl_key := SDL.Scancode(sdl_a+i)
		lib_key := c.KeyboardKey(lib_a+i)
		SDL_KEYMAP[sdl_key] = lib_key
	}
	sdl_1 := int(SDL.SCANCODE_1)
	lib_1 := int(c.KeyboardKey.N_1)
	for i in 0..<10 {
		sdl_key := SDL.Scancode(sdl_1+i)
		lib_key := c.KeyboardKey(lib_1+i)
		SDL_KEYMAP[sdl_key] = lib_key
	}

	SDL_KEYMAP[.UP] = .UP
	SDL_KEYMAP[.DOWN] = .DOWN
	SDL_KEYMAP[.LEFT] = .LEFT
	SDL_KEYMAP[.RIGHT] = .RIGHT

	SDL_KEYMAP[.LCTRL] = .CTRL
	SDL_KEYMAP[.RCTRL] = .CTRL
	SDL_KEYMAP[.LSHIFT] = .SHIFT
	SDL_KEYMAP[.RSHIFT] = .SHIFT
	SDL_KEYMAP[.LALT] = .META
	SDL_KEYMAP[.RALT] = .META
}

sdl_handle_event :: proc(event:SDL.Event) -> bool {
	should_quit := false
	#partial switch event.type {
		case .KEYDOWN, .KEYUP: {
			keycode := SDL.Keycode(event.key.keysym.sym)
			mods := event.key.keysym.mod
			if mods & SDL.KMOD_ALT != {} && keycode == .F4 {
				should_quit = true
			}
			scancode := event.key.keysym.scancode
			if scancode in SDL_KEYMAP
			{
				key := &GAME_INPUT.keyboard[SDL_KEYMAP[scancode]]
				key.is_down = event.key.state == SDL.PRESSED
			}
		}
		case .QUIT: {
			log.debug("SDL_QUIT")
			should_quit = true
		}
		case .WINDOWEVENT: {
			#partial switch event.window.event {
				case .RESIZED: {
					log.debug("SDL_RESIZE", event.window.data1, event.window.data2)
				}
				case .EXPOSED: {
					log.debug("SDL_EXPOSED")
				}
			}
		}
	}
	return should_quit
}

/********************
 * Game API and Lib *
 ********************/

LIB_NAME :: "game.dll"
LIB_LOCK_NAME :: "lock.tmp"

load_game_library :: proc(api_version:int) -> c.GameAPI {
	lib_write_time, lwt_err := os.last_write_time_by_name(LIB_NAME)
	if lwt_err != nil {
		panic("Couldn't get last write time of file")
	}

	copy_err := os2.copy_file(fmt.tprintf("game_{0}.dll", api_version), LIB_NAME)
	assert(copy_err == nil)

	lib, lib_ok := dynlib.load_library(fmt.tprintf("game_{0}.dll", api_version))
	if !lib_ok do panic("dynload fail")

	api := c.GameAPI {
		update = cast(c.GameUpdateFn)(dynlib.symbol_address(lib, "game_update")),
		init = cast(c.GameInitFn)(dynlib.symbol_address(lib, "game_state_init")),
		destroy = cast(c.GameDestroyFn)(dynlib.symbol_address(lib, "game_state_destroy")),
		lib = lib,
		write_time = lib_write_time,
	}

	return api
}

main :: proc() {
	/****************
	 * DEBUG logger *
	 ****************/

	context.logger = log.create_console_logger()
	context.logger.lowest_level = .Warning
	defer log.destroy_console_logger(context.logger)

	when ODIN_DEBUG {
		context.logger.lowest_level = .Debug
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		context.allocator = mem.tracking_allocator(&track)

		defer {
			if len(track.allocation_map) > 0 {
				for _, entry in track.allocation_map {
					fmt.eprintf("%v leaked %v bytes\n", entry.location, entry.size)
				}
			}
			if len(track.bad_free_array) > 0 {
				for entry in track.bad_free_array {
					fmt.eprintf("%v bad free at %v\n", entry.location, entry.memory)
				}
			}
			mem.tracking_allocator_destroy(&track)
		}
	}

	/*************
	 * SDL Setup *
	 *************/

	SDL.SetHint(SDL.HINT_WINDOWS_DISABLE_THREAD_NAMING, "1")
	if SDL.Init(SDL.InitFlags{.VIDEO}) < 0 do panic("Could not initialize window")

	sdl_resize_window(1177, 736)
	sdl_load_spritesheet()

	{
		r := SDL.GetRenderer(WIN)
		if r == nil {
			r = SDL.CreateRenderer(WIN, -1, {})
			if r == nil do panic("couldn't create renderer")
		}
		width, height : i32
		SDL.GetRendererOutputSize(r, &width, &height)
		sdl_create_textures(r, int(width), int(height))
	}

	setup_keymap()
	defer delete(SDL_KEYMAP)

	/******************
	 * Game API Setup *
	 ******************/

	api_version := 0
	game_api := load_game_library(api_version)
	platform_api := c.PlatformAPI{
		plot_tile = set_tile
	}
	game_memory := game_api.init(platform_api)
	lib_reload_timer := 0
	defer game_api.destroy(game_memory)
	defer dynlib.unload_library(game_api.lib)

	/*************
	 * Game Loop *
	 *************/

	running := true
	game_update_hz :f32= 60.0
	target_seconds_per_frame := 1.0 / game_update_hz
	last_counter := SDL.GetPerformanceCounter()

	for x in 0..<COLS {
		for y in 0..<ROWS {
			TILES[x][y].bg = {0,0,0,1}
			TILES[x][y].fg = {1,1,1,1}
		}
	}

	for running {
		if lib_reload_timer > 2*60 && !os.is_file(LIB_LOCK_NAME) {
			new_lib_write_time, err := os.last_write_time_by_name(LIB_NAME)
			if err != nil {
				panic("Couldn't get new write time")
			}
			if new_lib_write_time > game_api.write_time {
				api_version += 1
				log.debug("Loading API version", api_version)
				game_api = load_game_library(api_version)
			}
			lib_reload_timer = 0
		}
		lib_reload_timer += 1

		event : SDL.Event
		for SDL.PollEvent(&event) {
			running = !sdl_handle_event(event)
		}

		game_api.update(target_seconds_per_frame, game_memory, GAME_INPUT)

		for &btn in GAME_INPUT.keyboard {
			if btn.is_down && btn.was_down {
				btn.repeat += target_seconds_per_frame
			} else if !btn.is_down && btn.was_down {
				btn.repeat = 0
			}
			btn.was_down = btn.is_down
		}

		sdl_render()
		if sdl_get_seconds_elapsed(last_counter, SDL.GetPerformanceCounter()) < target_seconds_per_frame
		{
			time_to_sleep := u32((target_seconds_per_frame - sdl_get_seconds_elapsed(last_counter, SDL.GetPerformanceCounter())) * 1000) - 1
			SDL.Delay(time_to_sleep)
			for (sdl_get_seconds_elapsed(last_counter, SDL.GetPerformanceCounter()) < target_seconds_per_frame)
			{
				// Waiting...
			}
		}
		last_counter = SDL.GetPerformanceCounter()
	}

	/**********
	 * Render *
	 **********/

	SDL.Quit()
}
