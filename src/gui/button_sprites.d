module gui.button_sprites;

import geometry.all;
import graphics.all;

void drawButtonSprite(string button, Vector2i pos) {
  assert(button in _sprites, "no button sprite named " ~ button);
  _sprites[button].draw(pos);
}

private static Sprite[string] _sprites;

static this() {
  _sprites["a"]     = new Sprite("button_a");
  _sprites["b"]     = new Sprite("button_b");
  _sprites["x"]     = new Sprite("button_x");
  _sprites["y"]     = new Sprite("button_y");
  _sprites["lb"]    = new Sprite("button_lb");
  _sprites["rb"]    = new Sprite("button_rb");
  _sprites["lt"]    = new Sprite("button_lt");
  _sprites["rt"]    = new Sprite("button_rt");
  _sprites["start"] = new Sprite("button_start");
  _sprites["back"]  = new Sprite("button_back");
}
