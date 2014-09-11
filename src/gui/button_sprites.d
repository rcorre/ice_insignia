module gui.button_sprites;

import geometry.all;
import graphics.all;

private enum {
  // text rect roundness
  rx = 1,
  ry = 1,
  offsetX = 5
}

void drawButtonSprite(string button, Vector2i pos, string cmd = null) {
  assert(button in _sprites, "no button sprite named " ~ button);
  auto sprite = _sprites[button];
  if (cmd) {
    auto width = _font.widthOf(cmd);
    auto height = _font.heightOf(cmd);
    auto area = Rect2i(pos.x + sprite.width / 2 - offsetX, pos.y - height / 2, width, height);
    area.drawFilled(Color.black, 1, 1);
    auto textPos = area.topLeft;
    _font.draw(cmd, textPos, Color.white);
  }
  sprite.draw(pos);
}

private static Sprite[string] _sprites;
private static Font _font;

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

  _font = getFont("buttonSprite");
}
