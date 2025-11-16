package platform

import "vendor:sdl2/image"
import SDL "vendor:sdl2"

PNG_WIDTH :: 2048
PNG_HEIGHT :: 5568
PNG_TILE_HEIGHT :: 232
PNG_TILE_WIDTH :: 128
PNG_TILE_COLS :: 16
PNG_TILE_ROWS :: 24

PNG : ^SDL.Surface
PNG_TILE_PADDING  : [PNG_TILE_COLS][PNG_TILE_ROWS]int
PNG_TILE_IS_EMPTY : [PNG_TILE_COLS][PNG_TILE_ROWS]bool


/*
Returns the numbers of black lines at the top and bottom of a given glyph in the source PNG.

For example, if the glyph has 30 black lines at the top and 40 at the bottom, the function
returns 30 (the least of the two).

In case the glyph is very small, the function never returns more than TILE_HEIGHT / 4.
This is to avoid drawing the glyph more than twice its size relative to other glyphs
when the window's aspect ratio is very large (super wide).
*/
get_padding :: proc(row,column:int) -> int {
	padding : int
	// each pixel is encoded as 0xffRRGGBB, so we can tell if it's filled
	// with a bitand
	pixels := cast([^]u32)PNG.pixels
	for padding = 0; padding < PNG_TILE_WIDTH/4; padding += 1 {
		for x in 0..<PNG_TILE_WIDTH {
			top_y := padding
			bottom_y := PNG_TILE_HEIGHT - padding - 1

			if pixels[(x+column*PNG_TILE_WIDTH) + (top_y+row*PNG_TILE_HEIGHT)*PNG_WIDTH] & 0xffffff != 0 ||
				pixels[(x+column*PNG_TILE_WIDTH) + (bottom_y+row*PNG_TILE_HEIGHT)*PNG_WIDTH] & 0xffffff != 0 {
					return padding
			}
		}
	}
	return padding
}

is_empty :: proc(row,column:int) -> bool
{
	pixels := cast([^]u32)PNG.pixels
	for x in 0..<PNG_TILE_WIDTH {
		for y in 0..<PNG_TILE_HEIGHT {
			idx := (x + column * PNG_TILE_WIDTH) + (y + row * PNG_TILE_HEIGHT) * PNG_WIDTH
			if pixels[idx] & 0xffffff != 0 do return false
		}
	}

	return true
}

sdl_load_spritesheet :: proc() {
	image := image.Load("assets/tiles.png")
	if image == nil do panic("image load fail")
	defer SDL.FreeSurface(image)

	pfmt := SDL.PixelFormatEnum.ARGB8888
	PNG = SDL.ConvertSurfaceFormat(image, u32(pfmt), 0)
	if PNG == nil do panic("image convert fail")

	// measure padding
	for x in 0..<PNG_TILE_COLS {
		for y in 0..<PNG_TILE_ROWS {
			PNG_TILE_PADDING[x][y] = get_padding(x, y)
			PNG_TILE_IS_EMPTY[x][y] = is_empty(x, y)
		}
	}

	// Convert greyscale image intensity to alpha
	p_count := PNG.w * PNG.h
	pixels := cast([^]u32)PNG.pixels
	for i in 0..<p_count {
		r,g,b,a : u8
		SDL.GetRGBA(pixels[i], PNG.format, &r,&g,&b,&a)
		a=r
		r=255
		g=255
		b=255
		pixels[i] = SDL.MapRGBA(PNG.format, r,g,b,a)
	}
}
