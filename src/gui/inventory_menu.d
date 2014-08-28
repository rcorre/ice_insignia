module gui.inventory_menu;

import std.array : array;
import std.algorithm : filter, max;
import graphics.all;
import geometry.all;
import gui.selection_menu;
import gui.item_view;
import model.item;

private enum {
  infoOffset = Vector2i(220, 0),
}

class InventoryMenu : SelectionMenu!Item {
  this(Vector2i pos, Item[] items, Action onChoose, HoverAction onHover = null) {
    super(pos, items, onChoose, onHover);
  }

  protected override {
    void drawEntry(Item item, Rect2i rect, bool isSelected) {
      if (isSelected) {
        rect.drawFilled(Color.white, 5, 5);
      }
      else {
        rect.drawFilled(Color.gray, 5, 5);
      }
      if (item) {
        Vector2i size = item.sprite.size;
        item.draw(rect.topLeft + size / 2);
        _font.draw(item.name, rect.topLeft + Vector2i(size.x, 0));
      }
    }

    int entryWidth(Item entry) {
      return entry ? entry.sprite.width + _font.widthOf(entry.name) : 0;
    }

    int entryHeight(Item entry) {
      return entry ? max(entry.sprite.height, _font.heightOf(entry.name)) : 0;
    }
  }
}
