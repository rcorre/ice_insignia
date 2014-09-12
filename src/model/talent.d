module model.talent;

import allegro;
import util.jsonizer;
import geometry.all;
import graphics.sprite;
import model.valueset;
import model.item;
import model.attribute;

class Talent {
  @jsonize this(string key, string title, string description, ValueSet!Attribute bonus,
      ValueSet!Attribute potential, ItemType weaponSkill = ItemType.other, int weaponTier = 0,
      string prerequisite = null)
  {
    this.key = key;
    this.title = title;
    this.description = description;
    this.bonus = bonus;
    this.potential = potential;
    this.weaponSkill = weaponSkill;
    this.weaponTier = weaponTier;
    this.prerequisite = prerequisite;
    this.sprite = new Sprite(key);
  }

  @jsonize const {
    string key;
    string title;
    string description;
    string prerequisite;
    ValueSet!Attribute bonus;     /// instant additions to stats
    ValueSet!Attribute potential; /// improvements to potential
    ItemType weaponSkill;
    int weaponTier;
  }

  Sprite sprite;
}

Talent loadTalent(string key) {
  assert(key in _talentStore, "could not find talent " ~ key);
  return _talentStore[key];
}

Talent[] allTalents() {
  return _talentStore.values;
}

private Talent[string] _talentStore;

static this() {
  _talentStore = readJSON!(Talent[string])(Paths.talentData);
}
