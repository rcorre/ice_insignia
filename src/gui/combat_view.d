module gui.combat_view;

import std.string : format;
import std.algorithm : reduce;
import geometry.all;
import graphics.all;
import state.combat_calc;

private enum {
  separatorWidth = 150 /// distance between attack and counter info
}

class CombatView {
  this(Vector2i pos, CombatPrediction attack, CombatPrediction counter) {
    _attackInfo = [
      attack.attacker.name,
      attack.attacker.equippedWeapon.name,
      format("Damage : %d x%d", attack.damage, attack.doubleHit ? 2 : 1),
      format("Hit    : %d", attack.hit),
      format("Crit   : %d", attack.crit)
    ];
    _counterInfo = [
      counter.attacker.name,
      counter.attacker.equippedWeapon.name,
      format("Damage : %d x%d", counter.damage, counter.doubleHit ? 2 : 1),
      format("Hit    : %d", counter.hit),
      format("Crit   : %d", counter.crit)
    ];
    auto width  = separatorWidth + reduce!((total, text) => max(total, _font.widthOf(text)))(0, _attackInfo);
    auto height = reduce!((total, text) => total + _font.heightOf(text))(0, _attackInfo);
    _area = Rect2i(pos.x, pos.y, width, height);
  }

  void draw() {
    _area.drawFilled;
    _font.draw(_attackInfo, _area.topLeft);
    _font.draw(_counterInfo, _area.topLeft + Vector2i.UnitX * separatorWidth);
  }

  private:
  Rect2i _area;
  string[] _attackInfo, _counterInfo;
  static Font _font ;

  static this() {
    _font = getFont("combat_info_font");
  }
}
