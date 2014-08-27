module ai.agressive_ai;

import std.algorithm;
import std.range;
import std.math;
import ai.ai;
import ai.territorial_ai;
import model.battler;
import tilemap.all;

/// move towards closest opponent regardless of how far away they are
class AgressiveAI : TerritorialAI {
  this(Battler self, TileMap map, Battler[] enemies, Battler[] allies) {
    super(self, map, enemies, allies);
  }

  override @property {
    Tile[] moveRequest() {
      if (attackRequest !is null) {
        return null;  // don't move if target in range
      }
      if (super.moveRequest) { // if enemy in territory, move to it
        return super.moveRequest;
      }

      // find closest enemy
      int distTo(Battler other) { return abs(_self.row - other.row) + abs(_self.col - other.col); }
      // find nearest living target
      auto target = _enemies.sort!((a,b) => distTo(a) < distTo(b)).find!"a.alive".front;
      auto tiles = _map.neighbors(_map.tileAt(target.row, target.col));
      // route towards nearest enemy
      foreach(tile ; tiles) {
        auto path = _pathFinder.pathToward(tile);
        if (path) {
          return path; // return path up to but not including target's tile
        }
      }
      return null;
    }
  }
}
