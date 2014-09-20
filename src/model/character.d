module model.character;

import std.conv;
import std.string : format;
import std.random : uniform;
import std.array: array;
import std.range;
import std.algorithm;
import allegro;
import util.jsonizer;
import model.item;
import model.valueset;
import model.talent;
import model.character_spec;
import graphics.sprite;
public import model.attribute;

private enum {
  talentAwardLevels = [1, 3, 6, 10, 15, 20],
  basePotential = [
    "maxHp"        : 60,
    "strength"     : 40,
    "skill"        : 40,
    "speed"        : 40,
    "defense"      : 40,
    "luck"         : 40,
    "move"         : 0,
    "constitution" : 10
  ]
}

class Character {
  mixin JsonizeMe;

  enum {
    itemCapacity = 5,
    xpLimit = 100,
    maxPotential = 100,
  }

  /// load saved character
  @jsonize this(string name, string model, AttributeSet attributes, int level, int xp, Item[itemCapacity] items,
      string[] talentKeys = [])
  {
    _name = name;
    _model = model;
    _attributes = attributes; _potential = basePotential;
    _level = level;
    _xp = xp;
    _items = items;
    _talents = array(talentKeys.map!(a => loadTalent(a)));
  }

  this(CharacterSpec spec) {
    _name       = spec.name;
    _model      = spec.model;
    _attributes = spec.attributes;
    _potential  = basePotential;
  }

  @property {
    @jsonize {
      string name() { return _name; }
      string model() { return _model; }
      int level() { return _level; }
      int xp() { return _xp; }

      AttributeSet potential() { return _potential; }
      AttributeSet attributes() { return _attributes + _statEffects; }
      AttributeSet baseAttributes() { return _attributes; }
      AttributeSet statEffects() { return _statEffects; }

      auto items() { return _items; }
      auto talentKeys() { return array(_talents.map!"a.key"); }
    }

    auto talents() { return _talents; }

    Item equippedWeapon() {
      return (_items[0] && canWield(_items[0])) ? _items[0] : Item.none;
    }

    /// set equipped weapon
    void equippedWeapon(Item item) {
      if (item && canWield(item)) {
        auto idx = _items[].countUntil(item);
        assert(idx >= 0);
        _items[idx] = _items[0];
        _items[0] = item;
      }
    }

    bool isArmed() {
      return canWield(_items[0]);
    }

    bool canAwardTalent() {
      return talentAwardLevels.canFind(level);
    }
  }

  void passTurn() {
    auto norm = _statEffects.map!(a => a == 0 ? 0 : (a < 0 ? -1 : 1));
    _statEffects = _statEffects + norm;
  }

  /// if results in level-up, returns true and assigns bonuses
  bool awardXp(int val, out AttributeSet bonuses, out int leftover) {
    if (_xp + val >= xpLimit) {
      leftover = _xp + val - xpLimit;
      bonuses = getLevelBonuses();
      _xp = (_xp + val) % xpLimit;
      return true;
    }
    _xp = (_xp + val) % xpLimit;
    return false;
  }

  /// called when current weapon broken to equip a new weapon
  void equipNextWeapon() {
    auto item = _items[].find!(x => canWield(x));
    equippedWeapon = item.front;
  }

  bool canWield(Item item) {
    return item !is null && item.type != ItemType.magic && _talents.canFind!(x => x.weaponSkill ==
        item.type && x.weaponTier == item.tier);
  }

  ref Item itemAt(ulong slot) {
    assert(slot >= 0 && slot < itemCapacity, format("item #%d/%d out of range", slot, itemCapacity));
    return _items[slot];
  }

  bool addItem(Item newItem) {
    foreach(ref item ; _items) { // look for empty slot to place item in
      if (item is null) {
        item = newItem;
        if (!isArmed) {
          equippedWeapon = newItem;
        }
        return true;
      }
    }
    return false;
  }

  bool removeItem(Item toRemove) {
    auto idx = _items[].countUntil(toRemove);
    if (idx < 0) {
      return false;
    }
    _items[idx] = null;
    return true;
  }

  Item findItem(string name) {
    auto item = _items[].find!(a => a !is null && a.name == name);
    return item.empty ? null : item.front;
  }

  /// access an attribute by name
  int opDispatch(string m)() const if (hasMember!(Attribute, m)) {
    return _attributes.opDispatch!m;
  }

  /// level up and return attribute increase values
  AttributeSet getLevelBonuses() {
    auto bonuses = _potential.map!(p => uniform!"[]"(0, 100) > p ? 0 : 1);
    return bonuses;
  }

  bool canGetNewTalent() {
    auto talentsDeserved = talentAwardLevels.countUntil!(a => a > _level);
    return talentsDeserved > _talents.length;
  }

  Talent[] availableNewTalents() {
    bool canGetTalent(Talent talent) {
      if (_talents.canFind(talent)) { return false; } // already have it
      string prereq = talent.prerequisite;
      return (prereq is null) || _talents.canFind!(a => a.key == prereq);
    }
    return array(allTalents.filter!canGetTalent);
  }

  void applyLevelUp(AttributeSet bonuses) {
    ++_level;
    _xp = 0;
    _attributes = attributes + bonuses;
  }

  void addTalent(Talent talent) {
    _talents ~= talent;
    _attributes = _attributes + talent.bonus;
    _potential = _potential + talent.potential;
  }

  bool hasTalent(string key) {
    return _talents.canFind!(a => a.key == key);
  }

  void applyStatEffects(AttributeSet effects) {
    _statEffects = _statEffects + effects;
  }

  private:
  string _name;
  string _model;
  int _xp;
  int _level = 1;
  AttributeSet _attributes, _statEffects, _potential;
  Item[itemCapacity] _items;
  Talent[] _talents;
}

Character generateCharacter(string name, int level = 1) {
  auto spec =  loadCharacterSpec(name);
  auto character = new Character(spec);
  foreach(key ; spec.talentKeys) {
    if (!character.canGetNewTalent) { break; }
    character.addTalent(loadTalent(key));
  }
  for(int i = 1 ; i < level ; i++) {
    character.applyLevelUp(character.getLevelBonuses());
  }
  return character;
}

unittest {
  import std.json : parseJSON;

  auto json = parseJSON(`{
      "name" : "Myron",
      "attributes" : {
      "valueSet" : {
      "maxHp"        : 20,
      "strength"     : 5,
      "skill"        : 4,
      "speed"        : 5,
      "defense"      : 5,
      "luck"         : 2,
      "move"         : 4,
      "constitution" : 5
      }
      },
      "potential" : {
      "valueSet" : {
      "maxHp"        : 10,
      "strength"     : 2,
      "skill"        : 8,
      "speed"        : 5,
      "defense"      : 4,
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
