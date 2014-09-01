module gui.roster_view;

import std.algorithm : moveAll;
import gui.element;
import gui.container;
import gui.roster_slot;
import gui.string_menu;
import gui.character_sheet;
import geometry.all;
import graphics.all;
import model.character;
import util.input;

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
      addElement(new RosterSlot(slotPos, character, &selectRoster));
      slotPos.x += rosterSpacingX;
    }
    slotPos = recruitStartPos;
    foreach(idx, character ; forHire) {
      if (idx != 0 && idx % numRecruitCols == 0) {
        slotPos.x = recruitStartPos.x;
        slotPos.y += rosterSpacingY;
      }
      addElement(new RosterSlot(slotPos, character, &selectRecruit));
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
      if (_menu) {
        _menu.draw();
      }
    }

    void handleInput(InputManager input) {
      if (_menu) {
        if (input.cancel) {
          _menu = null;
        }
        else {
          _menu.handleInput(input);
        }
      }
      else {
        super.handleInput(input);
      }
    }
  }

  void slotCommand(string cmd) {
  }

  void slotHover(string cmd, Rect2i area) {
  }

  void selectRoster(Character character) {
    _menu = new StringMenu(selectedElement.bounds.center, ["equipment", "talents", "cancel"], &slotCommand,
        &slotHover);
  }

  void selectRecruit(Character character) {
    _menu = new StringMenu(selectedElement.bounds.center, ["recruit", "cancel"], &slotCommand, &slotHover);
  }

  private:
  CharacterSheet _characterSheet;
  StringMenu _menu;
}
