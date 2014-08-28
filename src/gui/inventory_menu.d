module gui.inventory_menu;

import std.array : array;
import std.algorithm : filter, max;
import graphics.all;
import geometry.all;
import gui.selection_menu;
import gui.item_view;
import model.item;

private enum {
  fontName = "selection_font",
  spacingY = 5
}

class InventoryMenu : SelectionMenu!Item {
  this(Vector2i pos, Item[] items, Action onChoose) {
    super(pos, items, onChoose, &showItemInfo);
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
      if (_itemView) {
        _itemView.draw();
      }
    }

    int entryWidth(Item entry) {
      return entry ? entry.sprite.width + _font.widthOf(entry.name) : 0;
    }

    int entryHeight(Item entry) {
      return entry ? max(entry.sprite.height, _font.heightOf(entry.name)) : 0;
    }
  }

  private:
  ItemView _itemView;

  void showItemInfo(Item item) {
    _itemView = new ItemView(item, Vector2i(160, 160));
  }
}
