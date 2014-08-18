module tilemap.tile;

import std.string : format;
import util.jsonizer;
import model.battler;
import graphics.sprite;
import geometry.vector;

class Tile {
  this(int row, int col, Sprite terrainSprite, Sprite featureSprite, int moveCost = 1) {
    _row = row;
    _col = col;
    _terrainSprite = terrainSprite;
    _featureSprite = featureSprite;
    _moveCost = moveCost;
  }

  @property {
    int row() { return _row; }
    int col() { return _col; }
    int moveCost() { return _moveCost; }

    Battler battler() { return _battler; }
    void battler(Battler b) {
      assert(_battler is null || b is null, format("tile at %d,%d is already occupied", row, col));
      _battler = b;
    }
  }

  void draw(Vector2i pos) {
    if (_terrainSprite) {
      _terrainSprite.draw(pos);
    }
    if (_featureSprite) {
      _featureSprite.draw(pos);
    }
  }

  private:
    int _row, _col;
    int _moveCost;
    Sprite _terrainSprite, _featureSprite;
    Battler _battler;
}
