module gui.roster_view;

import std.algorithm : moveAll;
import gui.element;
import gui.container;
import gui.roster_slot;
import geometry.all;
import graphics.all;
import model.character;

private enum {
  rosterSpacingX = 64,
  rosterSpacingY = 64,
  rosterStartPos = Vector2i(112, 170),
  rosterEndPos = Vector2i(322, 509),
  numRosterEntries = 24,
  cursorShade = Color(0, 0, 0.5, 0.8),
}

class RosterView : GUIContainer {
  this(Vector2i pos, Character[] roster) {
    auto cursor = new AnimatedSprite("target", cursorShade);
    super(pos, Anchor.topLeft, "roster_view", cursor);
    int counter = 0;
    Vector2i slotPos = rosterStartPos;
    foreach(character ; roster) {
      addElement(new RosterSlot(slotPos, character));
      slotPos.x += rosterSpacingX;
      if (slotPos.x > rosterEndPos.x) {
        slotPos.x = rosterStartPos.x;
        slotPos.y += rosterSpacingY;
      }
    }
  }
}
