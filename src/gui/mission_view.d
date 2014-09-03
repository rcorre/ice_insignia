module gui.mission_view;

import std.range;
import std.algorithm;
import std.string : format;
import gui.element;
import gui.container;
import gui.roster_slot;
import geometry.all;
import graphics.all;
import model.character;
import util.input;
import util.savegame;

private enum {
  goldOffset     = Vector2i(120, 25),
  rosterStartPos = Vector2i(113, 105),
  cursorShade    = Color(0, 0, 0.5, 0.8),
  numRecruitCols = 3,
  rosterSpacingX = 64,
  rosterSpacingY = 64,
}

class MissionView : GUIContainer {
  this(Vector2i pos, SaveData data) {
    _data = data;
    auto cursor = new AnimatedSprite("target", cursorShade);
    super(pos, Anchor.topLeft, "mission_view", cursor);
    auto slotPos = rosterStartPos;
    foreach(idx, character ; _data.roster) {
      if (idx != 0 && idx % numRecruitCols == 0) {
        slotPos.x = rosterStartPos.x;
        slotPos.y += rosterSpacingY;
      }
      auto slot = new RosterSlot(slotPos, character, &selectRoster, null, false);
      _slots ~= slot;
      addElement(slot);
      slotPos.x += rosterSpacingX;
    }
  }

  override {
    void draw() {
      super.draw;
      _goldFont.draw(format("%dG", _data.gold), bounds.topLeft + goldOffset);
    }

    void handleInput(InputManager input) {
      super.handleInput(input);
    }
  }

  void selectRoster(Character character) {
    auto slot = _slots.find!(a => a.character == character);
    assert(!slot.empty);
    if (!slot.empty) {
      slot.front.active = !slot.front.active;
    }
  }

  private:
  SaveData _data;
  RosterSlot[] _slots;
}

private static Font _goldFont;

static this() {
  _goldFont = getFont("rosterGold");
}
