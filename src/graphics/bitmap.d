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
