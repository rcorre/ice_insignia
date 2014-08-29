module model.item;

import std.algorithm : max;
import allegro;
import util.jsonizer;
import geometry.vector;
import graphics.sprite;

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
    @jsonize string name() { return _name; }
    int uses()    { return _uses; }
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

  void draw(Vector2i pos) {
    assert(_sprite);
    _sprite.draw(pos);
  }

  static Item none() {
    return new Item;
  }

  private:
  @jsonize {
    @property {
      void name(string name) {
        _name = name;
        _sprite = new Sprite(name);
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

private Item[string] _itemData;

static this() {
  _itemData = readJSON!(Item[string])(Paths.itemData);
}
