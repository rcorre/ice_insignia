module gui.inventory_menu;

import std.array : array;
import std.algorithm : filter, max;
import graphics.all;
import geometry.all;
import gui.selection_menu;
import model.item;

private enum {
  fontName = "selection_font",
  spacingY = 5
}

class InventoryMenu : SelectionMenu!Item {
  this(Vector2i pos, Item[] items, Action onChoose, Action onHover) {
    auto selections = array(items.filter!"a !is null");
    super(pos, selections, onChoose, onHover);
  }

  protected override :
  void drawEntry(Item item, Rect2i rect, bool isSelected) {
    if (item) {
      if (isSelected) {
        rect.drawFilled(Color.white, 5, 5);
      }
      Vector2i size = item.sprite.size;
      item.draw(rect.topLeft + size / 2);
      _font.draw(item.name, rect.topLeft + Vector2i(size.x, 0));
    }
  }

  int entryWidth(Item entry) {
    return entry.sprite.width + _font.widthOf(entry.name);
  }

  int entryHeight(Item entry) {
    return max(entry.sprite.height, _font.heightOf(entry.name));
  }
}
