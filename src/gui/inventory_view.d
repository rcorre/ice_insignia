module gui.inventory_view;

import graphics.all;
import geometry.all;
import gui.selection_view;
import model.item;

private enum {
  fontName = "selection_font",
  spacingY = 5
}

class InventoryView : SelectionView!Item {
  this(Vector2i pos, Item[] selections, Action onChoose, Action onHover) {
    super(pos, selections, onChoose, onHover);
  }

  protected:
  override void drawEntry(Item item, Rect2i rect, bool isSelected) {
    if (item) {
      if (isSelected) {
        rect.drawFilled(Color.white, 5, 5);
      }
      assert(item.sprite);
      Vector2i size = item.sprite.size;
      item.draw(rect.topLeft + size / 2);
      _font.draw(item.name, rect.topLeft + Vector2i(size.x, 0));
    }
  }
}
