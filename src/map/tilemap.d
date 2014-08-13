module map.tilemap;

import allegro;
import map.tile;
import geometry.all;
import util.math;

class TileMap {
  this(Tile[][] tiles, int tileWidth, int tileHeight) {
    _tiles = tiles;
    _tileWidth = tileWidth;
    _tileHeight = tileHeight;
  }

  @property {
    int numRows() { return cast(int) _tiles.length; }
    int numCols() { return cast(int) _tiles[0].length; }

    int height() { return _tileHeight * numRows; }
    int width()  { return _tileWidth * numCols; }

    Rect2i bounds() { return Rect2i(0, 0, width, height); }
  }

  Tile tileAt(int row, int col) {
    assert(row >= 0 && col >= 0 && row < numRows && col < numCols);
    return _tiles[row][col];
  }

  void draw(Vector2i topLeft, Rect2i cameraRect) {
    int firstCol = cameraRect.x / _tileWidth;
    int firstRow = cameraRect.y / _tileHeight;
    int lastRow = clamp(firstRow + cameraRect.height / _tileHeight + 2, 0, numRows);
    int lastCol = clamp(firstCol + cameraRect.width  / _tileWidth + 2, 0, numCols);
    Vector2i offset = -Vector2i(cameraRect.x % _tileWidth, cameraRect.y % _tileHeight);
    Vector2i pos = topLeft + offset + Vector2i(_tileWidth, _tileHeight) / 2;

    al_hold_bitmap_drawing(true);
    foreach(row ; _tiles[firstRow .. lastRow]) {
      foreach(tile ; row[firstCol .. lastCol]) {
        tile.draw(pos);
        pos.x += _tileWidth;
      }
      pos.x = topLeft.x + offset.x + _tileWidth / 2;
      pos.y += _tileHeight;
    }
    al_hold_bitmap_drawing(false);
  }

  private:
    Tile[][] _tiles;
    int _tileWidth, _tileHeight;
}
