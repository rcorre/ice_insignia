module gui.roster_view;

import std.string : format;
import gui.element;
import gui.container;
import gui.roster_slot;
import gui.string_menu;
import gui.inventory_menu;
import gui.character_sheet;
import geometry.all;
import graphics.all;
import model.character;
import model.item;
import util.input;
import util.savegame;

private enum {
  goldOffset = Vector2i(120, 25),
  rosterSpacingX = 64,
  rosterSpacingY = 64,
  rosterStartPos = Vector2i(112, 170),
  rosterEndPos = Vector2i(258, 378),
  recruitStartPos = Vector2i(113, 458),
  numRecruitCols = 3,
  cursorShade = Color(0, 0, 0.5, 0.8),
  characterSheetPos = Vector2i(288, 57),
  hireCostPerLevel = 200,
}

class RosterView : GUIContainer {
  this(Vector2i pos, SaveData data, Character[] forHire) {
    _data = data;
    auto cursor = new AnimatedSprite("target", cursorShade);
    super(pos, Anchor.topLeft, "roster_view", cursor);
    auto slotPos = recruitStartPos;
    generateRoster;
    foreach(idx, character ; forHire) {
      if (idx != 0 && idx % numRecruitCols == 0) {
        slotPos.x = recruitStartPos.x;
        slotPos.y += rosterSpacingY;
      }
      addElement(new RosterSlot(slotPos, character, &selectRecruit, &rosterHover));
      slotPos.x += rosterSpacingX;
    }
  }

  void generateRoster() {
    auto slotPos = rosterStartPos;
    foreach(idx, character ; _data.roster) {
      if (idx != 0 && idx % numRecruitCols == 0) {
        slotPos.x = recruitStartPos.x;
        slotPos.y += rosterSpacingY;
      }
      addElement(new RosterSlot(slotPos, character, &selectRoster, &rosterHover));
      slotPos.x += rosterSpacingX;
    }
  }

  override {
    void draw() {
      super.draw;
      if (_characterSheet) {
        _characterSheet.draw;
      }
      if (_menu) {
        _menu.draw();
      }
      _goldFont.draw(format("%dG", _data.gold), bounds.topLeft + goldOffset);
    }

    void handleInput(InputManager input) {
      final switch(_state) {
        case State.editInventory:
          if (input.cancel) {
            _state = State.viewRoster;
            _characterSheet.mode = CharacterSheet.Mode.idle;
          }
          else {
            _characterSheet.handleInput(input);
          }
          break;
        case State.editTalents:
        case State.viewRoster:
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
  }

  void slotCommand(string cmd) {
    switch(cmd) {
      case "cancel":
        _menu = null;
      case "equipment":
        _characterSheet.mode = CharacterSheet.Mode.editInventory;
        _state = State.editInventory;
      case "talents":
      default:
    }
  }

  void slotHover(string cmd, Rect2i area) {
  }

  void rosterHover(Character character) {
    if (character) {
      _characterSheet = new CharacterSheet(characterSheetPos, character);
    }
  }

  void recruitCommand(string cmd) {
    if (cmd != "cancel") { // other command is recruit
      auto slot = cast(RosterSlot) selectedElement;
      auto character = slot.character;
      auto cost = character.level * hireCostPerLevel;
      if (cost <= _data.gold) {
        slot.character = null;
        // add character to roster
        _data.roster ~= character;
        generateRoster;
        _data.gold -= cost;
        saveGame(_data);
      }
    }
    _menu = null;
  }

  void selectRoster(Character character) {
    auto pos = selectedElement.bounds.center;
    _menu = new StringMenu(pos, ["equipment", "talents", "cancel"], &slotCommand, &slotHover);
  }

  void selectRecruit(Character character) {
    if (character) {
      auto pos = selectedElement.bounds.center;
      auto selections = [format("recruit (%dG)", character.level * hireCostPerLevel), "cancel"];
      _menu = new StringMenu(pos, selections, &recruitCommand, &slotHover);
    }
  }

  void selectEquippedItem(Item item) {
  }

  private:
  CharacterSheet _characterSheet;
  StringMenu _menu;
  InventoryMenu _inventoryMenu;
  SaveData _data;
  State _state;

  enum State {
    viewRoster,
    editInventory,
    editTalents
  }
}

private static Font _goldFont;

static this() {
  _goldFont = getFont("rosterGold");
}
