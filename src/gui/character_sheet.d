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
  spritePos          = Vector2i(80, 72),
  namePos            = Vector2i(112, 60),
  lvlPos             = Vector2i(362, 60),
  hpBarPos           = Vector2i(109, 130),
  hpBarWidth         = 96,
  hpBarHeight        = 16,
  hpBarFg            = Color(0.0, 0.8, 0),
  hpBarBg            = Color.white,
  hpTextColor        = Color.black,
  xpBarPos           = Vector2i(109, 160),
  xpBarWidth         = 96,
  xpBarHeight        = 16,
  xpBarFg            = Color(0.8, 0.8, 0),
  xpBarBg            = Color.white,
  xpTextColor        = Color.black,
  attributesPos      = Vector2i(118, 227),
  attributesSep      = 32,
  attributeBarWidth  = 96,
  attributeBarHeight = 12,
  attributeBarFg     = Color(0.0, 0.8, 0),
  attributeBarBg     = Color.white,
  attributeTextColor = Color.black,
  combatStatsPos     = Vector2i(606, 398),
  combatStatsSep     = 32,
  equipmentPos       = Vector2i(515, 155),
  equipmentStatsSep  = 32,
}

/// displays info about a character's stats
class CharacterSheet {
  this(Battler battler) {
    _bgTexture = getTexture(textureName);
    _battler = battler;
    makeAttributeBars;
    makeXpAndHpBars;
  }

  void handleInput(InputManager input) {
  }

  void draw() {
    _bgTexture.draw(Vector2i(Settings.screenW / 2, Settings.screenH / 2));
    foreach(bar ; _progressBars) {
      bar.draw();
    }
    _battler.sprite.draw(spritePos);
    _nameFont.draw(_battler.name, namePos);
    _levelFont.draw(to!string(_battler.level), lvlPos);
  }

  private:
  Texture _bgTexture;
  Battler _battler;
  ProgressBar!int[] _progressBars;

  void makeAttributeBars() {
    Rect2i area = Rect2i(attributesPos, attributeBarWidth, attributeBarHeight);
    foreach(attribute ; Attribute.strength .. Attribute.max) {
      auto val = _battler.attributes[attribute];
      auto maxVal = AttributeCaps[attribute];
      _progressBars ~= new ProgressBar!int(area, val, maxVal, attributeBarFg, attributeBarBg, attributeTextColor);
      area.y += attributesSep;
    }
  }

  void makeXpAndHpBars() {
    auto area = Rect2i(hpBarPos, hpBarWidth, hpBarHeight);
    _progressBars ~= new ProgressBar!int(area, _battler.hp, _battler.maxHp, hpBarFg, hpBarBg, hpTextColor);
    area = Rect2i(xpBarPos, xpBarWidth, xpBarHeight);
    _progressBars ~= new ProgressBar!int(area, _battler.xp, _battler.xpLimit, xpBarFg, xpBarBg, xpTextColor);
  }

  static Font _nameFont, _levelFont;
  static this() {
    _nameFont  = getFont("characterSheetName");
    _levelFont = getFont("characterSheetLevel");
  }
}
