// TODO: untested
module util.savegame;

import std.file;
import std.path;
import model.character;
import model.item;
import util.jsonizer;

private string fileName = "ice_insignia_save.json";

class SaveData {
  mixin JsonizeMe;
  @jsonize {
    Character[] roster;
    Item[] items;
    int gold;
    int mission;
  }
}

SaveData loadSave() {
  if (!savePath.exists) { return null; }
  return savePath.readJSON!SaveData;
}

void saveGame(SaveData data) {
  data.writeJSON(savePath);
}

private @property string savePath() {
  string dir;
  debug {
    return fileName;
  }
  else {
    version(Windows) {
      dir = "./savegame";
    }
    version(linux) {
      dir = expandTilde("~/.ice_insignia");
    }

    if (!dir.exists) {
      mkdir(dir);
    }
  }

  return dir ~ "/" ~ fileName;
}
