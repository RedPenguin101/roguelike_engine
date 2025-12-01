package game

import "core:math"

abs :: math.abs

V2  :: [2]f32
V2i :: [2]int
V3i :: [3]int
TileRect :: [4]int

tile_rect_from_center_and_dim :: proc(center,dim:V2i) -> TileRect {
	min_v := center - (dim/2)
	max_v := min_v + dim
	return {
		min_v.x,
		min_v.y,
		max_v.x,
		max_v.y,
	}
}

in_rect :: proc(v:V2i,r:TileRect) -> bool {
    return v.x >= r.x && v.x < r.z && v.y >= r.y && v.y < r.w
}

/**************
 * Color Math *
 **************/

hsl_to_rgb :: proc(hsl:[3]f32) -> Color {
	hue        := hsl[0]
	saturation := hsl[1]
	lightness  := hsl[2]

	c := (1-abs(2*lightness-1)) * saturation
	m := lightness - c/2

	h_mod := hue / 60
	for h_mod > 2 do h_mod -= 2
	x := c * f32(1 - abs(h_mod-1))

	color : Color

	if hue < 60 {
		color = {c, x, 0, 1}
	} else if hue < 120 {
		color = {x, c, 0, 1}
	} else if hue < 180 {
		color = {0, c, x, 1}
	} else if hue < 240 {
		color = {0, x, c, 1}
	} else if hue < 300 {
		color = {x, 0, c, 1}
	} else if hue < 360 {
		color = {c, 0, x, 1}
	} else do panic("invalid h prime value")

	color += {m,m,m,0}
	return color
}

rbg_to_hsl :: proc(c:Color) -> [3]f32 {
	c_max := max(c.r, c.g, c.b)
	c_min := min(c.r, c.g, c.b)
	chroma := c_max - c_min
	lightness := (c_max+c_min)/2
	saturation : f32

	if lightness == 0 {
		saturation = 0
	} else if lightness <= 0.5 {
		saturation = chroma / (c_max+c_min)
	} else if lightness < 1{
		saturation = chroma / (2-c_max-c_min)
	} else {
		saturation = 0
	}

	hue : f32
	if chroma == 0 {
		hue = 0
	} else if c_max == c.r {
		hue = (c.g-c.b)/chroma
	} else if c_max == c.g {
		hue = (c.b-c.r)/chroma + 2
	} else {
		hue = (c.r-c.g)/chroma + 4
	}
	if hue < 0 do hue += 6
	hue /= 6
	assert(hue >= 0 && hue <= 1)
	hue *= 360

	return {hue, saturation, lightness}
}

change_lightness :: proc(c:Color, percent:f32) -> Color {
	hsl := rbg_to_hsl(c)
	hsl[2] = clamp(hsl[2]*percent, 0, 1)
	return hsl_to_rgb(hsl)
}
