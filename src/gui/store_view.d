module gui.store_view;

import std.string : format;
import std.algorithm : moveAll;
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
  storagePos = Vector2i(140, 140),
  shopPos = Vector2i(440, 220),
  cursorShade = Color(0, 0, 0.5, 0.8),
  shopInfoOffset = Vector2i(-100, 0),
  storageInfoOffset = Vector2i(0, -50),
}

class StoreView : GUIContainer {
  this(Vector2i pos, SaveData data, Item[] forSale) {
    _data = data;
    auto cursor = new AnimatedSprite("target", cursorShade);
    super(pos, Anchor.topLeft, "store_view", cursor);
    _storageMenu = new InventoryMenu(storagePos, _data.items, &itemSelect, &itemHover, InventoryMenu.ShowPrice.resale);
    _shopMenu = new InventoryMenu(shopPos, forSale, &itemSelect, &itemHover, InventoryMenu.ShowPrice.full);
    _selectedMenu = _storageMenu;
  }

  override {
    void draw() {
      super.draw();
      _storageMenu.draw;
      _shopMenu.draw;
      if (_itemView) { _itemView.draw; }
      _goldFont.draw(format("%dG", _data.gold), bounds.topLeft + goldOffset);
    }

    void handleInput(InputManager input) {
      if (input.selectLeft || input.selectRight) {
        _selectedMenu = (_selectedMenu == _shopMenu) ? _storageMenu : _shopMenu;
      }
      _selectedMenu.handleInput(input);
      super.handleInput(input);
    }
  }

  void itemHover(Item item, Rect2i rect) {
    auto pos = (_selectedMenu == _shopMenu) ? rect.bottomLeft + shopInfoOffset : rect.bottomRight + storageInfoOffset;
    _itemView = item ? new ItemView(item, pos) : null;
  }

  void itemSelect(Item item) {
  }

  private:
  InventoryMenu _storageMenu, _shopMenu;
  InventoryMenu _selectedMenu;
  ItemView _itemView;
  SaveData _data;
}

private static Font _goldFont;

static this() {
  _goldFont = getFont("rosterGold");
}
