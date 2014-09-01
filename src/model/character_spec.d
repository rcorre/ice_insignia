module model.character_spec;

import std.string : splitLines;
import std.file : readText;
import std.random : randomSample;
import std.range : front;
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

auto loadCharacterSpec(string model) {
  assert(model in _specs, "could not match character spec " ~ model);
  auto spec = _specs[model];
  spec.name = _names.randomSample(1).front;
  return spec;
}

static this() {
  _specs = readJSON!(CharacterSpec[string])(Paths.characterData);
  _names = Paths.names.readText.splitLines;
}

private CharacterSpec[string] _specs;
private string[] _names;
