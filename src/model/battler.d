module model.battler;

import std.algorithm : max;
import std.math : abs;
import allegro;
import geometry.all;
import graphics.all;
import util.math;
import gui.battler_info;
import model.character;
import model.item;

private enum {
  movedTint = Color(0.6,0.6,0.6,0.9),
  damageFlashTime = 0.22,/// duration of flash used to indicate damage
  fadeTime = 0.5,/// duration of flash used to indicate damage
  damageFlashColor = Color(0.5, 0, 0),
  fadeSpectrum = [Color.red, Color.clear],
  hpTransitionTime = 1
}

enum BattleTeam {
  ally,
  enemy,
  neutral
}

class Battler {
  //alias character this;

  this(Character c, int row, int col, Vector2i pos, Sprite sprite, BattleTeam team, string aiType = "agressive") {
    _character = c;
    _row = row;
    _col = col;
    _pos = pos;
    _sprite = sprite;
    this.team = team;
    _hp = c.maxHp;
    _aiType = aiType;
  }

  @property {
    Sprite sprite() { return _sprite; }
    ref int row() { return _row; }
    ref int col() { return _col; }
    ref Vector2i pos() { return _pos; }
    //Character character() { return _character; }
    int hp() { return _hp; }

    bool alive() { return _hp > 0; }

    bool moved() { return _moved || !alive; }
    void moved(bool val) {
      if (alive) {
        _moved = val;
        // shade sprite if moved
        _sprite.tint = val ? movedTint : Color.white;
      }
    }

    BattlerInfoBox infoBox() { return _infoBox; }
    bool isHpTransitioning() { return _infoBox.healthBar.isTransitioning; }

    string aiType() {return _aiType; }

    // HACK due to alias this bug
    auto equippedWeapon() {
      return _character.equippedWeapon;
    }
    void equippedWeapon(Item item) {
      _character.equippedWeapon = item;
    }
  }

  void update(float time) {
    _sprite.update(time);
    if (_infoBox) {
      _infoBox.update(time);
    }
  }

  void draw(Vector2i offset) {
    _sprite.draw(pos - offset);
    if (_infoBox) {
      _infoBox.draw();
    }
  }

  void showInfoBox(Vector2i pos) {
    if (_infoBox is null) {
      _infoBox = new BattlerInfoBox(pos, _character.name, _hp, _character.maxHp);
    }
  }

  void hideInfoBox() {
    _infoBox = null;
  }

  void passTurn() {
    _moved = false;
  }

  void dealDamage(int amount) {
    amount = amount.clamp(0, _hp);
    if (amount > 0) {
      _sprite.flash(damageFlashTime, damageFlashColor);
      _infoBox.healthBar.transition(_hp, _hp - amount, hpTransitionTime);
    }
    _hp -= amount;
    if (_hp <= 0) {
      _sprite.fade(fadeTime, fadeSpectrum);
    }
  }

  bool canAttack(Battler other) {
    auto dist = abs(row - other.row) + abs(col - other.col);
    return other.alive && dist >= _character.equippedWeapon.minRange && dist <= _character.equippedWeapon.maxRange;
  }

  /// access an attribute by name
  auto opDispatch(string m)() {
    return mixin("_character." ~ m);
  }

  const BattleTeam team;

  private:
  Sprite _sprite;
  int _row, _col;
  Vector2i _pos;
  Character _character;
  int _hp;
  bool _moved;
  BattlerInfoBox _infoBox;
  string _aiType;
}
