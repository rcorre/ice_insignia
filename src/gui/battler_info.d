module gui.battler_info;

import graphics.all;
import geometry.all;
import gui.progress_bar;
import model.battler;
import tilemap.object;

private enum {
  textureName     = "battler_info",
  fontName        = "battler_info_font",
  healthFg        = Color(0.0, 1.0, 0, 0.8),
  healthBg        = Color(0.5, 0.5, 0.5, 0.8),
  xpFg            = Color(0.1, 0.2, 0.8, 0.8),
  xpBg            = Color(0.5, 0.5, 0.5, 0.8),
  spriteOffset    = Vector2i(25, 25),
  nameOffset      = Vector2i(50, 7),
  healthBarOffset = Vector2i(49, 25),
  healthBarSize   = Vector2i(60, 10),
  xpBarOffset     = Vector2i(49, 30 + healthBarSize.y),
  xpBarSize       = Vector2i(60, 8),
}

/// shows name and health bar
class BattlerInfoBox {
  this(Vector2i pos, Battler b) {
    _name = b.name;
    _area = Rect2i(pos, width, height);
    auto healthArea = Rect2i(pos + healthBarOffset, healthBarSize);
    _healthBar = new ProgressBar!int(healthArea, b.hp, b.maxHp, healthFg, healthBg);
    auto xpArea = Rect2i(pos + xpBarOffset, xpBarSize);
    _xpBar = new ProgressBar!int(xpArea, b.xp, b.xpLimit, xpFg, xpBg);
    _sprite = new CharacterSprite(b.model, b.team);
  }

  this(Vector2i pos, Wall wall) {
    _name = wall.name;
    _area = Rect2i(pos, width, height);
    auto healthArea = Rect2i(pos + healthBarOffset, healthBarSize);
    _healthBar = new ProgressBar!int(healthArea, wall.hp, wall.maxHp, healthFg, healthBg);
    _sprite = wall.sprite;
  }

  @property {
    static {
      int width() { return _texture.width; }
      int height() { return _texture.height; }
    }
    auto healthBar() { return _healthBar; }
    auto xpBar() { return _xpBar; }
  }

  void update(float time) {
    _healthBar.update(time);
    if (_xpBar !is null) {
      _xpBar.update(time);
    }
  }

  void draw() {
    _texture.draw(_area.center);
    _sprite.draw(_area.topLeft + spriteOffset);
    _font.draw(_name, _area.topLeft + nameOffset);
    _healthBar.draw();
    if (_xpBar !is null) {
      _xpBar.draw();
    }
  }

  private:
  string _name;
  ProgressBar!int _healthBar, _xpBar;
  Rect2i _area;
  Sprite _sprite;

  static Font _font;
  static Texture _texture;
  static this() {
    _font = getFont(fontName);
    _texture = getTexture(textureName);
  }
}
