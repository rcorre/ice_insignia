module model.item;

import std.regex;
import std.string : toLower;
import std.algorithm : max;
import allegro;
import util.jsonizer;
import geometry.vector;
import graphics.sprite;

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
}

class Item {
  ItemData data;
  alias data this;

  mixin JsonizeMe;

  @jsonize this(string name, int uses = -1) {
    assert(name in _itemData, "could not load item named " ~ name);
    data = _itemData[name];
    this.uses = (uses == -1) ? data.maxUses : uses;
    _sprite = new Sprite(data.name);
  }

  @jsonize { // json output
    int uses;
    @property string name() { return data.name; }
  }

  void draw(Vector2i pos) {
    _sprite.draw(pos);
  }

  static @property Item none() { return new Item("none", 0); }

  private:
  Sprite _sprite;
}

class ItemData {
  mixin JsonizeMe;

  @property {
    @jsonize string name() { return _name; }
    int maxUses()    { return _uses; }
    int damage()  { return _damage; }
    int hit()     { return _hit; }
    int crit()    { return _crit; }
    int weight()  { return _weight; }
    ItemType type()    { return _type; }
    int tier() { return _tier; }

    int minRange() { return _minRange; }
    int maxRange() { return max(_minRange, _maxRange); }

    bool isWeapon() {
     with(ItemType) {
       return _type == sword || _type == axe || _type == lance || _type == bow ||
         _type == anima || _type == light || _type == dark;
     }
    }

    auto sprite() { return _sprite; }
  }

  private:
  @jsonize {
    @property {
      void name(string name) {
        _name = name;
      }
    }
    ItemType _type;

    int _uses;
    int _damage;
    int _hit;
    int _crit;
    int _minRange = 0;
    int _maxRange = 0;
    int _weight;
    int _tier;
  }
  Sprite _sprite;
  string _name;
}

private ItemData[string] _itemData;

static this() {
  _itemData = readJSON!(ItemData[string])(Paths.itemData);
  _itemData["none"] = new ItemData; // empty placeholder item
}
