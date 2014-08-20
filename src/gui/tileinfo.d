module gui.tileinfo;

import std.string : format;
import geometry.all;
import graphics.all;

class TileInfoBox {
  this(Vector2i pos, string name, int defense, int avoid) {
    _pos = pos;
    _textLines = [
      name,
      format("Defense: %d", defense),
      format("Avoid: %d", avoid)
    ];
  }

  void draw() {
    _bgSprite.draw(_pos);
    _font.draw(_textLines, _pos + textOffset);
  }

  private:
  Vector2i _pos;
  string[3] _textLines;

  static {
    Sprite _bgSprite;
    Font _font;
  }

  enum {
    bgSpriteName = "tile_info_box",
    fontName = "tileInfoFont",
    textOffset = Vector2i(-40, -20),
  }

  static this() {
    _bgSprite = new Sprite(bgSpriteName);
    _font = getFont(fontName);
  }
}
