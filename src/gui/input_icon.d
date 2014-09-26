module gui.input_icon;

import geometry.all;
import graphics.all;
import util.all;

private enum {
  // text rect roundness
  rx = 1,
  ry = 1,
  offsetX = 5
}

void drawInputIcon(string action, Vector2i pos, bool gamepad, string cmd = null, float scale = 1f) {
  if (!userPreferences.showInputIcons) { return; }
  Sprite sprite;
  if (gamepad) {
    assert(action in _sprites360, "no gamepad sprite named " ~ action);
    sprite = _sprites360[action];
  }
  else {
    assert(action in _spritesKbd, "no keyboard sprite named " ~ action);
    sprite = _spritesKbd[action];
  }
  if (cmd) {
    auto width = _font.widthOf(cmd);
    auto height = _font.heightOf(cmd);
    auto area = Rect2i(pos.x + sprite.width / 2 - offsetX, pos.y - height / 2, width, height);
    area.drawFilled(Color.black, 1, 1);
    auto textPos = area.topLeft;
    _font.draw(cmd, textPos, Color.white);
  }
  sprite.draw(pos, scale);
}

auto inputIconSize() { return Vector2i(32, 32); }

private static Sprite[string] _sprites360, _spritesKbd;
private static Font _font;

static this() {
  _sprites360 = [
    "confirm"  : new Sprite("button_a"),
    "cancel"   : new Sprite("button_b"),
    "inspect"  : new Sprite("button_y"),
    "previous" : new Sprite("button_lb"),
    "next"     : new Sprite("button_rb"),
    "start"    : new Sprite("button_start"),
  ];

  _spritesKbd = [
    "confirm"  : new Sprite("keyboard_j"),
    "cancel"   : new Sprite("keyboard_k"),
    "inspect"  : new Sprite("keyboard_f"),
    "previous" : new Sprite("keyboard_q"),
    "next"     : new Sprite("keyboard_e"),
    "start"    : new Sprite("keyboard_enter"),
  ];

  _font = getFont("buttonSprite");
}
