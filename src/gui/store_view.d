module gui.store_view;

import std.string : format;
import std.algorithm : countUntil;
import std.range;
import std.traits;
import gui.all;
import geometry.all;
import graphics.all;
import model.character;
import model.item;
import util.input;
import util.bicycle;
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
    _storeStock = forSale;
    _categorySelector = bicycle([EnumMembers!ItemType][]);
    with(InventoryMenu.ShowPrice) {
      _storageMenu = new InventoryMenu(storagePos, _data.items, &sellItem, &storageHover,
          x => "sell", resale, true);
      auto items = itemsForSale(_categorySelector.front);
      _shopMenu = new InventoryMenu(shopPos, items, &purchaseItem, &shopHover, 
          x => "buy", full, false);
    }
  }

  override {
    void draw() {
      super.draw();
      _storageMenu.draw;
      _shopMenu.draw;
      if (_itemView) { _itemView.draw; }
      _goldFont.draw(format("%dG", _data.gold), bounds.topLeft + goldOffset);
      _categoryFont.drawCentered(_categorySelector.front, categoryPos);
      if (_shopMenu.hasFocus) {
        drawInputIcon("previous", categoryPos - inputIconOffset, _gamepadConnected);
        drawInputIcon("next", categoryPos + inputIconOffset, _gamepadConnected);
      }
    }

    bool handleInput(InputManager input) {
      _gamepadConnected = input.gamepadConnected;
      if (input.selectLeft || input.selectRight) {
        _storageMenu.hasFocus = !_storageMenu.hasFocus;
        _shopMenu.hasFocus = !_shopMenu.hasFocus;
      }
      else if (input.previous && _shopMenu.hasFocus) {
        auto stock = itemsForSale(_categorySelector.reverse);
        _shopMenu = new InventoryMenu(shopPos, stock, &purchaseItem, &shopHover,
            x => "buy", InventoryMenu.ShowPrice.full, true);
      }
      else if (input.next && _shopMenu.hasFocus) {
        auto stock = itemsForSale(_categorySelector.advance);
        _shopMenu = new InventoryMenu(shopPos, stock, &purchaseItem, &shopHover,
            x => "buy", InventoryMenu.ShowPrice.full, true);
      }
      else {
        _storageMenu.handleInput(input);
        _shopMenu.handleInput(input);
        return false;
      }
      super.handleInput(input);
      return true;
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
  Bicycle!(ItemType[]) _categorySelector;
  SaveData _data;
  bool _gamepadConnected;
  Item[] _storeStock;

  Item[] itemsForSale(ItemType type) {
    return array(_storeStock.filter!(x => x.type == type));
  }
}

private static Font _goldFont, _categoryFont;

static this() {
  _goldFont = getFont("rosterGold");
  _categoryFont = getFont("shopCategory");
}
