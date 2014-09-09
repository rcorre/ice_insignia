module model.character_spec;

import std.file : readText;
import std.range : front;
import std.random;
import std.string;
import std.algorithm;
import std.ascii;
import std.array;
import allegro;
import util.jsonizer;
import model.valueset;
import model.attribute;

private enum {
  nameList = "./content/data/names.txt",
  rareNameChance = 0.1
}

struct CharacterSpec {
  mixin JsonizeMe;
  string name; // randomly picked from name list
  @jsonize {
    string model;
    ValueSet!Attribute attributes;
    ValueSet!Attribute potential;
    string[] talentKeys;
    string[] names;
  }
}

auto loadCharacterSpec(string model) {
  assert(model in _specs, "could not match character spec " ~ model);
  auto spec = _specs[model];
  if (uniform01() < rareNameChance) {
    spec.name = spec.names.randomSample(1).front;
  }
  else {
    spec.name = _names.randomSample(1).front;
  }
  return spec;
}

static this() {
  _specs = readJSON!(CharacterSpec[string])(Paths.characterData);  // read character specs
  auto nameStr =nameList.readText;                                 // read all names
  // split on whitespace and discard non-ascii
  _names = array(splitter(nameStr).filter!(s => s.all!(c => c.isASCII)));
}

private CharacterSpec[string] _specs;
private string[] _names;
