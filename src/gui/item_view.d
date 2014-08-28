module gui.item_view;

import geometry.all;
import model.item;

private enum {
  nameOffset = Vector2i(-20, -20);
}

/// display info about an item
class ItemView {
  this(Item item, Vector2i pos) {
  }

  void draw() {
  }

  private:
  Item _item;
  Vector2i _pos;
}
