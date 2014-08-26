module gui.character_sheet;

import gui.progress_bar;
import gui.selection_view;

private enum {
  spritePos         = Vector2i(80, 72),
  namePos           = Vector2i(129, 72),
  lvlPos            = Vector2i(362, 74),
  healthBarPos      = Vector2i(109, 137),
  xpBarPos          = Vector2i(109, 169),
  attributesPos     = Vector2i(121, 234),
  attributesSep     = 32,
  combatStatsPos    = Vector2i(606, 398),
  combatStatsSep    = 32,
  equipmentPos      = Vector2i(515, 155),
  equipmentStatsSep = 32,
}

/// displays info about a character's stats
class CharacterSheet {
  this(Battler battler) {
    _battler = battler;
  }

  void handleInput(InputManager input) {
  }

  void draw() {
  }

  private:
  Battler _battler;
}
