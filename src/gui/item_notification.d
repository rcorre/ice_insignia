module gui.item_notification;

import geometry.all;
import graphics.all;
import model.item;

// pixels between text and item sprite
private enum {
  spriteSpacing = 10,
  text = "Got a ",
  bgColor = Color(0.7, 0.7, 0.7, 0.7),
  fontName = "itemNotification"
}

class ItemNotification {
  this(Vector2i center, Item item) {
    _sprite = item.sprite;
    _textWidth = _font.widthOf(text);
    int width = _textWidth + spriteSpacing + _sprite.width;
    int height = _sprite.height;
    _area = Rect2i.CenteredAt(center, width, height);
    _spritePos = _area.topLeft + Vector2i(_textWidth + spriteSpacing, _sprite.height / 2);
  }

  void draw() {
    _area.drawFilled(bgColor);
    _font.draw(text, _area.topLeft);
    _sprite.draw(_spritePos);
  }

  private:
  Sprite _sprite;
  Rect2i _area;
  Vector2i _spritePos;
  int _textWidth;
}

private static Font _font;

static this() {
  _font = getFont("itemNotification");
}
