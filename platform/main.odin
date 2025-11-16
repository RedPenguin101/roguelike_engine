package platform

import "core:fmt"
import "core:log"
import "core:mem"

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
	TILES[x][y].fg = bg
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

black := Color{0,0,0,1}
white := Color{1,1,1,1}
pink := Color{245.0/255, 66.0/355, 209.0/255, 1}
blue := Color{0, 0, 1, 1}

/*****************
 * SDL Functions *
 *****************/

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

	/*
	base_tile_width := int(max(1, output_width/COLS))
	base_tile_height := int(max(1, output_height/ROWS))

	for i in 0..<4 {
		if TEXTURE[i] != nil do SDL.DestroyTexture(TEXTURE[i])
	}

	SDL.SetHint(SDL.HINT_RENDER_SCALE_QUALITY, "nearest")

/*
- 0:   W   x   H
- 1: (W+1) x   H   pixels
- 2:   W   x (H+1) pixels
- 3: (W+1) x (H+1) pixels
*/
	for i in 0..<4 {
		width := base_tile_width
		if i == 1 || i == 3 do width+=1
		height := base_tile_height
		if i == 2 || i == 3 do height+=1

		// We make a surface to turn into the texture. The original
		// PNG is very big, so we need to downscale it to something
		// closer to the tiles in the texture. For mysterious SDL
		// compatibility reasons, we make the surface a multiple of 2

		surface_width := 1
		surface_height := 1
		for surface_width  < width*PNG_TILE_COLS  do surface_width *= 2
		for surface_height < height*PNG_TILE_ROWS do surface_height *= 2

		surface := SDL.CreateRGBSurfaceWithFormat(0, i32(surface_width), i32(surface_height), 32, u32(SDL.PixelFormatEnum.ARGB8888))
		defer SDL.FreeSurface(surface)

		for x in 0..<PNG_TILE_COLS {
			for y in 0..<PNG_TILE_COLS {
				
			}
		}
		
	}
    */

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

			if tile.bg != black {
				bg := color_to_sdl(tile.bg)
				SDL.SetRenderDrawColor(renderer, bg.r, bg.g, bg.b, bg.a)
				SDL.RenderFillRect(renderer, &dest)
			}

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

	/******************
	 * Game API Setup *
	 ******************/

	LIB_NAME :: "game.dll"
	LIB_LOCK_NAME :: "lock.tmp"

	/*************
	 * Game Loop *
	 *************/

	for x in 0..<COLS {
		for y in 0..<ROWS {
			TILES[x][y].bg = black
			TILES[x][y].fg = white
		}
	}

	TILES[0][0].glyph = .H
	TILES[0][0].bg = blue
	TILES[0][0].fg = pink
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
	TILES[COLS/2][ROWS/2].glyph = .AT
	TILES[COLS/2][ROWS/2].bg = blue
	TILES[COLS/2][ROWS/2].fg = white

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
}
