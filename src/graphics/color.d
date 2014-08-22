module graphics.color;

import allegro;
import util.math;

/// common colors
enum Tint {
  white = color(1, 1, 1, 1),
  black = color(0, 0, 0, 1),
  red   = color(1, 0, 0, 1),
  green = color(0, 1, 0, 1),
  blue  = color(0, 0, 1, 1),
}

/// shortcut to create colors from float values
ALLEGRO_COLOR color(float r, float g, float b, float a = 1.0f) {
  return ALLEGRO_COLOR(r, g, b, a);
}

/// shortcut to create colors from unsigned byte values
ALLEGRO_COLOR ucolor(ubyte r, ubyte g, ubyte b, ubyte a = 255u) {
  return ALLEGRO_COLOR(r / 255f, g / 255f, b / 255f, a / 255f);
}

ALLEGRO_COLOR lerp(ALLEGRO_COLOR start, ALLEGRO_COLOR end, float factor) {
  auto r = util.math.lerp(start.r, end.r, factor);
  auto g = util.math.lerp(start.g, end.g, factor);
  auto b = util.math.lerp(start.b, end.b, factor);
  auto a = util.math.lerp(start.a, end.a, factor);
  return color(r, g, b, a);
}

ALLEGRO_COLOR lerp(ALLEGRO_COLOR[] colors, float factor) {
  assert(colors.length > 2);
  float colorTime = 1.0 / (colors.length - 1); // time for each color pair
  int idx = roundDown(factor * (colors.length - 1));
  if (idx < 0) {  // before first color
    return colors[0];  // return first
  }
  else if (idx >= colors.length - 1) {  // past last color
    return colors[$ - 1];  // return last
  }
  factor = (factor % colorTime) / colorTime; 
  return lerp(colors[idx], colors[idx + 1], factor);
}

unittest {
  bool approxEqual(ALLEGRO_COLOR c1, ALLEGRO_COLOR c2) {
    import std.math : approxEqual;
    return c1.r.approxEqual(c2.r) &&
      c1.g.approxEqual(c2.g) &&
      c1.b.approxEqual(c2.b) &&
      c1.a.approxEqual(c2.a);
  }

  // float color with implied alpha
  auto c1 = color(0.5, 1, 0.3);
  assert(approxEqual(c1, ALLEGRO_COLOR(0.5, 1, 0.3, 1)));

  // float color with specified alpha
  auto c2 = color(0, 0, 0, 0.5);
  assert(approxEqual(c2, ALLEGRO_COLOR(0, 0, 0, 0.5)));

  // unsigned color with implied alpha
  auto c3 = ucolor(100, 255, 0);
  assert(approxEqual(c3, ALLEGRO_COLOR(100 / 255f, 1, 0, 1)));

  // unsigned color with specified alpha
  auto c4 = ucolor(0, 0, 255, 127);
  assert(approxEqual(c4, ALLEGRO_COLOR(0, 0, 1, 127 / 255f)));

  auto c5 = Tint.black.lerp(Tint.white, 0.5);
  assert(c5 == color(0.5, 0.5, 0.5, 1));

  assert(lerp([Tint.black, Tint.white, Tint.red], 0) == Tint.black);
  assert(lerp([Tint.black, Tint.white, Tint.red], 0.1) == color(0.2, 0.2, 0.2));
  assert(lerp([Tint.black, Tint.white, Tint.red], 0.5) == Tint.white);
  assert(approxEqual(lerp([Tint.black, Tint.white, Tint.red], 0.6), color(1, 0.8, 0.8)));
  assert(approxEqual(lerp([Tint.black, Tint.white, Tint.red], 1), Tint.red));
}
