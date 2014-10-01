module gui.combat_view;

import std.conv;
import std.string : format;
import std.algorithm;
import allegro;
import geometry.all;
import graphics.all;
import state.combat_calc;
import tilemap.object;
import model.battler;
import gui.input_icon;

private enum {
  leftOffsetSprite       = Vector2i(25, 25),
  leftOffsetName         = Vector2i(49, 9),
  leftOffsetHp           = Vector2i(73, 29),
  leftOffsetWeaponSprite = Vector2i(20, 65),
  leftOffsetWeaponName   = Vector2i(36, 53),
  leftOffsetDescription  = Vector2i(9,  73),
  leftOffsetDamage       = Vector2i(73, 94),
  leftOffsetHit          = Vector2i(73, 118),
  leftOffsetCrit         = Vector2i(73, 142),

  rightOffsetSprite       = Vector2i(193, 25),
  rightOffsetName         = Vector2i(113, 9),
  rightOffsetHp           = Vector2i(133, 29),
  rightOffsetWeaponSprite = Vector2i(196, 65),
  rightOffsetWeaponName   = Vector2i(112, 53),
  rightOffsetDescription  = Vector2i(117, 73),
  rightOffsetDamage       = Vector2i(137, 92),
  rightOffsetHit          = Vector2i(137, 116),
  rightOffsetCrit         = Vector2i(137, 140),

  prevItemOffset     = Vector2i(100, -16),
  nextItemOffset     = Vector2i(132, -16),
  multOffset         = Vector2f(8, 0),
  multRotation       = 2.0,
  spacing            = Vector2i(193, 0),
  buffer             = 20, // distance between view and sprite
  advantageSprite    = "upArrow",
  disadvantageSprite = "downArrow"
}

abstract class CombatView {
  this(Vector2i pos) {
    if (pos.x > Settings.screenW / 2) {
      pos.x -= (buffer + width / 2);
    }
    else {
      pos.x += buffer + width / 2;
    }

    if (pos.y > Settings.screenH / 2) {
      pos.y -= (buffer + height / 2);
    }
    else {
      pos.y += buffer + height / 2;
    }
    _area = Rect2i.CenteredAt(pos, width, height);
  }

  @property {
    Rect2i area() { return _area; }
    static {
      int width() { return _texture.width; }
      int height() { return _texture.height; }
    }
  }

  void update(float time) { }

  void draw(bool gamepad) {
    _texture.draw(area.center);
  }

  private Rect2i _area;
}

class BattlerCombatView : CombatView {
  this(Vector2i pos, CombatPrediction attack, CombatPrediction counter) {
    super(pos);
    _attack = attack;
    _counter = counter;
    _advantageSprite = new AnimatedSprite(advantageSprite);
    _disadvantageSprite = new AnimatedSprite(disadvantageSprite);
  }

  override void update(float time) {
    _multOffset.rotate(time * multRotation);
    _advantageSprite.update(time);
    _disadvantageSprite.update(time);
  }

  override void draw(bool gamepad) {
    super.draw(gamepad);
    drawLeftPrediction(_attack, _area.topLeft);
    drawRightPrediction(_counter, _area.topLeft);
    drawInputIcon("previous", _area.topLeft + prevItemOffset, gamepad);
    drawInputIcon("next", _area.topLeft + nextItemOffset, gamepad, "cycle weapon");
  }

  private:
  CombatPrediction _attack, _counter;
  Vector2f _multOffset = multOffset;
  AnimatedSprite _advantageSprite, _disadvantageSprite;

  void drawLeftPrediction(CombatPrediction pred, Vector2i offset) {
    auto unit = pred.attacker;
    auto weapon = unit.equippedWeapon;
    unit.sprite.draw(offset + leftOffsetSprite);
    weapon.sprite.draw(offset + leftOffsetWeaponSprite);
    _font.draw(unit.name   , offset + leftOffsetName);
    _font.draw(weapon.name , offset + leftOffsetWeaponName);
    _font.draw(pred.damage , offset + leftOffsetDamage);
    _font.draw(pred.hit    , offset + leftOffsetHit);
    _font.draw(pred.crit   , offset + leftOffsetCrit);
    _font.draw(weapon.text , offset + leftOffsetDescription);
    _font.draw("%2d".format(unit.hp), offset + leftOffsetHp);
    if (pred.doubleHit) {
      _font.draw("x2", cast(Vector2i) (offset + leftOffsetDamage + _multOffset), Color.green);
    }
    if (pred.triangleAdvantage) {
      _advantageSprite.draw(offset + leftOffsetWeaponSprite);
    }
    else if (pred.triangleDisadvantage) {
      _disadvantageSprite.draw(offset + leftOffsetWeaponSprite);
    }
  }

  void drawRightPrediction(CombatPrediction pred, Vector2i offset) {
    auto unit = pred.attacker;
    auto weapon = unit.equippedWeapon;
    unit.sprite.draw(offset + rightOffsetSprite);
    weapon.sprite.draw(offset + rightOffsetWeaponSprite);
    _font.draw(unit.name   , offset + rightOffsetName);
    _font.draw(weapon.name , offset + rightOffsetWeaponName);
    _font.draw(pred.damage , offset + rightOffsetDamage);
    _font.draw(pred.hit    , offset + rightOffsetHit);
    _font.draw(pred.crit   , offset + rightOffsetCrit);
    _font.draw(weapon.text , offset + rightOffsetDescription);
    _font.draw("%2d".format(unit.hp), offset + rightOffsetHp);
    if (pred.doubleHit) {
      _font.draw("x2", cast(Vector2i) (offset + rightOffsetDamage + _multOffset), Color.green);
    }
    if (pred.triangleAdvantage) {
      _advantageSprite.draw(offset + rightOffsetWeaponSprite);
    }
    else if (pred.triangleDisadvantage) {
      _disadvantageSprite.draw(offset + rightOffsetWeaponSprite);
    }
  }
}

class WallCombatView : CombatView {
  this(Vector2i pos, Battler attacker, Wall wall) {
    super(pos);
    _attacker = attacker;
    _wall = wall;
  }

  override void draw(bool gamepad) {
    super.draw(gamepad);
    auto offset = area.topLeft;
    // draw attacker
    _attacker.sprite.draw(offset + leftOffsetSprite);
    _attacker.equippedWeapon.sprite.draw(offset + leftOffsetWeaponSprite);
    _font.draw(_attacker.name                , offset + leftOffsetName);
    _font.draw(_attacker.equippedWeapon.name , offset + leftOffsetWeaponName);
    _font.draw(_attacker.attackDamage        , offset + leftOffsetDamage);
    _font.draw(_attacker.attackHit           , offset + leftOffsetHit);
    _font.draw(_attacker.attackCrit          , offset + leftOffsetCrit);
    _font.draw("%2d".format(_attacker.hp)    , offset + leftOffsetHp);

    _font.draw(_wall.name , offset + rightOffsetName      );
    _font.draw("none"     , offset + rightOffsetWeaponName);
    _font.draw(0          , offset + rightOffsetDamage    );
    _font.draw(0          , offset + rightOffsetHit       );
    _font.draw(0          , offset + rightOffsetCrit      );
    _font.draw("%2d".format(_wall.hp), offset + rightOffsetHp);
  }

  private:
  Rect2i _area;
  Battler _attacker;
  Wall _wall;
}

private:
static Font _font ;
static Texture _texture;

static this() {
  _font = getFont("combat_info_font");
  _texture = getTexture("combat_view");
}
