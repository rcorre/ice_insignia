module state.bmp_test;

import std.range : iota;
import allegro;

class BMPTest : GameState {
  this() {
    bmp1 = al_load_bitmap("content/image/units2.png");
    bmp2 = paletteSwap!(blueToRed)(bmp1);
  }

  /// returns a GameState to request a state transition, null otherwise
  override GameState update(float time) {
    return null;
  }

  /// render game state to screen
  override void draw() {
    al_draw_bitmap(bmp1, 0, 0, 0);
    al_draw_bitmap(bmp2, 150, 150, 0);
  }

  override void onExit() {
  }

  private:
  ALLEGRO_BITMAP* bmp1, bmp2;

}

Color blueToRed(Color color) {
  if (isBluish(color)) {
    auto r = color.r;
    color.r = color.b;
    color.b = r;
  }
  return color;
}

bool isBluish(ALLEGRO_COLOR c) {
  return c.b > 0.5 && c.r < 0.5 && c.g < 0.5;
}

/// bitmap manipulation utility functions
module graphics.bitmap;

import std.range : iota;
import allegro;
import graphics.color;

alias Bitmap = ALLEGRO_BITMAP*;

/// produce a new bitmap resulting from calling func on each pixel of src
auto paletteSwap(alias func)(Bitmap src) {
  int w = al_get_bitmap_width(src);
  int h = al_get_bitmap_height(src);
  auto dst = al_create_bitmap(w, h);

  auto format = al_get_bitmap_format(src);
  auto display = al_get_target_bitmap();

  al_lock_bitmap(dst, format, ALLEGRO_LOCK_WRITEONLY);
  al_set_target_bitmap(dst);

  scope(exit) al_unlock_bitmap(dst);
  scope(exit) al_set_target_bitmap(display);

  foreach(x ; iota(0, w - 1)) {
    foreach(y ; iota(0, h - 1)) {
      auto color = func(Color(al_get_pixel(src, x, y)));
      al_put_pixel(x, y, color);
    }
  }

  return dst;
}
