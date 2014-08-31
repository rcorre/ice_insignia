module model.character_spec;

import allegro;
import util.jsonizer;
import model.valueset;
import model.attribute;

struct CharacterSpec {
  mixin JsonizeMe;
  string name; // randomly picked from name list
  @jsonize {
    string model;
    ValueSet!Attribute attributes;
    ValueSet!Attribute potential;
    string[] talents;
  }
}

auto loadCharacterSpec(string name) {
  assert(name in _specs, "could not match character spec " ~ name);
  auto spec = _specs[name];
  spec.name = "fill me in";
  return spec;
}

static this() {
  _specs = readJSON!(CharacterSpec[string])(Paths.characterData);
}

private CharacterSpec[string] _specs;
