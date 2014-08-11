module model.valueset;

import std.json;
import std.conv;
import std.string;
import std.algorithm;

struct ValueSet(T) if (is(T == enum)) {
  alias int[T.max + 1] ValueStore;

  this(const ValueStore values) {
    _values = values;
  }

  this(JSONValue jsonEntry) {
    foreach ( k,v ; jsonEntry.object) {
      _values[to!T(k)] = cast(int) v.integer;
    }
  }

  /// + / - on ValueSets correspond to arraywise + / - on the ValueStores
  ValueSet opBinary(string op)(ValueSet!T other) if (op == "+" || op == "-") {
    ValueStore newValues;
    newValues[] = mixin("_values[]" ~ op ~ "other._values[]");
    return ValueSet(newValues);
  }

  /// "create" a property to access the value corresponding to each enum name
  int opDispatch(string m)() const {
    return _values[to!T(m)];
  }

  /// allow access to values via opIndex
  int opIndex(T m) const {
    return _values[m];
  }

  private ValueStore _values;
}

// Elemental test
unittest {
  enum Element { physical, heat, shock, mind } /// Possible types for damage and resistance.
  alias ValueSet!Element Elemental;            /// Elemental is used to represent damage or resistances

  // try parsing an Elemental from a JSONValue
  JSONValue json =
    parseJSON(` {
        "damage" : { "physical" : 1, "mind" : 2, "heat" : 4 },
        "resist" : { "physical" : 1, "mind" : 1, "shock" : 3 }
    } `);
  auto dmg = Elemental(json.object["damage"]);
  auto resist = Elemental(json.object["resist"]);
  // specified values should be set
  assert (dmg.physical == 1 && dmg.heat == 4);
  // unspecified values should not be set
  assert (dmg.shock == 0 && resist.heat == 0);
  // make sure opIndex works too
  assert (dmg[Element.physical] == 1 && dmg[Element.heat] == 4);

  // try subtracting resistance from damage
  auto result = dmg - resist;
  assert (result.physical == 0  && result.mind == 1 && result.heat == 4 && result.shock == -3);
}
