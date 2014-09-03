module gui.character_sheet;

import std.conv;
import std.traits;
import allegro;
import gui.all;
import model.character;
import model.battler;
import geometry.all;
import graphics.all;
import util.input;

private enum {
  textureName        = "character_view",
  spritePos          = Vector2i(51, 51),
  namePos            = Vector2i(81, 40),
  lvlPos             = Vector2i(260, 38),
  hpBarPos           = Vector2i(71, 106),
  hpBarWidth         = 96,
  hpBarHeight        = 16,
  hpBarFg            = Color(0.0, 0.8, 0),
  hpBarBg            = Color.white,
  hpTextColor        = Color.black,
  xpBarPos           = Vector2i(71, 138),
  xpBarWidth         = 96,
  xpBarHeight        = 16,
  xpBarFg            = Color(0.8, 0.8, 0),
  xpBarBg            = Color.white,
  xpTextColor        = Color.black,
  attributesPos      = Vector2i(83, 200),
  attributesSep      = 32,
  attributeBarWidth  = 96,
  attributeBarHeight = 12,
  potentialBarHeight = 4,
  attributeBarFg     = Color(0.0, 0.8, 0),
  attributeBarBg     = Color.white,
  potentialBarFg     = Color(0.3, 0.4, 0.8),
  potentialBarBg     = Color.black,
  attributeTextColor = Color.black,
  equipmentPos       = Vector2i(271, 306),
  equipmentSep       = 32,
  talentsPos         = Vector2i(376, 117),
  talentsSep         = 32,
  combatStatsPos     = Vector2i(269, 129),
  combatStatsSep     = 32
}

/// displays info about a character's stats
class CharacterSheet {
  enum Mode { idle, editInventory, editTalents }
  this(Vector2i topLeft, Battler battler, bool showPotential = false) {
    _topLeft = topLeft;
    _bgTexture = getTexture(textureName);
    _character = battler.character;
    _sprite = battler.sprite;
    populate(battler.hp, showPotential);
  }

  this(Vector2i topLeft, Character character, bool showPotential = false) {
    _topLeft = topLeft;
    _character = character;
    _sprite = new CharacterSprite(character.model);
    populate(character.maxHp, showPotential);
  }

  @property {
    auto mode() { return _mode; }
    auto mode(Mode val) { 
      if (val == Mode.editInventory) {
        _inventoryMenu.hasFocus = true;
      }
      else {
        _inventoryMenu.hasFocus = false;
      }
      _mode = val; 
    }
  }

  void handleInput(InputManager input) {
    final switch(_mode) {
      case Mode.idle:
      case Mode.editTalents:
        break;
      case Mode.editInventory:
        _inventoryMenu.handleInput(input);
        break;
    }
  }

  void draw() {
    _bgTexture.drawTopLeft(_topLeft);
    foreach(bar ; _progressBars) {
      bar.draw();
    }
    _inventoryMenu.draw;
    _sprite.draw(_topLeft + spritePos);
    _nameFont.draw(_character.name, _topLeft + namePos);
    _levelFont.draw(to!string(_character.level), _topLeft + lvlPos);
  }

  private:
  Mode _mode;
  Texture _bgTexture;
  Sprite _sprite;
  Character _character;
  InventoryMenu _inventoryMenu;
  ProgressBar!int[] _progressBars;
  Vector2i _topLeft;

  void populate(int hp, bool showPotential) {
    _bgTexture = getTexture(textureName);
    makeAttributeBars(showPotential);
    makeXpAndHpBars(hp);
    _inventoryMenu = new InventoryMenu(_topLeft + equipmentPos, _character.items, null, null,
        InventoryMenu.ShowPrice.no, false);
  }

  void makeAttributeBars(bool showPotential) {
    Rect2i area = Rect2i(_topLeft + attributesPos, attributeBarWidth, attributeBarHeight);
    foreach(attribute ; Attribute.strength .. Attribute.max) {
      // make bar for attribute
      auto val = _character.attributes[attribute];
      auto maxVal = AttributeCaps[attribute];
      _progressBars ~= new ProgressBar!int(area, val, maxVal, attributeBarFg, attributeBarBg, attributeTextColor);
      if (showPotential) {
        // now make bar for potential right below attribute
        val = _character.potential[attribute];
        auto area2 = Rect2i(area.x, area.y + attributeBarHeight, attributeBarWidth, potentialBarHeight);
        _progressBars ~= new ProgressBar!int(area2, val, 100, potentialBarFg, potentialBarBg, attributeTextColor,
            ProgressBar!int.DrawText.none);
      }
      area.y += attributesSep;
    }
  }

  void makeXpAndHpBars(int currentHp) {
    auto area = Rect2i(_topLeft + hpBarPos, hpBarWidth, hpBarHeight);
    _progressBars ~= new ProgressBar!int(area, currentHp, _character.maxHp, hpBarFg, hpBarBg, hpTextColor);
    area = Rect2i(_topLeft + xpBarPos, xpBarWidth, xpBarHeight);
    _progressBars ~= new ProgressBar!int(area, _character.xp, _character.xpLimit, xpBarFg, xpBarBg, xpTextColor);
  }

  static Font _nameFont, _levelFont;
  static this() {
    _nameFont  = getFont("characterSheetName");
    _levelFont = getFont("characterSheetLevel");
  }
}
