package platform

import "vendor:sdl2/image"
import SDL "vendor:sdl2"
import "core:math"

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
}

downscale_tile :: proc(source:^SDL.Surface, source_tile_width, source_tile_height: int,
					   dest:^SDL.Surface, dest_tile_width, dest_tile_height: int,
					   tile_row, tile_col: int)
{
	source_pixels := cast([^]u32)source.pixels
	dest_pixels   := cast([^]u32)dest.pixels

	col_mapping := make([]int, source_tile_width, context.temp_allocator)
	row_mapping := make([]int, source_tile_height, context.temp_allocator)

	for col in 0..<source_tile_width  do col_mapping[col] = (col*dest_tile_width)/source_tile_width
	for row in 0..<source_tile_height do row_mapping[row] = (row*dest_tile_height)/source_tile_height

	counter        := make([]u64, dest_tile_width*dest_tile_height, context.temp_allocator)
	sum_of_squares := make([]u64, dest_tile_width*dest_tile_height, context.temp_allocator)

	for acc_row, src_row in row_mapping {
		for acc_col, src_col in col_mapping {
			src_idx := (tile_col*source_tile_width)+(tile_row*source_tile_height+src_row)*PNG_WIDTH + src_col
			acc_idx := (acc_row*dest_tile_width)+acc_col

			intensity := u64(source_pixels[src_idx] & 0xff)
			counter[acc_idx]        += 1
			sum_of_squares[acc_idx] += intensity*intensity
		}
	}

	dest_width := int(dest.w)
	for row in 0..<dest_tile_height {
		for col in 0..<dest_tile_width {
			dst_idx := (tile_col*dest_tile_width) + (tile_row*dest_tile_height+row)*dest_width + col
			acc_idx := row*dest_tile_width + col

			count := counter[acc_idx]
			sos := sum_of_squares[acc_idx]
			avg := 0 if count == 0 else sos/count

			intensity := clamp(u32(math.round(math.sqrt(f64(avg)))), 0, 255)
			dest_pixels[dst_idx] = (intensity << 24) | 0xffffff
		}
	}
}
