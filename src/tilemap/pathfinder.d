module tilemap.pathfinder;

import std.algorithm;
import std.range;
import std.container : RedBlackTree;
import tilemap.tilemap;
import tilemap.tile;

class PathFinder {
  enum {
    impasseCost = 500,
    noParent = -1
  }

  this(TileMap map, Tile start, int moveRange) {
    _map = map;
    _start = start;
    _moveRange = moveRange;
    djikstra();
    foreach(i ; iota(0, numTiles)) {
      if (_dist[i] <= moveRange) {
        _tilesInRange ~= idxToTile(i);
      }
    }
  }

  @property Tile[] tilesInRange() { return _tilesInRange; }

  Tile[] pathTo(Tile end) {
    int idx = tileToIdx(end);
    if (_dist[idx] > _moveRange) {
      return null;
    }
    int startIdx = tileToIdx(_start);
    Tile[] tiles;
    while (idx != startIdx) {
      tiles ~= idxToTile(idx);
      idx = _prev[idx];
    }
    return tiles.reverse;
  }

  private:
  TileMap _map;
  Tile _start;
  int _moveRange;
  int[] _dist;
  int[] _prev;
  Tile[] _tilesInRange;

  int tileToIdx(Tile tile) {
    return tile.row * _map.numCols + tile.col;
  }

  Tile idxToTile(int idx) {
    return _map.tileAt(idx / _map.numCols, idx % _map.numCols);
  }

  @property int numTiles() { return _map.numRows * _map.numCols; }

  void djikstra() {
    // setup
    _dist = new int[numTiles];
    _prev = new int[numTiles];
    _dist.fill(impasseCost);
    _prev.fill(noParent);
    _dist[tileToIdx(_start)] = 0;
    int[] queue;
    foreach(i ; iota(0, numTiles)) {
      queue ~= i;
    }

    // execution
    while(!queue.empty) {
      queue.sort!((a,b) => _dist[a] < _dist[b]);
      // pop node with lowest cost
      auto u = queue.front;
      queue = queue[1..$];

      foreach(tile ; _map.neighbors(idxToTile(u))) {
        auto v = tileToIdx(tile);
        auto alt = _dist[u] + tile.moveCost;
        if (alt < _dist[v]) {
          _dist[v] = alt;
          _prev[v] = u;
          queue ~= v; // place v back in queue with new dist
        }
      }
    }
  }
}
