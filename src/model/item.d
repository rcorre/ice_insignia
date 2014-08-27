module model.item;

import std.algorithm : max;
import allegro;
import util.jsonizer;

Item loadItem(string name) {
  assert(name in _itemData, "could not load item named " ~ name);
  return _itemData[name];
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
  mixin JsonizeMe;

  @property {
    string name() { return _name; }
    int uses()    { return _uses; }
    int damage()  { return _damage; }
    int hit()     { return _hit; }
    int crit()    { return _crit; }
    int weight()  { return _weight; }
    ItemType type()    { return _type; }

    int minRange() { return _minRange; }
    int maxRange() { return max(_minRange, _maxRange); }

    bool isWeapon() {
     with(ItemType) {
       return _type == sword || _type == axe || _type == lance || _type == bow ||
         _type == anima || _type == light || _type == dark;
     }
    }
  }

  static Item none() {
    return new Item;
  }

  private:
  @jsonize {
    string _name;
    ItemType _type;

    int _uses;
    int _damage;
    int _hit;
    int _crit;
    int _minRange = 0;
    int _maxRange = 0;
    int _weight;
  }
}

private Item[string] _itemData;

static this() {
  _itemData = readJSON!(Item[string])(Paths.itemData);
}
