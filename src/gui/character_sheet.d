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
  namePos            = Vector2i(81, 47),
  lvlPos             = Vector2i(262, 51),
  hpBarPos           = Vector2i(71, 116),
  hpBarWidth         = 96,
  hpBarHeight        = 16,
  hpBarFg            = Color(0.0, 0.8, 0),
  hpBarBg            = Color.white,
  hpTextColor        = Color.black,
  xpBarPos           = Vector2i(103, 160),
  xpBarWidth         = 96,
  xpBarHeight        = 16,
  xpBarFg            = Color(0.8, 0.8, 0),
  xpBarBg            = Color.white,
  xpTextColor        = Color.black,
  attributesPos      = Vector2i(83, 211),
  attributesSep      = 32,
  attributeBarWidth  = 96,
  attributeBarHeight = 12,
  attributeBarFg     = Color(0.0, 0.8, 0),
  attributeBarBg     = Color.white,
  attributeTextColor = Color.black,
  combatStatsPos     = Vector2i(266, 278),
  combatStatsSep     = 32,
  equipmentPos       = Vector2i(376, 343),
  equipmentStatsSep  = 32,
  talentsPos         = Vector2i(376, 117),
  talentsSep  = 32,
}

/// displays info about a character's stats
class CharacterSheet {
  this(Vector2i topLeft, Battler battler) {
    _topLeft = topLeft;
    _bgTexture = getTexture(textureName);
    _character = battler.character;
    _sprite = battler.sprite;
    makeAttributeBars;
    makeXpAndHpBars(battler.hp);
  }

  this(Vector2i topLeft, Character character) {
    _topLeft = topLeft;
    _bgTexture = getTexture(textureName);
    _character = character;
    _sprite = new Sprite(character.spriteName);
    makeAttributeBars;
    makeXpAndHpBars(_character.maxHp);
  }

  void handleInput(InputManager input) {
  }

  void draw() {
    _bgTexture.drawTopLeft(_topLeft);
    foreach(bar ; _progressBars) {
      bar.draw();
    }
    _sprite.draw(_topLeft + spritePos);
    _nameFont.draw(_character.name, _topLeft + namePos);
    _levelFont.draw(to!string(_character.level), _topLeft + lvlPos);
  }

  private:
  Texture _bgTexture;
  Sprite _sprite;
  Character _character;
  ProgressBar!int[] _progressBars;
  Vector2i _topLeft;

  void makeAttributeBars() {
    Rect2i area = Rect2i(_topLeft + attributesPos, attributeBarWidth, attributeBarHeight);
    foreach(attribute ; Attribute.strength .. Attribute.max) {
      auto val = _character.attributes[attribute];
      auto maxVal = AttributeCaps[attribute];
      _progressBars ~= new ProgressBar!int(area, val, maxVal, attributeBarFg, attributeBarBg, attributeTextColor);
      area.y += attributesSep;
    }
  }

  void makeXpAndHpBars(int currentHp) {
    auto area = Rect2i(_topLeft + hpBarPos, hpBarWidth, hpBarHeight);
    _progressBars ~= new ProgressBar!int(area, currentHp, _character.maxHp, hpBarFg, hpBarBg, hpTextColor);
    area = Rect2i(_topLeft + xpBarPos, xpBarWidth, xpBarHeight);
    _progressBars ~= new ProgressBar!int(area, currentHp, _character.xpLimit, xpBarFg, xpBarBg, xpTextColor);
  }

  static Font _nameFont, _levelFont;
  static this() {
    _nameFont  = getFont("characterSheetName");
    _levelFont = getFont("characterSheetLevel");
  }
}
