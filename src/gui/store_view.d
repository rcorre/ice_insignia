module gui.store_view;

import std.string : format;
import std.algorithm : countUntil;
import std.range;
import gui.all;
import geometry.all;
import graphics.all;
import model.character;
import model.item;
import util.input;
import util.savegame;

private enum {
  goldOffset = Vector2i(120, 25),
  storagePos = Vector2i(100, 140),
  shopPos = Vector2i(470, 200),
  categoryPos = Vector2i(577, 167),
  cursorShade = Color(0, 0, 0.5, 0.8),
  shopInfoOffset = Vector2i(-100, 0),
  storageInfoOffset = Vector2i(100, 0),
  inputIconOffset = Vector2i(64, 0),
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
      _categoryFont.drawCentered(_category, categoryPos);
      if (_shopMenu.hasFocus) {
        drawInputIcon("previous", categoryPos - inputIconOffset, _gamepadConnected);
        drawInputIcon("next", categoryPos + inputIconOffset, _gamepadConnected);
      }
    }

    void handleInput(InputManager input) {
      if (input.selectLeft || input.selectRight) {
        _storageMenu.hasFocus = !_storageMenu.hasFocus;
        _shopMenu.hasFocus = !_shopMenu.hasFocus;
      }
      _storageMenu.handleInput(input);
      _shopMenu.handleInput(input);
      _gamepadConnected = input.gamepadConnected;
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
      auto hadRoom = _data.addItem(item);
      if (hadRoom) {
        _data.gold -= item.price;
          saveGame(_data);
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
  ItemType _category;
  SaveData _data;
  bool _gamepadConnected;
}

private static Font _goldFont, _categoryFont;

static this() {
  _goldFont = getFont("rosterGold");
  _categoryFont = getFont("shopCategory");
}
