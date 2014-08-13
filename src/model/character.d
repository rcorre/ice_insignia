module model.character;

import std.conv;
import std.string : format;
import util.jsonizer;
import model.item;
import model.weapon;
import model.valueset;

enum Attribute {
  maxHp,
  strength,
  skill,
  speed,
  defense,
  resist,
  luck,
  move,
  constitution
}

class Character {
  mixin JsonizeMe;

  enum itemCapacity = 5;

  Item itemAt(int slot) {
    assert(slot >= 0 && slot < itemCapacity, format("item #%d/%d out of range", slot, itemCapacity));
    return _items[slot];
  }

  /// access an attribute by name
  int opDispatch(string m)() const if (hasMember!(Attribute, m)) {
    return _attributes.opDispatch!m;
  }

  @property {
    ValueSet!Attribute potential() { return _potential; }
    ValueSet!Attribute attributes() { return _attributes; }
  }

  private:
  int _hp;
  @jsonize {
    string _name;
    ValueSet!Attribute _attributes;
    ValueSet!Attribute _potential;
    Item[itemCapacity] _items;
  }
}

unittest {
  import std.json : parseJSON;

  auto json = parseJSON(`{
      "_name" : "Myron",
      "_attributes" : {
      "valueSet" : {
      "maxHp"        : 20,
      "strength"     : 5,
      "skill"        : 4,
      "speed"        : 5,
      "defense"      : 5,
      "resist"       : 3,
      "luck"         : 2,
      "move"         : 4,
      "constitution" : 5
      }
      },
      "_potential" : {
      "valueSet" : {
      "maxHp"        : 10,
      "strength"     : 10,
      "skill"        : 10,
      "speed"        : 10,
      "defense"      : 10,
      "resist"       : 10,
      "luck"         : 10,
      "move"         : 0,
      "constitution" : 0
      }
      }
  }`);

  auto myron = json.extract!Character;
  assert(myron.maxHp == 20 && myron.move == 4 && myron.defense == 5);
}
