module gui.battler_info;

import graphics.all;
import geometry.all;
import gui.progress_bar;

private enum {
  width = 100,
  height = 40,
  bgColor = Color(0.5, 0, 0, 0.5),
  healthFg = Color(1.0, 1.0, 0, 0.8),
  healthBg = Color(0.5, 0.5, 0.5, 0.8),
}

/// shows name and health bar
class BattlerInfoBox {
  this(Vector2i pos, string name, int hp, int maxHp) {
    _area = Rect2i.CenteredAt(pos, width, height);
    _name = name;
    auto healthArea = Rect2i.CenteredAt(pos, 80, 12);
    _healthBar = new ProgressBar!int(healthArea, hp, maxHp, healthFg, healthBg);
  }

  @property auto healthBar() { return _healthBar; }

  void update(float time) {
    _healthBar.update(time);
  }

  void draw() {
    _area.drawFilled(bgColor);
    _font.draw(_name, _area.topLeft);
    _healthBar.draw();
  }

  private:
  Rect2i _area;
  string _name;
  ProgressBar!int _healthBar;

  static Font _font;
  static this() {
    _font = getFont("battler_info_font");
  }
}
