module util.savegame;

import std.file;
import std.path;
import std.algorithm;
import std.range;
import std.random;
import model.character;
import model.item;
import util.jsonizer;

enum {
  itemStorageSize = 10,
  rosterSize = 12,
  numRecruits = 6,
  recruitModels = ["mercenary", "fighter", "soldier", "hunter"],
}

private enum {
  fileName = "ice_insignia_save.json",
  startingGold = 1000,
}

class SaveData {
  mixin JsonizeMe;
  @jsonize {
    Character[] roster;
    Character[] forHire;
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

  void remove(Character c) {
    auto idx = roster.countUntil(c);
    if (idx >= 0) {
      roster = roster.remove(idx);
      saveGame(this);
    }
  }

  void advanceMission() {
    ++mission;
    generateNewRecruits(mission + 1);
    saveGame(this);
  }

  void generateNewRecruits(int maxLevel) {
    forHire = null;
    foreach(i ; iota(0, numRecruits)) {
      auto model = recruitModels.randomSample(1).front;
      int level = uniform!"[]"(1, maxLevel);
      forHire ~= generateCharacter(model, level);
    }
  }
}

SaveData loadSave() {
  if (!savePath.exists) {  // no save yet
    auto data = new SaveData;
    data.gold = startingGold;
    data.generateNewRecruits(1);
    data.saveGame;
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
