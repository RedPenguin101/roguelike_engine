package platform

import "core:fmt"
import "core:log"
import "core:mem"
import "core:strings"

import SDL "vendor:sdl2"
import IMG "vendor:sdl2/image"

import c "../common"

Color :: c.Color
DisplayGlyph :: c.DisplayGlyph

PlatformTile :: struct {
	fg,bg : Color,
	glyph : DisplayGlyph,
	needs_update : bool,
}

/***********
 * GLOBALS *
 ***********/

SPRITESHEET : ^SDL.Surface

TILES : [c.COLS][c.ROWS]PlatformTile
WIN : ^SDL.Window

TEXTURE : ^SDL.Texture

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
		.A=65, .B=66, .C=67, .D=68, .E=69, .F=70, .G=71, .H=72, .I=73, .J=74, .K=75, .L=76, .M=77, .N=78, .O=79, .P=80, .Q=81, .R=82, .S=83, .T=84, .U=85, .V=86, .W=87, .X=88, .Y=89, .Z=90}

/*****************
 * SDL Functions *
 *****************/

sdl_load_spritesheet :: proc() {
	img_loc := "assets/tiles.png"
	img_loc_c := strings.clone_to_cstring(img_loc, context.temp_allocator)

	image := IMG.Load(img_loc_c)
	if image == nil do panic("image load fail")
	defer SDL.FreeSurface(image)

	pfmt := SDL.PixelFormatEnum.ARGB8888
	SPRITESHEET = SDL.ConvertSurfaceFormat(image, u32(pfmt), 0)
	if SPRITESHEET == nil do panic("image convert fail")
}

TEMP_FIRST_PASS := true

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

	tw := f32(width) / c.COLS
	th := f32(height) / c.ROWS

	for y in 0..<c.ROWS {
		for x in 0..<c.COLS {
			dest : SDL.Rect
			dest.x = i32(f32(x)*tw)
			dest.y = i32(f32(y)*th)
			dest.w = i32(tw)
			dest.h = i32(th)

			/* red   := u8(255 * (f32(y) / c.ROWS)) */
			/* if y % 2 == 0 do red = 255-red */

			/* green := u8(255 * (f32(x) / c.COLS)) */
			/* if x % 2 == 0 do green = 255-green */

			/* SDL.SetRenderDrawColor(renderer, red, green, 0, 255) */
			/* SDL.RenderFillRect(renderer, &dest) */

			tile := TILES[x][y]
			if tile.glyph != .NULL {
				SH :: 232
				SW :: 128
				TPR :: 16

				idx := GLYPH_LOOKUP[tile.glyph]
				src : SDL.Rect
				src.w = SW
				src.h = SH
				src.x = SW * i32(idx%TPR)
				src.y = SH * i32(idx/TPR)

				SDL.RenderCopy(renderer, TEXTURE, &src, &dest)
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

sdl_handle_event :: proc(event:SDL.Event) -> bool {
	should_quit := false
	#partial switch event.type {
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

main :: proc() {
	fmt.println("Hello, world")
	fmt.println("cols", c.COLS, "rows", c.ROWS)
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

	// div 2 because of high DPI
	sdl_resize_window(1177, 736)
	sdl_load_spritesheet()

	{
		r := SDL.GetRenderer(WIN)
		if r == nil {
			r = SDL.CreateRenderer(WIN, -1, {})
			if r == nil do panic("couldn't create renderer")
		}
		TEXTURE = SDL.CreateTextureFromSurface(r, SPRITESHEET)

	}

	/******************
	 * Game API Setup *
	 ******************/

	LIB_NAME :: "game.dll"
	LIB_LOCK_NAME :: "lock.tmp"

	/*************
	 * Game Loop *
	 *************/

	TILES[0][0].glyph = .H
	TILES[1][0].glyph = .E
	TILES[2][0].glyph = .L
	TILES[3][0].glyph = .L
	TILES[4][0].glyph = .O
	TILES[6][0].glyph = .W
	TILES[7][0].glyph = .O
	TILES[8][0].glyph = .R
	TILES[9][0].glyph = .L
	TILES[10][0].glyph = .D

	TILES[0][1].glyph = .N_1
	TILES[1][1].glyph = .N_2
	TILES[2][1].glyph = .N_3
	TILES[3][1].glyph = .N_4
	TILES[4][1].glyph = .N_5
	TILES[5][1].glyph = .N_6
	TILES[6][1].glyph = .N_7
	TILES[7][1].glyph = .N_8
	TILES[8][1].glyph = .N_9
	TILES[9][1].glyph = .N_0
	TILES[c.COLS/2][c.ROWS/2].glyph = .AT

	for {
		event : SDL.Event
		SDL.WaitEvent(&event)
		should_quit := sdl_handle_event(event)
		if should_quit do break
		sdl_render()
	}

	/**********
	 * Render *
	 **********/

	SDL.Quit()
	fmt.println("Fin")
}
