module map.tile;

import std.string : format;
import util.jsonizer;
import model.character;
import graphics.sprite;
import geometry.vector;

class Tile {
  this(int row, int col, Sprite sprite) {
    _row = row;
    _col = col;
    _sprite = sprite;
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
    _sprite.draw(pos);
  }

  private:
    int _row, _col;
    Sprite _sprite;
    Character _character;
}
