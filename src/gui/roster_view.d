module gui.roster_view;

import std.algorithm : moveAll;
import gui.element;
import gui.container;
import gui.roster_slot;
import gui.character_sheet;
import geometry.all;
import graphics.all;
import model.character;

private enum {
  rosterSpacingX = 64,
  rosterSpacingY = 64,
  rosterStartPos = Vector2i(112, 170),
  rosterEndPos = Vector2i(258, 378),
  recruitStartPos = Vector2i(113, 458),
  numRecruitCols = 3,
  cursorShade = Color(0, 0, 0.5, 0.8),
  characterSheetPos = Vector2i(288, 57)
}

class RosterView : GUIContainer {
  this(Vector2i pos, Character[] roster, Character[] forHire) {
    auto cursor = new AnimatedSprite("target", cursorShade);
    super(pos, Anchor.topLeft, "roster_view", cursor);
    int counter = 0;
    Vector2i slotPos = rosterStartPos;
    foreach(idx, character ; roster) {
      if (idx != 0 && idx % numRecruitCols == 0) {
        slotPos.x = recruitStartPos.x;
        slotPos.y += rosterSpacingY;
      }
      addElement(new RosterSlot(slotPos, character));
      slotPos.x += rosterSpacingX;
    }
    slotPos = recruitStartPos;
    foreach(idx, character ; forHire) {
      if (idx != 0 && idx % numRecruitCols == 0) {
        slotPos.x = recruitStartPos.x;
        slotPos.y += rosterSpacingY;
      }
      addElement(new RosterSlot(slotPos, character));
      slotPos.x += rosterSpacingX;
    }
  }

  override {
    void handleCursorMoved() {
      auto slot = cast(RosterSlot) selectedElement;
      if (slot) {
        _characterSheet = new CharacterSheet(characterSheetPos, slot.character);
      }
    }

    void draw() {
      super.draw;
      if (_characterSheet) {
        _characterSheet.draw;
      }
    }
  }

  private:
  CharacterSheet _characterSheet;
}
