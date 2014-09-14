module tilemap.object;

import graphics.all;
import geometry.all;
import model.item;
import tilemap.tile;

abstract class TileObject {
  this(Sprite sprite) {
    _sprite = sprite;
  }

  @property {
    Sprite sprite() { return _sprite; }

    bool impassable();
    string name();
  }

  void draw(Vector2i pos) {
    sprite.draw(pos);
  }

  private:
  Sprite _sprite;
}

class Chest : TileObject {
  this(Sprite sprite, Item item) {
    super(sprite);
  }

  @property {
    auto item() { return _item; }
    override bool impassable() { return false; }
    override string name() { return "Chest"; }
  }

  private:
  Item _item;
}

class Wall : TileObject {
  this(Sprite sprite, int hp) {
    super(sprite);
  }

  @property {
    auto hp() { return _hp; }
    override bool impassable() { return true; }
    override string name() { return "Wall"; }
  }

  void damage(int amount) {
    assert(0, "TODO");
  }

  private:
  int _hp;
}

class Door : TileObject {
  this(Sprite sprite) {
    super(sprite);
  }

  @property {
    override bool impassable() { return true; }
    override string name() { return "Door"; }
  }
}
