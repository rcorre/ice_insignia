module state.combat_calc.d;

import std.algorithm : max, min;
import model.character;
import model.weapon;

struct CombatPrediction {
  this(Character attacker, Character defender) {
    this.attacker = attacker;
    this.defender = defender;
  }

  @property {
    int damage() { return max(0, attacker.damage - defender.defense); }
  }

  Character attacker, defender;
}

private:
// combat stats
int damage(Character c) {
  return c.equippedWeapon.damage + c.strength;
}

int adjustedSpeed(Character c) {
  int penalty = min(0, c.constitution  - c.equippedWeapon.weight);
  return c.speed + penalty;
}
