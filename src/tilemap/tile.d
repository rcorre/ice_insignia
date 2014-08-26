module tilemap.tile;

import std.string : format;
import util.jsonizer;
import model.battler;
import graphics.sprite;
import geometry.vector;

enum impasseCost = 500; /// represents an impassable tile

class Tile {
  this(int row, int col, Sprite terrainSprite, Sprite featureSprite, string name, int moveCost, int defense, int avoid) {
    _row = row;
    _col = col;
    _terrainSprite = terrainSprite;
    _featureSprite = featureSprite;
    _moveCost = moveCost;
    _defense = defense;
    _avoid = avoid;
    _name = name;
  }

  @property {
    string name() { return _name; }
    int row() { return _row; }
    int col() { return _col; }
    /// returns the move cost of the terrain, or impasseCost if tile is occupied
    int moveCost() {
      return (battler is null) ? _moveCost : impasseCost;
    }
    int defense() { return _defense; }
    int avoid() { return _avoid; }

    Battler battler() { 
      if (_battler && !_battler.alive) { _battler = null; } // remove battler if not alive
      return _battler; 
    }
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
    int _defense, _avoid;
    string _name;
    Sprite _terrainSprite, _featureSprite;
    Battler _battler;
}
