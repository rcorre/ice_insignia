module tilemap.object;

import std.algorithm;
import graphics.all;
import geometry.all;
import model.item;
import model.attackable;
import model.battler;
import tilemap.tile;
import util.sound;

abstract class TileObject {
  this(Sprite sprite, int row, int col) {
    _sprite = sprite;
    _row = row;
    _col = col;
  }

  @property {
    Sprite sprite() { return _sprite; }

    bool impassable();
    string name();

    int row() { return _row; }
    int col() { return _col; }
  }

  void draw(Vector2i pos) {
    sprite.draw(pos);
  }

  protected:
  Sprite _sprite;
  private:
  int _row, _col;
}

class Chest : TileObject {
  this(Sprite sprite, Item item, int row, int col) {
    _item = item;
    super(sprite, row, col);
  }

  @property {
    auto item() { return _item; }
    override bool impassable() { return false; }
    override string name() { return "Chest"; }
  }

  private:
  Item _item;
}

class Wall : TileObject, Attackable {
  this(Sprite sprite, int hp, int row, int col) {
    super(sprite, row, col);
    _maxHp = hp;
    _hp = hp;
  }

  @property {
    auto hp() { return _hp; }
    auto maxHp() { return _maxHp; }
    bool alive() { return _hp > 0; }
    override {
      bool impassable() { return true; }
      string name() { return "Wall"; }
      int row() { return super.row; }
      int col() { return super.col; }
    }
  }

  void dealDamage(int amount) {
    _hp = max(hp - amount, 0);
    sprite.flash(damageFlashTime, damageFlashColor);
    playSound("hit");
  }

  private:
  int _hp, _maxHp;
  enum {
    damageFlashTime = 0.22,/// duration of flash used to indicate damage
    fadeTime = 0.5,/// duration of flash used to indicate damage
    damageFlashColor = Color(0.5, 0, 0),
    fadeSpectrum = [Color.red, Color.clear],
  }
}

class Door : TileObject {
  this(Sprite sprite, int row, int col) {
    super(sprite, row, col);
  }

  @property {
    override bool impassable() { return true; }
    override string name() { return "Door"; }
  }
}

class Banner : TileObject {
  this(BattleTeam team, int row, int col) {
    auto sprite = new Sprite(team == BattleTeam.ally ? "bannerBlue" : "bannerRed");
    this.team = team;
    super(sprite, row, col);
  }

  BattleTeam team;

  @property {
    override bool impassable() { return false; }
    override string name() { return "Banner"; }
  }
}

class Pedestal : TileObject {
  this(Sprite sprite, int row, int col, bool hasRelic) {
    super(sprite, row, col);
  }

  @property {
    override bool impassable() { return false; }
    override string name() { return _hasRelic ? "Relic" : "Pedestal"; }
  }

  private bool _hasRelic;
}
