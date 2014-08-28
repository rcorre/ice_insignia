module model.character;

import std.conv;
import std.string : format;
import std.random : uniform;
import std.range : empty;
import std.algorithm : max, min, countUntil;
import allegro;
import util.jsonizer;
import model.item;
import model.valueset;

enum Attribute {
  maxHp,
  strength,
  magic,
  skill,
  speed,
  luck,
  defense,
  resist,
  move,
  constitution
}

enum AttributeCaps = [
  Attribute.maxHp        : 100,
  Attribute.strength     : 25,
  Attribute.magic        : 25,
  Attribute.skill        : 25,
  Attribute.speed        : 25,
  Attribute.luck         : 25,
  Attribute.defense      : 25,
  Attribute.resist       : 25,
  Attribute.move         : 10,
  Attribute.constitution : 15,
];

class Character {
  mixin JsonizeMe;

  enum {
    itemCapacity = 5,
    xpLimit = 100
  }

  @property {
    ValueSet!Attribute potential() { return _potential; }
    ValueSet!Attribute attributes() { return _attributes; }

    Item equippedWeapon() {
      return (_items[0] && _items[0].isWeapon) ? _items[0] : Item.none;
    }
    /// set equipped weapon
    void equippedWeapon(Item item) {
      if (item) {
        auto idx = _items[].countUntil(item);
        assert(idx >= 0);
        _items[idx] = _items[0];
        _items[0] = item;
      }
    }

    Item[] items() { return _items; }

    string name() { return _name; }

    /// character level
    int level() { return _level; }

    // character experience
    int xp() { return _xp; }
    void xp(int val) {
      if (_xp + val >= xpLimit) {
        levelUp();
      }
      _xp = (_xp + val) % xpLimit;
    }
  }

  Item itemAt(int slot) {
    assert(slot >= 0 && slot < itemCapacity, format("item #%d/%d out of range", slot, itemCapacity));
    return _items[slot];
  }

  bool addItem(Item newItem) {
    foreach(ref item ; _items) { // look for empty slot to place item in
      if (item is null) {
        item = newItem;
        return true;
      }
    }
    return false;
  }

  /// access an attribute by name
  int opDispatch(string m)() const if (hasMember!(Attribute, m)) {
    return _attributes.opDispatch!m;
  }

  /// level up and return attribute increase values
  ValueSet!Attribute levelUp() {
    auto bonuses = _potential.map!(p => uniform!"[]"(0, 100) > p ? 0 : 1);
    _attributes = attributes + bonuses;
    return bonuses;
  }

  private:
  Item[itemCapacity] _items;
  @jsonize {
    string _name;
    int _xp;
    int _level;
    ValueSet!Attribute _attributes;
    ValueSet!Attribute _potential;
    /// load items from names
    @property {
      string[] inventory() {
        import std.algorithm : map;
        import std.array : array;
        return array(_items[].map!"a.name");
      }
      void inventory(string[] inv) {
        assert(inv.length < itemCapacity);
        foreach(name ; inv) {
          addItem(loadItem(name));
        }
      }
    }
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
