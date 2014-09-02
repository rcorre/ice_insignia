module gui.inventory_menu;

import std.string : format;
import std.array : array;
import std.algorithm : filter, max;
import graphics.all;
import geometry.all;
import gui.selection_menu;
import model.item;

private enum {
  defaultWidth = 120,
  defaultHeight = 32
}

class InventoryMenu : SelectionMenu!Item {
  enum ShowPrice { no, full, resale }
  this(Vector2i pos, Item[] items, Action onChoose, HoverAction onHover = null,
      ShowPrice showPrice = ShowPrice.no)
  {
    _showPrice = showPrice;
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
        item.sprite.draw(rect.topLeft + size / 2);
        _font.draw(itemText(item), rect.topLeft + Vector2i(size.x, 0));
      }
    }

    int entryWidth(Item entry) {
      return entry ? entry.sprite.width + _font.widthOf(itemText(entry)) : defaultWidth;
    }

    int entryHeight(Item entry) {
      return entry ? max(entry.sprite.height, _font.heightOf(itemText(entry))) : defaultHeight;
    }
  }

  string itemText(Item item) {
    if (item is null) { return ""; }
    final switch (_showPrice) { // choose how to display item text
      case ShowPrice.no:
        return format("%12s (%d)", item.name, item.uses);
      case ShowPrice.full:
        return format("%12s (%d)  %4dG", item.name, item.uses, item.price);
      case ShowPrice.resale:
        return format("%12s (%d)  %4dG", item.name, item.uses, item.resalePrice);
    }
  }

  private:
  ShowPrice _showPrice;
}
