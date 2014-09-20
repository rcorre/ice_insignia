module model.item;

import std.regex;
import std.string : toLower;
import std.algorithm : max;
import allegro;
import util.jsonizer;
import geometry.vector;
import graphics.sprite;
import model.valueset;
import model.attribute;

private enum resalePriceFactor = 0.5;

enum ItemType {
  other,
  sword,
  axe,
  lance,
  bow,
  magic,
}

enum ItemEffect {
  none,
  drain,
  antiArmor,
  counter,
}

class Item {
  const ItemData data;
  alias data this;

  bool drop; // whether item is dropped when holder is defeated

  mixin JsonizeMe;

  @jsonize this(string key, bool drop = false, int uses = -1) {
    assert(key in _itemData, "could not load item named " ~ key);
    data = _itemData[key];
    this.uses = (uses == -1) ? data.maxUses : uses;
    _sprite = new Sprite(data.name);
    this.drop = drop;
  }

  @jsonize { // json output
    int uses;
    string key;
  }

  @property {
    auto sprite() { return _sprite; }
    static Item none() { return new Item("none", 0); }
    bool isWeapon() { with(ItemType) { return type != other && type != magic; } }
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
    string text;
    ItemType type = ItemType.other;
    int maxUses;
    int damage;
    int hit;
    int crit;
    int minRange;
    int maxRange;
    int weight;
    int tier = 1;
    int price;
    int heal;
    ItemEffect effect;
    bool useOnSelf;
    bool useOnAlly;
    AttributeSet statEffects;
  }
}

private ItemData[string] _itemData;

static this() {
  _itemData = readJSON!(ItemData[string])(Paths.itemData);
  _itemData["none"] = new ItemData; // empty placeholder item
  _itemData["none"].name = "none";
}
