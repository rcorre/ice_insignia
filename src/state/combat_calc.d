module state.combat_calc;

import std.random : uniform;
import std.algorithm : max, min;
import util.math : clamp;
import model.battler;
import model.item;
import tilemap.tile;

class CombatPrediction {
  this(Battler attacker, Battler defender, Tile defenderTerrain) {
    this.attacker = attacker;
    this.defender = defender;
    this.defenderTerrain = defenderTerrain;
  }

  @property {
    int damage() {
      int dmg = attacker.equippedWeapon.damage + attacker.strength;
      int def = defender.defense + defenderTerrain.defense;
      return max(0, dmg - def);
    }

    int hit() {
      int acc = attacker.equippedWeapon.hit + attacker.skill * 4;
      int avoid = defender.adjustedSpeed * 4 + defenderTerrain.avoid;
      return clamp(acc - avoid, 0, 100);
    }

    int crit() {
      int crt = attacker.equippedWeapon.crit + attacker.luck * 2;
      int anti_crt = defender.luck * 2;
      return clamp(crt - anti_crt, 0, 100);
    }

    bool doubleHit() {
      return attacker.adjustedSpeed - defender.adjustedSpeed > 3;
    }
  }

  Battler attacker, defender;
  Tile defenderTerrain;
}

CombatResult resolve(CombatPrediction pred) {
  return new CombatResult(pred);
}

class CombatResult {
  this(CombatPrediction pred) {
    hit = pred.hit > uniform(0,100);
    if (hit) {
      critted = pred.crit > uniform(0, 100);
      damageDealt = critted ? pred.damage * 2 : pred.damage;
    }
    attacker = pred.attacker;
    defender = pred.defender;
  }

  const int damageDealt; /// amount of damage dealt by attack
  const bool hit;        /// true if hit connected, false if it missed
  const bool critted;    /// true if critical hit, false otherwise
  Battler attacker, defender;
}

private:
// speed after adjustment for weapon weight
int adjustedSpeed(Battler b) {
  int penalty = min(0, b.constitution  - b.equippedWeapon.weight);
  return b.speed + penalty;
}