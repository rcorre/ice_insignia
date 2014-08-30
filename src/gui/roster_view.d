module gui.roster_view;

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
}

class RosterView : GUIContainer {
  this(Vector2i pos, Character[] characters) {
    super(pos, Anchor.topLeft, "roster_view");
    int counter = 0;
    Vector2i slotPos = rosterStartPos;
    foreach(character ; characters) {
      addElement(new RosterSlot(slotPos, character));
      slotPos.x += rosterSpacingX;
      if (slotPos.x > rosterEndPos.x) {
        slotPos.x = rosterStartPos.x;
        slotPos.y = rosterSpacingY;
      }
    }
  }
}
