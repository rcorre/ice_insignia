module ai.camper_ai;

import std.algorithm;
import std.range;
import std.math;
import ai.ai;
import ai.territorial_ai;
import model.battler;
import tilemap.all;

/// attack opponents in range, but don't move
class CamperAI : AI {
  this(Battler self, TileMap map, Battler[] enemies, Battler[] allies) {
    super(self, map, enemies, allies);
  }

  override @property {
    Tile[] moveRequest() {
      return null;
    }

    Battler attackRequest() {
      auto result = _enemies.find!(x => _self.canAttack(x));
      return result.empty ? null : result.front;
    }
  }
}
