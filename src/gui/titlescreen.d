module gui.titlescreen;

import std.range;
import gui.element;
import gui.container;
import gui.saveslot;
import graphics.all;
import geometry.all;
import util.savegame;

enum {
  firstSavePos = Vector2i(161, 185),
  cursorShade = Color(0, 0, 0.5, 0.8),
  saveSpacing = Vector2i(0, 50),
}

class TitleScreen : GUIContainer {
  this(SaveData[] saveData) {
    auto cursor = new AnimatedSprite("target", cursorShade);
    super(Vector2i.Zero, Anchor.topLeft, "titleScreen", cursor);
    _saveData = saveData;
    auto pos = firstSavePos;
    foreach(i ; iota(0, numSaveSlots)) {
      addElement(new SaveSlot(pos, i));
      pos += saveSpacing;
    }
  }

  private:
  SaveData[] _saveData;
}
