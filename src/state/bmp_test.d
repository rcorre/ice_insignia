module state.bmp_test;

import std.range : iota;
import allegro;
import state.gamestate;
import gui.all;
import geometry.all;
import graphics.all;
import graphics.bitmap;
import util.input;

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
