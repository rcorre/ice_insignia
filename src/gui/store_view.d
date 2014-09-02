module gui.store_view;

import std.string : format;
import std.algorithm : countUntil;
import std.range;
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
  storagePos = Vector2i(100, 140),
  shopPos = Vector2i(480, 220),
  cursorShade = Color(0, 0, 0.5, 0.8),
  shopInfoOffset = Vector2i(-100, 0),
  storageInfoOffset = Vector2i(100, 0),
}

class StoreView : GUIContainer {
  this(Vector2i pos, SaveData data, Item[] forSale) {
    _data = data;
    auto cursor = new AnimatedSprite("target", cursorShade);
    super(pos, Anchor.topLeft, "store_view", cursor);
    with(InventoryMenu.ShowPrice) {
      _storageMenu = new InventoryMenu(storagePos, _data.items, &sellItem, &storageHover, resale);
      _shopMenu = new InventoryMenu(shopPos, forSale, &purchaseItem, &shopHover, full, false);
    }
    _storageMenu.hasFocus = true;
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
        _storageMenu.hasFocus = !_storageMenu.hasFocus;
        _shopMenu.hasFocus = !_shopMenu.hasFocus;
      }
      _storageMenu.handleInput(input);
      _shopMenu.handleInput(input);
      super.handleInput(input);
    }
  }

  void storageHover(Item item, Rect2i rect) {
    _itemView = item ? new ItemView(item, rect.topRight + storageInfoOffset) : null;
  }

  void shopHover(Item item, Rect2i rect) {
    _itemView = item ? new ItemView(item, rect.bottomLeft + shopInfoOffset) : null;
  }

  void purchaseItem(Item item) {
    if (_data.gold >= item.price) {
      foreach(ref slot ; _data.items) {
        if (slot is null) {
          slot = item;
          _data.gold -= item.price;
          saveGame(_data);
          return;
        }
      }
    }
  }

  void sellItem(Item item) {
    if (item is null) { return; }
    auto idx = _data.items[].countUntil(item);
    if (idx > -1) {
      _data.items[idx] = null;
      _data.gold += item.resalePrice;
      saveGame(_data);
    }
  }

  private:
  InventoryMenu _storageMenu, _shopMenu;
  ItemView _itemView;
  SaveData _data;
}

private static Font _goldFont;

static this() {
  _goldFont = getFont("rosterGold");
}
