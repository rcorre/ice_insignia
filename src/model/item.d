module model.item;

import std.regex;
import std.string : toLower;
import std.algorithm : max;
import allegro;
import util.jsonizer;
import geometry.vector;
import graphics.sprite;

private enum resalePriceFactor = 0.5;

Item loadItem(string name, int uses = -1) {
  name = toLower(name);
  return new Item(name, uses);
}

enum ItemType {
  none,
  sword,
  axe,
  lance,
  bow,
  anima,
  light,
  dark,
  staff,
  other
}

class Item {
  const ItemData data;
  alias data this;

  mixin JsonizeMe;

  @jsonize this(string name, int uses = -1) {
    name = name.toLower;
    assert(name in _itemData, "could not load item named " ~ name);
    data = _itemData[name];
    this.uses = (uses == -1) ? data.maxUses : uses;
    _sprite = new Sprite(data.name);
  }

  @jsonize { // json output
    int uses;
    @property string name() { return data.name; }
  }

  @property {
    auto sprite() { return _sprite; }
    static Item none() { return new Item("none", 0); }
    bool isWeapon() { with(ItemType) { return type != none && type != staff && type != other; } }
    int resalePrice() {
      return cast(int) (price * resalePriceFactor * cast(float) uses / maxUses);
    }
  }

  private:
  Sprite _sprite;
}

class ItemData {
  mixin JsonizeMe;

  @jsonize {
    string name;
    ItemType type;
    int maxUses;
    int damage;
    int hit;
    int crit;
    int minRange;
    int maxRange;
    int weight;
    int tier;
    int price;
  }
}

private ItemData[string] _itemData;

static this() {
  _itemData = readJSON!(ItemData[string])(Paths.itemData);
  _itemData["none"] = new ItemData; // empty placeholder item
  _itemData["none"].name = "none";
}
