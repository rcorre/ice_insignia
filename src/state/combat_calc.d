module state.combat_calc;

import std.random : uniform;
import std.math : pow;
import std.algorithm;
import std.array;
import util.math : clamp;
import model.battler;
import model.character;
import model.item;
import tilemap.tile;

private enum {
  // xp
  levelXpFactor  = 2f,   /// higher means less xp reward/penalty for difference in level
  baseXp         = 5f,   /// xp awarded for being in combat
  attackXpFactor = 3f, /// xp awarded per damage point dealt
  killXpBonus    = 40f,  /// xp awarded for a kill
  dodgeXp        = 10f,  /// xp awarded for a dodge

  lockpickXp          = 50f, /// xp for picking a lock at level 1
  lockpickLevelFactor = 0.8, /// lockpick xp factor for each level over 1
  stealXp             = 40f, /// xp awarded for stealing
  castXp              = 15f,

  // combat results
  triangleBonus = 1.2,
  trianglePenalty = 0.8,
  counterBonus = 0.4,     /// counterattack bonus for weapon with counter ability

  berserkDamageFactor = 1f, /// damage + (1 - hp / maxHp) * berserkDamageFactor
  precisionCritBonus = 15, /// constant added to crit
}

// speed after adjustment for weapon weight
int adjustedSpeed(Character c) {
  int penalty = min(0, c.constitution  - c.equippedWeapon.weight);
  return c.speed + penalty;
}

int attackDamage(Character c) {
  return c.equippedWeapon.damage + c.strength;
}

int attackDamage(Battler c) {
  return c.equippedWeapon.damage + c.strength + c.berserkDamageBonus;
}

int attackHit(Character c) {
  return c.equippedWeapon.hit + c.skill * 4;
}

int attackCrit(Character c) {
  float base = c.equippedWeapon.crit + (c.hasTalent("precision") ? precisionCritBonus : 0);
  return cast(int) (base * c.luck / 4f);
}

int avoid(Character c) {
  return c.adjustedSpeed * 4;
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
  this(Battler attacker, Battler defender, Tile defenderTerrain, bool isCounter) {
    this.attacker = attacker;
    this.defender = defender;
    this.defenderTerrain = defenderTerrain;
    this.isCounter = isCounter;
  }

  @property {
    int damage() {
      int dmg = attacker.attackDamage;
      auto effect = attacker.equippedWeapon.effect;
      int def = defender.defense + defenderTerrain.defense;
      if (effect == ItemEffect.antiArmor) {
        def /= 2;
      }
      if (triangleAdvantage) {
        dmg *= triangleBonus;
      }
      else if (triangleDisadvantage) {
        dmg *= trianglePenalty;
      }
      if (isCounter && effect == ItemEffect.counter) {
        dmg *= counterBonus;
      }
      return max(0, dmg - def);
    }

    int hit() {
      int acc = attacker.attackHit;
      int avoid = defender.avoid + defenderTerrain.avoid;
      if (triangleAdvantage) {
        acc *= triangleBonus;
      }
      else if (triangleDisadvantage) {
        acc *= trianglePenalty;
      }
      return clamp(acc - avoid, 0, 100);
    }

    int crit() {
      int crt = attacker.attackCrit;
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
  bool isCounter;
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
    if (player == attacker) {
      return cast(int) ((damageDealt * attackXpFactor + baseXp) * levelFactor(player, enemy));
    }
    else {
      auto dodgeBonus = hit ? 0 : dodgeXp;
      return cast(int) ((baseXp + dodgeBonus) * levelFactor(player, enemy));
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
    xp += killXpBonus * levelFactor(player, enemy);
  }
  return xp;
}

int computeStealXp(Battler stealer, Battler target) {
  return cast(int) (stealXp * levelFactor(stealer, target));
}

int computeCastXp(Battler caster, Battler target) {
  return cast(int) (castXp * levelFactor(caster, target));
}

int computeLockpickXp(Battler battler) {
  return cast(int) (lockpickXp * lockpickLevelFactor.pow(battler.level));
}

private:
// how much level difference influences xp
float levelFactor(Battler player, Battler enemy) {
    return cast(float) (enemy.level + levelXpFactor) / (player.level + levelXpFactor);
}

int berserkDamageBonus(Battler c) {
  return cast(int) ((1 - cast(float) c.hp / c.maxHp) * berserkDamageFactor);
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
];
