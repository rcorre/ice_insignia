module gui.item_notification;

import geometry.all;
import graphics.all;
import model.item;

// pixels between text and item sprite
private enum {
  spriteSpacing = 10,
  textPrefix = "Got a",
  bgColor = Color(0.7, 0.7, 0.7, 0.7),
  fontName = "itemNotification"
}

class ItemNotification {
  this(Vector2i center, Item item) {
    _sprite = item.sprite;
    _itemName = item.name;
    auto prefixWidth = _font.widthOf(textPrefix);
    auto suffixWidth = _font.widthOf(_itemName);
    int width = prefixWidth + spriteSpacing + _sprite.width + suffixWidth;
    int height = _sprite.height;
    _area = Rect2i.CenteredAt(center, width, height);
    _spritePos = _area.topLeft + Vector2i(prefixWidth + spriteSpacing + _sprite.width / 2, _sprite.height / 2);
    int textY = (_sprite.height - _font.heightOf(textPrefix)) / 2;
    _prefixPos = _area.topLeft + Vector2i(0, textY);
    _namePos = _area.topLeft + Vector2i(_sprite.width + prefixWidth + spriteSpacing, textY);
  }

  void draw() {
    _area.drawFilled(bgColor);
    _font.draw(textPrefix, _prefixPos);
    _sprite.draw(_spritePos);
    _font.draw(_itemName, _namePos);
  }

  private:
  Sprite _sprite;
  Rect2i _area;
  Vector2i _spritePos, _namePos, _prefixPos;
  string _itemName;
}

private static Font _font;

static this() {
  _font = getFont("itemNotification");
}
