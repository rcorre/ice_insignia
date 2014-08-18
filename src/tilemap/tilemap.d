module tilemap.tilemap;

import allegro;
import tilemap.tile;
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
    int numTiles() { return numRows * numCols; }

    int height() { return _tileHeight * numRows; }
    int width()  { return _tileWidth * numCols; }

    int tileWidth() { return _tileWidth; }
    int tileHeight() { return _tileHeight; }

    Rect2i bounds() { return Rect2i(0, 0, width, height); }
  }

  Vector2i tileToPos(Tile tile) {
    return tileCoordToPos(tile.row, tile.col);
  }

  Vector2i tileCoordToPos(int row, int col) {
    return Vector2i(col * _tileWidth, row * _tileHeight) + Vector2i(_tileWidth, _tileHeight) / 2;
  }

  Tile tileAtPos(Vector2i pos) {
    int row = pos.y / _tileHeight;
    int col = pos.x / _tileWidth;
    if (row < 0 || col < 0 || row >= numRows || col >= numCols) {
      return null;
    }
    return _tiles[row][col];
  }

  int rowAt(Vector2i pos) {
    return pos.y / _tileHeight;
  }

  int colAt(Vector2i pos) {
    return pos.x / _tileWidth;
  }

  Tile tileAt(int row, int col) {
    assert(row >= 0 && col >= 0 && row < numRows && col < numCols);
    return _tiles[row][col];
  }

  Tile[] neighbors(Tile tile) {
    Tile[] list;
    int row = tile.row;
    int col = tile.col;
    if (row > 0)           { list ~= _tiles[row - 1][col]; }
    if (row < numRows - 1) { list ~= _tiles[row + 1][col]; }
    if (col > 0)           { list ~= _tiles[row][col - 1]; }
    if (col < numCols - 1) { list ~= _tiles[row][col + 1]; }
    return list;
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
