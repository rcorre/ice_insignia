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
  offsetSprite       = Vector2i(25, 49),
  offsetName         = Vector2i(49, 41),
  offsetWeaponSprite = Vector2i(25, 113),
  offsetWeaponName   = Vector2i(49, 105),
  offsetDamage       = Vector2i(81, 137),
  offsetHit          = Vector2i(81, 169),
  offsetCrit         = Vector2i(81, 201),
  offsetInputIcon    = Vector2i(-10, -20),
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
      pos.x += buffer;
    }

    if (pos.y > Settings.screenH / 2) {
      pos.y -= (buffer + height / 2);
    }
    else {
      pos.y += buffer;
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
    drawPrediction(_attack, _area.topLeft);
    drawPrediction(_counter, _area.topLeft + spacing);
    drawInputIcon("previous", _area.topLeft + offsetWeaponSprite + offsetInputIcon, gamepad,
        "previous");
    drawInputIcon("next", _area.topLeft + offsetWeaponSprite + offsetInputIcon.mirroredH, gamepad, "next");
  }

  private:
  CombatPrediction _attack, _counter;
  Vector2f _multOffset = multOffset;
  AnimatedSprite _advantageSprite, _disadvantageSprite;

  void drawPrediction(CombatPrediction pred, Vector2i offset) {
    auto unit = pred.attacker;
    unit.sprite.draw(offset + offsetSprite);
    unit.equippedWeapon.sprite.draw(offset + offsetWeaponSprite);
    _font.draw(unit.name                , offset + offsetName);
    _font.draw(unit.equippedWeapon.name , offset + offsetWeaponName);
    _font.draw(pred.damage              , offset + offsetDamage);
    _font.draw(pred.hit                 , offset + offsetHit);
    _font.draw(pred.crit                , offset + offsetCrit);
    if (pred.doubleHit) {
      _font.draw("x2", cast(Vector2i) (offset + offsetDamage + _multOffset), Color.green);
    }
    if (pred.triangleAdvantage) {
      _advantageSprite.draw(offset + offsetWeaponSprite);
    }
    else if (pred.triangleDisadvantage) {
      _disadvantageSprite.draw(offset + offsetWeaponSprite);
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
    _attacker.sprite.draw(offset + offsetSprite);
    _attacker.equippedWeapon.sprite.draw(offset + offsetWeaponSprite);
    _font.draw(_attacker.name                , offset + offsetName);
    _font.draw(_attacker.equippedWeapon.name , offset + offsetWeaponName);
    _font.draw(_attacker.attackDamage        , offset + offsetDamage);
    _font.draw(_attacker.attackHit           , offset + offsetHit);
    _font.draw(_attacker.attackCrit          , offset + offsetCrit);

    _font.draw(_wall.name , offset + offsetName       + spacing);
    _font.draw("none"     , offset + offsetWeaponName + spacing);
    _font.draw(0          , offset + offsetDamage     + spacing);
    _font.draw(0          , offset + offsetHit        + spacing);
    _font.draw(0          , offset + offsetCrit       + spacing);
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
