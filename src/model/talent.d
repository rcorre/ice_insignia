module model.talent;

import allegro;
import util.jsonizer;
import geometry.all;
import graphics.sprite;
import model.character;
import model.valueset;
import model.item;

class Talent {
  @jsonize this(string name, string description, ValueSet!Attribute bonus,
      ValueSet!Attribute potential, ItemType weaponSkill = ItemType.none, int weaponTier = 0,
      string prerequesite = null)
  {
    this.name = name;
    this.description = description;
    this.bonus = bonus;
    this.potential = potential;
    this.weaponSkill = weaponSkill;
    this.weaponTier = weaponTier;
    this.prerequesite = prerequesite;
  }

  @jsonize const {
    string name;
    string description;
    string prerequesite;
    ValueSet!Attribute bonus;     /// instant additions to stats
    ValueSet!Attribute potential; /// improvements to potential
    ItemType weaponSkill;
    int weaponTier;
  }

  void drawIcon(Vector2i pos) {
    _sprite.draw(pos);
  }

  private Sprite _sprite;
}

Talent loadTalent(string name) {
  assert(name in _talentStore, "could not find talent " ~ name);
  return _talentStore[name];
}

private Talent[string] _talentStore;

static this() {
  _talentStore = readJSON!(Talent[string])(Paths.talentData);
}
