module graphics.character_sprite;

import std.conv;
import allegro;
import geometry.all;
import graphics.texture;
import graphics.sprite;
import graphics.color;
import util.config;
import model.character;
import model.battler;

/// displays a single frame of a texture
class CharacterSprite : Sprite {
  this(Character character, BattleTeam team = BattleTeam.ally) {
    auto spriteSheet = (team == BattleTeam.ally) ? _blueSpriteSheet : _redSpriteSheet;
    auto model = character.model;
    assert(model in _spriteData.entries["rows"], "cannot find character sprite model " ~ model);
    int row = to!int(_spriteData.entries["rows"][model]);
    int col = 0;
    if (character.hasTalent("armor2")) {
      col = 2;
    }
    else if (character.hasTalent("armor1")) {
      col = 1;
    }
    super(spriteSheet, row, col);
  }

  override void draw(Vector2i pos) {
    super.draw(pos);
    // TODO: overlay weapon sprite
  }
}

private:
ConfigData _spriteData;
Texture _redSpriteSheet;
Texture _blueSpriteSheet;

static this() {
  _spriteData = loadConfigFile(Paths.characterSpriteData);
  _blueSpriteSheet = getTexture(_spriteData.globals["blue_texture"]);
  _redSpriteSheet = getTexture(_spriteData.globals["red_texture"]);
}
