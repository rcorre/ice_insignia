module model.item;

import util.jsonizer;
import graphics.sprite;
import graphics.font;
import geometry.all;

abstract class Item {
  mixin JsonizeMe;

  void draw(Vector2i pos) {
    _icon.draw(pos);
    // TODO: draw name and uses left
  }

  protected:
  Sprite _icon;
  @jsonize {
    string name;
    int maxUses;
    int usesLeft;
    @property {
      string iconName()            { return _icon.name; }
      void   iconName(string name) { _icon = new Sprite(name); }
    }
  }
}
