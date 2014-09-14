module tilemap.tileobject;

import graphics.all;
import geometry.all;
import model.item;
import tilemap.tile;

abstract class TileObject {
  this(Tile tile, Vector2i pos, Sprite sprite) {
    _tile   = tile;
    _sprite = sprite;
    _pos    = pos;
  }

  @property {
    Tile tile()     { return _tile; }
    Sprite sprite() { return _sprite; }
    Vector2i pos()  { return _pos; }

    bool impassable();
  }

  void draw(Vector2i offset) {
    sprite.draw(pos - offset);
  }

  private:
  Tile _tile;
  Sprite _sprite;
  Vector2i _pos;
}

class Chest : TileObject {
  this(Tile tile, Vector2i pos, Sprite sprite, Item item) {
    super(tile, pos, sprite);
  }

  @property auto item() { return _item; }
  @property override bool impassable() { return false; }

  private:
  Item _item;
}

class Wall : TileObject {
  this(Tile tile, Vector2i pos, Sprite sprite, int hp) {
    super(tile, pos, sprite);
  }

  @property auto hp() { return _hp; }
  @property override bool impassable() { return true; }

  void damage(int amount) {
    assert(0, "TODO");
  }

  private:
  int _hp;
}

class Door : TileObject {
  this(Tile tile, Vector2i pos, Sprite sprite) {
    super(tile, pos, sprite);
  }

  @property override bool impassable() { return true; }
}
