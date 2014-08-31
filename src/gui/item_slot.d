module gui.item_slot;

import std.string : format;
import gui.element;
import geometry.all;
import graphics.all;
import model.item;

private enum {
  int slotSize = 36,
  float borderThickness = 2,
}

class ItemSlot : GUIElement {
  this(Vector2i pos, Item item) {
    _item = item;
    super(pos, Anchor.center);
    if (item) {
      _text = format("%s (%d)", item.name, item.uses);
      _namePos = bounds.topRight + Vector2i.UnitY * _font.heightOf(_text) / 2;
    }
  }

  override {
    @property {
      int width() { return slotSize; }
      int height() { return slotSize; }
    }

    void handleSelect() {
    }

    void draw() {
      if (_item) {
        _item.draw(bounds.center);
        _font.draw(_text, _namePos);
      }
    }
  }

  private:
  Item _item;
  string _text;
  Vector2i _namePos;

  static Font _font;

  static this() {
    _font = getFont("itemSlot");
  }
}
