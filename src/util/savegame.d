// TODO: untested
module util.savegame;

import std.file;
import std.path;
import model.character;
import model.item;
import util.jsonizer;

enum {
  itemStorageSize = 10
}

private enum {
  fileName = "ice_insignia_save.json",
  startingGold = 1000
}

class SaveData {
  mixin JsonizeMe;
  @jsonize {
    Character[] roster;
    Item[itemStorageSize] items;
    int gold;
    int mission;
  }

  bool addItem(Item item) {
    foreach(ref slot ; items) {
      if (slot is null) {
        slot = item;
        return true;
      }
    }
    return false;
  }
}

SaveData loadSave() {
  if (!savePath.exists) {  // no save yet
    auto data = new SaveData;
    data.gold = startingGold;
    return data;
  }
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
