module gui.store_view;

import std.string : format;
import std.algorithm : moveAll;
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
  storagePos = Vector2i(140, 140),
  cursorShade = Color(0, 0, 0.5, 0.8),
}

class StoreView : GUIContainer {
  this(Vector2i pos, SaveData data, Item[] forSale) {
    _data = data;
    auto cursor = new AnimatedSprite("target", cursorShade);
    super(pos, Anchor.topLeft, "store_view", cursor);
    //auto _storageMenu = new InventoryMenu(storagePos, _data.items, &itemSelect, &itemHover);
  }

  override {
    void draw() {
      super.draw();
      //_storageMenu.draw;
      _goldFont.draw(format("%dG", _data.gold), bounds.topLeft + goldOffset);
    }

    void handleInput(InputManager input) {
      /*
      if (selectedElement == _storageMenu) {
        _storageMenu.handleInput(input);
      }
      else {
        super.handleInput(input);
      }
      */
    }
  }

  void itemHover(Item item, Rect2i area) {
  }

  void itemSelect(Item item) {
  }

  private:
  //InventoryMenu _storageMenu;
  SaveData _data;
}

private static Font _goldFont;

static this() {
  _goldFont = getFont("rosterGold");
}
