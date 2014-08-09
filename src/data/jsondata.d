module util.jsondata;

import std.json;
import std.file;
import std.conv;
import std.string;

private Object[string][TypeInfo] _store;

/// load each entry in a json file, making data accessible by getData!T(name)
void loadDataFile(T)(string filename) if (is(typeof(new T("", JSONValue())))) {
  auto content = to!string(read(filename)); // read json file
  foreach (name,value ; parseJSON(content).object) {
    _store[typeid(T)][name] = new T(name, value); // place each parsed T into _store[T][name]
  }
}

/// call loadDataFile on each file in dirname matching pattern (e.g. pattern = "*.json")
void loadDataDir(T)(string dirname, string pattern) if (is(typeof(new T("", JSONValue())))) {
  foreach (filename ; dirEntries(dirname)) {
    loadDataFile(T)(filename);
  }
}

T getData(T)(string key) {
  assert(typeid(T) in _store, format("no %s data was loaded!", T.stringof));
  assert(key in _store[typeid(T)], format("no loaded %s data has key %s!", T.stringof, key));
  return cast(T) _store[typeid(T)][key];
}

JSONValue readJSON(string fileName) {
  return parseJSON(fileName.readText);
}

unittest {
  import std.path;

  static class DummyData {
    string name;
    int value1, value2;
    this (string key, JSONValue json) {
      name = key;
      auto data = json.object;
      value1 = cast(int) data["value1"].integer;
      value2 = cast(int) data["value2"].integer;
    }
  }

  // create a temp file for testing
  string tmpFilename = buildPath(tempDir(), "haven_jsondata_test.json");

  // write some test json data
  auto dummyJson = `{
    "dummy1" : { "value1" : 1, "value2" : 2 },
    "dummy2" : { "value1" : 5, "value2" : 1 }
  }`;
  write(tmpFilename, dummyJson);

  // try reading that data
  loadDataFile!DummyData(tmpFilename);
  auto dummy1 = getData!DummyData("dummy1");
  assert(dummy1.name == "dummy1" && dummy1.value1 == 1 && dummy1.value2 == 2);
  auto dummy2 = getData!DummyData("dummy2");
  assert(dummy2.name == "dummy2" && dummy2.value1 == 5 && dummy2.value2 == 1);
}
