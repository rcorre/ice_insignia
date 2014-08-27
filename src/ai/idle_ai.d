module ai.idle_ai;

import ai.ai;
import model.battler;
import tilemap.all;

/// AI that always passes turn
class IdleAI : AI {
  this(Battler self, TileMap map, Battler[] enemies, Battler[] allies) {
    super(self, map, enemies, allies);
  }
  override @property {
    Tile[] moveRequest() { return null; }
    Battler attackRequest() { return null; }
  }
}
