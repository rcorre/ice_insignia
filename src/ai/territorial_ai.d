module ai.territorial_ai;

import std.algorithm;
import std.range;
import std.math;
import ai.ai;
import model.battler;
import tilemap.all;

/// attack enemies that enter move range -- otherwise skip turn
class TerritorialAI : AI {
  this(Battler self, TileMap map, Battler[] enemies, Battler[] allies) {
    super(self, map, enemies, allies);
  }

  override @property {
    Tile[] moveRequest() {
      if (attackRequest !is null) {
        return null;  // don't move if target in range
      }

      // find closest enemy
      int distTo(Battler other) { return abs(_self.row - other.row) + abs(_self.col - other.col); }
      // find nearest living target
      auto target = _enemies.sort!((a,b) => distTo(a) < distTo(b)).find!"a.alive".front;
      auto tiles = _map.neighbors(_map.tileAt(target.row, target.col));

      foreach(tile ; tiles) {
        auto path = _pathFinder.pathTo(tile);
        if (path) {
          return path; // return path up to but not including target's tile
        }
      }
      return null; // no enemy in move range
    }

    Battler attackRequest() {
      auto result = _enemies.find!(x => _self.canAttack(x));
      return result.empty ? null : result.front;
    }
  }
}
