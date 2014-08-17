module tilemap.tile;

import std.string : format;
import util.jsonizer;
import model.character;
import graphics.sprite;
import geometry.vector;

class Tile {
  this(int row, int col, Sprite terrainSprite, Sprite featureSprite) {
    _row = row;
    _col = col;
    _terrainSprite = terrainSprite;
    _featureSprite = featureSprite;
  }

  @property {
    int row() { return _row; }
    int col() { return _col; }

    Character character() { return _character; }
    void character(Character c) {
      assert(_character is null, format("tile at %d,%d is already occupied", row, col));
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
    Sprite _terrainSprite, _featureSprite;
    Character _character;
}
