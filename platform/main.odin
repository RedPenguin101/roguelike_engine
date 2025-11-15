package platform

import "core:fmt"
import "core:log"
import "core:mem"

import SDL "vendor:sdl2"

import c "../common"

/* DBG :: log.debug */

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

TILES : [c.ROWS][c.COLS]PlatformTile
WIN : ^SDL.Window

INIT_WIDTH :: 800
INIT_HEIGHT :: 640

/*****************
 * SDL Functions *
 *****************/

/* sdl_resize_window :: proc(width, height:i32) */
/* { */
/* 	if (WIN==nil) { */
/* 		flags := SDL.WindowFlags{ .RESIZABLE, .ALLOW_HIGHDPI, } */
/* 		WIN = SDL.CreateWindow("MY_ROGUELIKE", */
/* 							   SDL.WINDOWPOS_CENTERED, SDL.WINDOWPOS_CENTERED, */
/* 							   width, height, */
/* 							   flags) */
/* 		assert(WIN!=nil) */
/* 		// TODO: Set Icon */
/* 	} */
/* } */

main :: proc() {
	fmt.println("Hello, world")
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
	SDL.Init(SDL.InitFlags{.VIDEO})
	/* sdl_resize_window(INIT_WIDTH, INIT_HEIGHT) */

	/******************
	 * Game API Setup *
	 ******************/

	LIB_NAME :: "game.dll"
	LIB_LOCK_NAME :: "lock.tmp"

	/*************
	 * Game Loop *
	 *************/

	/* for true { */
		
	/* } */

	/**********
	 * Render *
	 **********/

	/* SDL.Quit() */
	fmt.println("Fin")
}
