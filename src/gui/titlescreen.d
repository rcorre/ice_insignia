module gui.titlescreen;

import std.range;
import gui.element;
import gui.container;
import gui.saveslot;
import graphics.all;
import geometry.all;
import util.savegame;

enum {
  firstSavePos = Vector2i(161, 120),
  saveSpacing = 50,
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
  }

  private:
  SaveData[] _saveData;
}
