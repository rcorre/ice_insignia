module model.character;

import std.conv;
import std.string : format;
import std.random : uniform;
import std.algorithm : max, min;
import allegro;
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

  enum {
    itemCapacity = 5,
    xpLimit = 100
  }

  @property {
    ValueSet!Attribute potential() { return _potential; }
    ValueSet!Attribute attributes() { return _attributes; }
    Weapon equippedWeapon() {
      return (typeid(_items[0]) == typeid(Weapon)) ? cast(Weapon) _items[0] : Weapon.none;
    }

    int avoid() { return _attributes.speed * 4; }

    // experience
    int xp() { return _xp; }
    void xp(int val) {
      if (_xp + val >= 100) {
        levelUp();
      }
      _xp = (_xp + val) % 100;
    }
  }

  Item itemAt(int slot) {
    assert(slot >= 0 && slot < itemCapacity, format("item #%d/%d out of range", slot, itemCapacity));
    return _items[slot];
  }

  /// access an attribute by name
  int opDispatch(string m)() const if (hasMember!(Attribute, m)) {
    return _attributes.opDispatch!m;
  }

  /// level up and return attribute increase values
  ValueSet!Attribute levelUp() {
    auto bonuses = _potential.map!(p => uniform(0, 10 + p) / 10);
    _attributes = attributes + bonuses;
    return bonuses;
  }

  private:
  @jsonize {
    string _name;
    int _xp;
    int _level;
    ValueSet!Attribute _attributes;
    ValueSet!Attribute _potential;
    Item[itemCapacity] _items;
  }
}

Character loadCharacter(string name) {
  assert(name in _characterData, "could not match character " ~ name);
  return _characterData[name];
}

private Character[string] _characterData;

static this() {
  _characterData = readJSON!(Character[string])(Paths.characterData);
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
        "strength"     : 2,
        "skill"        : 8,
        "speed"        : 5,
        "defense"      : 4,
        "resist"       : 5,
        "luck"         : 2,
        "move"         : 0,
        "constitution" : 1
      }
      }
  }`);

  auto myron = json.extract!Character;
  assert(myron.maxHp == 20 && myron.move == 4 && myron.defense == 5);
  assert(myron.potential.strength == 2 && myron.potential.constitution == 1);
}
