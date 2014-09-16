module tilemap.object;

import std.algorithm;
import graphics.all;
import geometry.all;
import model.item;
import model.attackable;
import tilemap.tile;

abstract class TileObject {
  this(Sprite sprite, int row, int col) {
    _sprite = sprite;
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

  private:
  Sprite _sprite;
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
  }

  @property {
    auto hp() { return _hp; }
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
  }

  private:
  int _hp;
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
