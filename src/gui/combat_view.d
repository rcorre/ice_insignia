module gui.combat_view;

import std.string : format;
import geometry.all;
import graphics.all;
import state.combat_calc;

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
  }

  void draw() {
    _font.draw(_attackInfo, _pos);
    _font.draw(_counterInfo, _pos + Vector2i.UnitX * 150);
  }

  private:
  Vector2i _pos;
  string[] _attackInfo, _counterInfo;
  static Font _font ;

  static this() {
    _font = getFont("combat_info_font");
  }
}
