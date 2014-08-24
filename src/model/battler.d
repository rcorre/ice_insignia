module model.battler;

import std.algorithm : max;
import std.math : abs;
import allegro;
import geometry.all;
import graphics.all;
import model.character;

private enum {
  movedTint = Color(0.6,0.6,0.6,0.9),
  damageFlashTime = 0.1,/// duration of flash used to indicate damage
}

enum BattleTeam {
  ally,
  enemy,
  neutral
}

class Battler {
  alias character this;

  this(Character c, int row, int col, Vector2i pos, Sprite sprite, BattleTeam team) {
    _character = c;
    _row = row;
    _col = col;
    _pos = pos;
    _sprite = sprite;
    this.team = team;
    _hp = c.maxHp;
  }

  @property {
    Sprite sprite() { return _sprite; }
    ref int row() { return _row; }
    ref int col() { return _col; }
    ref Vector2i pos() { return _pos; }
    Character character() { return _character; }
    int hp() { return _hp; }

    bool moved() { return _moved; }
    void moved(bool val) {
      _moved = val;
      // shade sprite if moved
      _sprite.tint = val ? movedTint : Color.white;
    }
  }

  void draw() {
    _sprite.draw(pos);
  }

  void passTurn() {
    _moved = false;
  }

  void dealDamage(int amount) {
    _sprite.flash(damageFlashTime, Color.black);
    _hp = max(_hp - amount, 0);
  }

  bool canAttack(Battler other) {
    auto dist = abs(row - other.row) + abs(col - other.col);
    return dist >= equippedWeapon.minRange && dist <= equippedWeapon.maxRange;
  }

  const BattleTeam team;

  private:
  Sprite _sprite;
  int _row, _col;
  Vector2i _pos;
  Character _character;
  int _hp;
  bool _moved;
}
