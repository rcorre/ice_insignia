module model.battler;

import std.range;
import std.algorithm;
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
  hpTransitionRate = 20,
  xpTransitionRate = 80,
}

enum BattleTeam {
  ally,
  enemy,
  neutral
}

class Battler {
  alias character this;

  this(Character c, int row, int col, Vector2i pos, BattleTeam team, string aiType = "agressive") {
    character = c;
    _row = row;
    _col = col;
    _pos = pos;
    _sprite = new CharacterSprite(c.model, team);
    this.team = team;
    _hp = c.maxHp;
    _aiType = aiType;
  }

  @property {
    Sprite sprite() { return _sprite; }
    ref int row() { return _row; }
    ref int col() { return _col; }
    ref Vector2i pos() { return _pos; }
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
    bool isXpTransitioning() { return _infoBox.xpBar.isTransitioning; }

    bool canPickLocks() {
      return talents.canFind!(x => x.key == "lockpicking") &&
        items[].canFind!(x => x !is null && x.name == "Lockpick");
    }

    bool canOpenDoor() {
      return items[].canFind!(x => x !is null && x.name == "Door Key") || canPickLocks;
    }

    bool canOpenChest() {
      return items[].canFind!(x => x !is null && x.name == "Chest Key") || canPickLocks;
    }

    /// return true if item totally consumed
    bool useItem(Item item) {
      auto idx = items[].countUntil(item);
      assert(idx >= 0, "trying to use item " ~ item.name ~ " but it is not in inventory");
      if (--items[idx].uses <= 0) {
        items[idx] = null;
        if (idx == 0) { // was equipped weapon
          equipNextWeapon();
        }
        return true;
      }
      return false;
    }

    string aiType() {return _aiType; }
    Item itemToDrop() {
      auto r = items[].find!"a !is null && a.drop";
      return r.empty ? null : r.front;
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
  }

  void drawInfoBox() {
    if (_infoBox) {
      _infoBox.draw();
    }
  }

  void showInfoBox(Vector2i pos) {
    if (_infoBox is null) {
      _infoBox = new BattlerInfoBox(pos, this);
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
      _infoBox.healthBar.transition(_hp, _hp - amount, hpTransitionRate);
    }
    _hp -= amount;
    if (_hp <= 0) {
      _sprite.fade(fadeTime, fadeSpectrum);
    }
  }

  bool awardXp(int amount, out AttributeSet bonuses, out int leftover) {
    assert(_infoBox, "infobox not shown to award xp");
    _infoBox.xpBar.transition(xp, min(xp + amount, xpLimit), xpTransitionRate);
    return character.awardXp(amount, bonuses, leftover);
  }

  bool canAttack(Battler other) {
    auto dist = abs(row - other.row) + abs(col - other.col);
    return other.alive && dist >= character.equippedWeapon.minRange && dist <= character.equippedWeapon.maxRange;
  }

  auto stealableItems() {
    return items[].drop(1).filter!(x => x !is null); // cant steal equipped item
  }

  bool canStealFrom(Battler other) {
    auto dist = abs(row - other.row) + abs(col - other.col);
    auto hasPickpocket = talents.canFind!(x => x.key == "theft");
    bool hasSpace = items[].canFind!(x => x is null);
    return hasPickpocket && dist == 1 && !other.stealableItems.empty;
  }

  const BattleTeam team;
  Character character;

  private:
  CharacterSprite _sprite;
  int _row, _col;
  Vector2i _pos;
  int _hp;
  bool _moved;
  BattlerInfoBox _infoBox;
  string _aiType;
}
