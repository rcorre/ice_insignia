module gui.titlescreen;

import std.range;
import gui.element;
import gui.container;
import gui.saveslot;
import gui.input_icon;
import gui.button;
import graphics.all;
import geometry.all;
import util.savegame;

enum {
  firstSavePos = Vector2i(161, 120),
  saveSpacing = 30,
  prefsPos = Vector2i(405, 550),
}

class TitleScreen : GUIContainer {
  this(SaveData[] saveData, void delegate(SaveData) selectSave) {
    auto cursor = new Sprite("saveCursor");
    super(Vector2i.Zero, Anchor.topLeft, "titleScreen", cursor);
    _saveData = saveData;
    auto pos = firstSavePos;
    foreach(data ; saveData) {
      auto slot = new SaveSlot(pos, data, selectSave);
      addElement(slot);
      pos += Vector2i(0, saveSpacing + slot.height);
    }
    addElement(new Button(prefsPos, &displayPrefs, "preferencesButton"));
  }

  void displayPrefs() {
  }

  private:
  SaveData[] _saveData;
}
