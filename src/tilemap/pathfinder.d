module tilemap.pathfinder;

import std.algorithm;
import std.range;
import std.array;
import std.math : abs;
import tilemap.tilemap;
import tilemap.tile;
import model.battler;

class PathFinder {
  private enum noParent = -1;

  this(TileMap map, Tile start, Battler battler) {
    _map = map;
    _start = start;
    _battler = battler;
    _moveRange = _battler.move;
    djikstra();
    foreach(i ; iota(0, numTiles)) {
      if (_dist[i] <= _moveRange) {
        auto tile = idxToTile(i);
        if (tile.battler is null) {
          _tilesInRange ~= idxToTile(i);
        }
      }
    }
  }

  @property Tile[] tilesInRange() { return _tilesInRange; }

  /// return path to end, or null if end is not reachable
  Tile[] pathTo(Tile end) {
    int idx = tileToIdx(end);
    if (end.battler !is null || _dist[idx] > _moveRange) {
      return null;
    }
    int startIdx = tileToIdx(_start);
    Tile[] tiles;
    while (idx != startIdx) {
      tiles ~= idxToTile(idx);
      idx = _prev[idx];
    }
    tiles ~= _start;
    return tiles.reverse;
  }

  /// return best path towards tile, clamped at moveRange
  Tile[] pathToward(Tile end) {
    auto fullPath = aStar(_start, end);
    if (!fullPath) { return null; } // not reachable

    auto path = [_start];
    int cost = 0;
    // skip start as it will be seen as occupied
    foreach(tile ; fullPath.drop(1)) {
      cost += tile.moveCost(_battler);
      if (cost <= _moveRange && tile.battler is null) {
        path ~= tile;
      }
    }
    return path;
  }

  private:
  TileMap _map;
  Tile _start;
  int _moveRange;
  int[] _dist;
  int[] _prev;
  Tile[] _tilesInRange;
  Battler _battler;

  int tileToIdx(Tile tile) {
    return tile.row * _map.numCols + tile.col;
  }

  Tile idxToTile(int idx) {
    return _map.tileAt(idx / _map.numCols, idx % _map.numCols);
  }

  int idxToRow(int idx) {
    return idx / _map.numCols;
  }

  int idxToCol(int idx) {
    return idx % _map.numCols;
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
        auto alt = _dist[u] + tile.moveCost(_battler);
        if (alt < _dist[v]) {
          _dist[v] = alt;
          _prev[v] = u;
          queue ~= v; // place v back in queue with new dist
        }
      }
    }
  }

  /// use to find a route between a single pair of tiles
  Tile[] aStar(Tile startTile, Tile endTile) {
    int start = tileToIdx(startTile);
    int goal  = tileToIdx(endTile);

    int[] closedset;
    int[] openset = [start];
    int[int] parent;
    int[] gscore = new int[numTiles];
    int[] fscore = new int[numTiles];

    gscore[start] = 0;
    fscore[start] = 0;

    while(!openset.empty) {
      openset.sort!((a,b) => fscore[a] < fscore[b]);
      auto current = openset.front;

      if (current == goal) {
        return reconstructPath(parent, goal);
      }

      openset.popFront;
      closedset ~= current;

      foreach(tile ; _map.neighbors(idxToTile(current))) {
        auto neighbor = tileToIdx(tile);
        if (closedset.canFind(neighbor)) { continue; }
        auto tentative_gscore = gscore[current] + tile.moveCost(_battler);

        if (!openset.canFind(neighbor) || tentative_gscore < gscore[neighbor]) {
          parent[neighbor] = current;
          gscore[neighbor] = tentative_gscore;
          fscore[neighbor] = gscore[neighbor] + manhattan(neighbor, goal);
          if (!openset.canFind(neighbor)) {
            openset ~= neighbor;
          }
        }
      }
    }

    return null;
  }

  Tile[] reconstructPath(int[int] parents, int current) {
    Tile[] path;
    if (current in parents) {
      path = reconstructPath(parents, parents[current]);
      return path ~ idxToTile(current);
    }
    return [idxToTile(current)];
  }

  int manhattan(int start, int end) {
    return abs(idxToRow(start) - idxToRow(end)) + abs(idxToCol(start) - idxToCol(end));
  }
}
