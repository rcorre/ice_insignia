module gui.item_slot;

import std.string : format;
import gui.element;
import geometry.all;
import graphics.all;
import model.item;

private enum {
  slotSize = 36,
  borderThickness = 2,
  usesOffset = Vector2i(-16,0),
  usesColor = Color.blue
}

class ItemSlot : GUIElement {
  enum ShowPrice { no, full, resale }
  this(Vector2i pos, Item item, ShowPrice showCost = ShowPrice.no) {
    _item = item;
    super(pos, Anchor.center);
    if (item) {
      final switch (showCost) { // choose how to display item text
        case ShowPrice.no:
          _text = format("%12s (%d)", item.name, item.uses);
          break;
        case ShowPrice.full:
          _text = format("%12s (%d)  %4dG", item.name, item.uses, item.price);
          break;
        case ShowPrice.resale:
          _text = format("%12s (%d)  %4dG", item.name, item.uses, item.resalePrice);
          break;
      }
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
        _item.sprite.draw(bounds.center);
        _font.draw(_text, _namePos);
        _font.draw(_item.uses, bounds.center + usesOffset, usesColor);
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
