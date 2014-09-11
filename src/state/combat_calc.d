module state.combat_calc;

import std.random : uniform;
import std.algorithm;
import std.array;
import util.math : clamp;
import model.battler;
import model.item;
import tilemap.tile;

private enum {
  // xp
  levelXpFactor  = 2f,   /// higher means less xp reward/penalty for difference in level
  baseXp         = 5f,   /// xp awarded for being in combat
  attackXpFactor = 3f, /// xp awarded per damage point dealt
  killXpBonus    = 40f,  /// xp awarded for a kill
  dodgeXp        = 10f,  /// xp awarded for a dodge
  lockpickXp     = 30f,  /// xp awarded for picking a lock
  stealXp        = 40f,  /// xp awarded for stealing

  // combat results
  triangleBonus = 1.2,
  trianglePenalty = 0.8,
}

CombatResult[] constructAttackSeries(CombatPrediction attack, CombatPrediction counter) {
  auto attacker = attack.attacker;
  auto defender = attack.defender;
  CombatResult[] attacks = [attack.resolve()];
  if (defender.canAttack(attacker)) {
    attacks ~= counter.resolve();
  }
  if (attack.doubleHit) {
    attacks ~= attack.resolve();
  }
  else if (defender.canAttack(attacker) && counter.doubleHit) {
    attacks ~= counter.resolve();
  }
  return attacks;
}

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
      if (triangleAdvantage) {
        dmg *= triangleBonus;
      }
      else if (triangleDisadvantage) {
        dmg *= trianglePenalty;
      }
      return max(0, dmg - def);
    }

    int hit() {
      int acc = attacker.equippedWeapon.hit + attacker.skill * 4;
      int avoid = defender.adjustedSpeed * 4 + defenderTerrain.avoid;
      if (triangleAdvantage) {
        acc *= triangleBonus;
      }
      else if (triangleDisadvantage) {
        acc *= trianglePenalty;
      }
      return clamp(acc - avoid, 0, 100);
    }

    int crit() {
      int crt = attacker.equippedWeapon.crit + attacker.luck * 2;
      int anti_crt = defender.luck * 2;
      if (triangleAdvantage) {
        crt *= 1.2;
      }
      else if (triangleDisadvantage) {
        crt *= 0.8;
      }
      return clamp(crt - anti_crt, 0, 100);
    }

    bool doubleHit() {
      return attacker.adjustedSpeed - defender.adjustedSpeed > 3;
    }

    bool triangleAdvantage() {
      return (attacker.equippedWeapon.type in advantageMap) &&
        (advantageMap[attacker.equippedWeapon.type] == defender.equippedWeapon.type);
    }

    bool triangleDisadvantage() {
      return (defender.equippedWeapon.type in advantageMap) &&
        (advantageMap[defender.equippedWeapon.type] == attacker.equippedWeapon.type);
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

  @property int xpAward() {
    auto player = (attacker.team == BattleTeam.ally) ? attacker : defender;
    auto enemy  = (attacker.team == BattleTeam.ally) ? defender : attacker;
    float levelFactor = cast(float) (enemy.level + levelXpFactor) / (player.level + levelXpFactor);
    if (player == attacker) {
      return cast(int) ((damageDealt * attackXpFactor + baseXp) * levelFactor);
    }
    else {
      auto dodgeBonus = hit ? 0 : dodgeXp;
      return cast(int) ((baseXp + dodgeBonus) * levelFactor);
    }
  }
}

/// deduce how much xp to award to player from a combat series
int playerXp(CombatResult[] series) {
  // TODO: check for kill
  auto xp = reduce!((a, b) => a + b.xpAward)(0, series);
  if (series.wouldKillEnemy) {
    auto attacker = series.front.attacker;
    auto defender = series.front.defender;
    auto player = (attacker.team == BattleTeam.ally) ? attacker : defender;
    auto enemy  = (attacker.team == BattleTeam.ally) ? defender : attacker;
    float levelFactor = cast(float) (enemy.level + levelXpFactor) / (player.level + levelXpFactor);
    xp += killXpBonus * levelFactor;
  }
  return xp;
}

private:
// speed after adjustment for weapon weight
int adjustedSpeed(Battler b) {
  int penalty = min(0, b.constitution  - b.equippedWeapon.weight);
  return b.speed + penalty;
}

bool wouldKillEnemy(CombatResult[] series) {
  auto first = series.front;
  auto enemy = first.attacker.team == BattleTeam.enemy ? first.attacker : first.defender;
  auto dmg = series.filter!(a => a.defender == enemy).map!"a.damageDealt".sum;
  return dmg >= enemy.hp;
}

enum advantageMap = [
  ItemType.sword : ItemType.axe,
  ItemType.axe   : ItemType.lance,
  ItemType.lance : ItemType.sword,

  ItemType.anima : ItemType.light,
  ItemType.light : ItemType.dark,
  ItemType.dark  : ItemType.anima,
];
