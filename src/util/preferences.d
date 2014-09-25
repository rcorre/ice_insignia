module util.preferences;

import std.file;
import std.path;
import util.jsonizer;

class Preferences {
  mixin JsonizeMe;
  @jsonize {
    float musicVolume;
    float soundVolume;
    bool showInputIcons;
  }
}

Preferences userPreferences;

private:
enum prefPath = "./save/prefs.json";

static this() {
  if (prefPath.exists) {
    userPreferences = prefPath.readJSON!Preferences;
  }
  else {
    userPreferences = new Preferences;
  }
}

static ~this() {
  if (!prefPath.dirName.exists) {
    mkdir(prefPath.dirName);
  }
  userPreferences.writeJSON(prefPath);
}
