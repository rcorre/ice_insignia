module model.character;

import std.string : format;
import util.jsonizer;
import model.item;
import model.weapon;
import model.valueset;

class Character {
  enum itemCapacity = 5;
  enum Attribute {
    maxHp,
    strength,
    skill,
    speed,
    defense,
    resist,
    luck,
    constitution
  }

  Item itemAt(int slot) {
    assert(slot >= 0 && slot < itemCapacity, format("item #%d/%d out of range", slot, itemCapacity));
    return _items[slot];
  }

  /// access an attribute by name
  int opDispatch(string m)() const {
    return _attributes.opDispatch!m;
  }

  private:
  string _name;
  int _hp;
  ValueSet!Attribute _attributes;
  Item[5] _items;
}
