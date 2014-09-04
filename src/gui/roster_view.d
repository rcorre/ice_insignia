module gui.roster_view;

import std.string : format;
import std.algorithm;
import gui.element;
import gui.container;
import gui.roster_slot;
import gui.string_menu;
import gui.inventory_menu;
import gui.character_sheet;
import gui.item_view;
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
  inventoryPos = Vector2i(360, 177),
  itemInfoOffset = Vector2i(-100, 0),
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
      if (_itemView) {
        _itemView.draw;
      }
      if (_inventoryMenu) {
        _inventoryMenu.draw;
      }
    }

    void handleInput(InputManager input) {
      final switch(_state) {
        case State.editInventory:
          if (input.cancel) {
            _state = State.viewRoster;
            _characterSheet.mode = CharacterSheet.Mode.idle;
          }
          if (input.selectLeft || input.selectRight) {
            if (_characterSheet.mode == CharacterSheet.Mode.editInventory) {
              _characterSheet.mode = CharacterSheet.Mode.idle;
              _inventoryMenu.hasFocus = true;
            }
            else {
              _characterSheet.mode = CharacterSheet.Mode.editInventory;
              _inventoryMenu.hasFocus = false;
            }
          }
          else {
            _characterSheet.handleInput(input);
            _inventoryMenu.handleInput(input);
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
    _menu = null;
    switch(cmd) {
      case "cancel":
        break;
      case "equipment":
        enterInventoryEditMode;
        break;
      case "talents":
        break;
      default:
    }
  }

  void enterInventoryEditMode() {
    _state = State.editInventory;
    _inventoryMenu = new InventoryMenu(inventoryPos, _data.items, &giveItem, &itemHover);
    _inventoryMenu.hasFocus = true;
  }

  void slotHover(string cmd, Rect2i area) {
  }

  void itemHover(Item item, Rect2i rect) {
    _itemView = item ? new ItemView(item, rect.topLeft + itemInfoOffset) : null;
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

  void giveItem(Item item) {
    auto slot = cast(RosterSlot) selectedElement;
    auto character = slot.character;
    auto itemIdx = _data.items[].countUntil(item);
    if (itemIdx >= 0) {
      if (character.addItem(item)) {
        _data.items[itemIdx] = null;
        saveGame(_data);
      }
    }
  }

  private:
  CharacterSheet _characterSheet;
  StringMenu _menu;
  InventoryMenu _inventoryMenu;
  ItemView _itemView;
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
