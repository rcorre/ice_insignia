module map.tilemap;

import map.tile;
import geometry.all;
import util.math;

class TileMap {
  this(Tile[][] tiles, int tileWidth, int tileHeight) {
    _tiles = tiles;
    _tileWidth = tileWidth;
    _tileHeight = tileHeight;
    debug {
      import std.stdio;
      writeln(tileWidth, tileHeight);
    }
  }

  @property {
    int numRows() { return cast(int) _tiles.length; }
    int numCols() { return cast(int) _tiles[0].length; }

    int height() { return _tileHeight * numRows; }
    int width()  { return _tileWidth * numCols; }
  }

  Tile tileAt(int row, int col) {
    assert(row >= 0 && col >= 0 && row < numRows && col < numCols);
    return _tiles[row][col];
  }

  void draw(Vector2i topLeft, Rect2i cameraRect) {
    int firstCol = cameraRect.x / _tileWidth;
    int firstRow = cameraRect.y / _tileHeight;
    int lastRow = firstRow + cameraRect.height / _tileHeight;
    int lastCol = firstCol + cameraRect.width  / _tileWidth;
    Vector2i offset = -Vector2i(cameraRect.x % _tileWidth, cameraRect.y % _tileHeight);
    Vector2i pos = topLeft + offset + Vector2i(_tileWidth, _tileHeight) / 2;

    foreach(row ; _tiles[firstRow .. lastRow]) {
      foreach(tile ; row[firstCol .. lastCol]) {
        tile.draw(pos);
        pos.x += _tileWidth;
      }
      pos.x = topLeft.x + offset.x + _tileWidth / 2;
      pos.y += _tileHeight;
    }
  }

  private:
    Tile[][] _tiles;
    int _tileWidth, _tileHeight;
}
