module ai.get_ai;

import ai.all;
import model.battler;
import tilemap.tilemap;

/// allies refer to the allies of the battler b
AI getAI(Battler b, TileMap map, Battler[] enemies, Battler[] allies) {
  switch(b.aiType) {
    case "agressive":
      return new AgressiveAI(b, map, enemies, allies);
    case "territorial":
      return new TerritorialAI(b, map, enemies, allies);
    case "camper":
      return new CamperAI(b, map, enemies, allies);
    default:
      return new IdleAI(b, map, enemies, allies);
  }
}
