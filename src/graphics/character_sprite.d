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
      col = to!int(_spriteData.entries["cols"]["armor1"]);
    }
    else if (character.hasTalent("armor1")) {
      col = to!int(_spriteData.entries["cols"]["armor2"]);
    }
    super(spriteSheet, row, col);
    if (character.isArmed) {
      string type = to!string(character.equippedWeapon.type);
      assert(type in _spriteData.entries["cols"], "no sprite for weapon type " ~ type);
      int weaponRow = to!int(_spriteData.entries["rows"]["weapon"]);
      int weaponCol = to!int(_spriteData.entries["cols"][type]);
      _weaponSprite = new Sprite(spriteSheet, weaponRow, weaponCol);
    }
  }

  override void draw(Vector2i pos) {
    super.draw(pos);
    if (_weaponSprite) {
      _weaponSprite.draw(pos);
    }
  }

  private Sprite _weaponSprite;
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
