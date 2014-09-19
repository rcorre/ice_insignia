module gui.item_notification;

import geometry.all;
import graphics.all;
import model.item;

// pixels between text and item sprite
private enum {
  spriteSpacing = 10,
  bgColor = Color(0.7, 0.7, 0.7, 0.7),
  fontName = "itemNotification"
}

class ItemNotification {
  this(Vector2i center, Item item, string text) {
    _sprite = item.sprite;
    _text = item.name ~ " " ~ text;
    auto textWidth = _font.widthOf(_text);
    int width = _sprite.width + spriteSpacing + textWidth;
    int height = _sprite.height;
    _area = Rect2i.CenteredAt(center, width, height);
    _spritePos = _area.topLeft + _sprite.size / 2;
    int textY = (_sprite.height - _font.heightOf(_text)) / 2;
    _textPos = _area.topLeft + Vector2i(_sprite.width + spriteSpacing, textY);
  }

  void draw() {
    _area.drawFilled(bgColor);
    _sprite.draw(_spritePos);
    _font.draw(_text, _textPos);
  }

  private:
  Sprite _sprite;
  Rect2i _area;
  Vector2i _spritePos, _textPos;
  string _text;
}

private static Font _font;

static this() {
  _font = getFont("itemNotification");
}
