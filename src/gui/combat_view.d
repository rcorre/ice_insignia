module gui.combat_view;

import std.conv;
import std.string : format;
import std.algorithm;
import geometry.all;
import graphics.all;
import state.combat_calc;
import tilemap.object;
import model.battler;

private enum spacing = Vector2i(193, 0);
private enum {
  offsetSprite       = Vector2i(49, 49),
  offsetName         = Vector2i(73,41),
  offsetWeaponSprite = Vector2i(49, 113),
  offsetWeaponName   = Vector2i(73, 105),
  offsetDamage       = Vector2i(105, 137),
  offsetHit          = Vector2i(105, 169),
  offsetCrit         = Vector2i(105, 201),
}

abstract class CombatView {
  this(Vector2i pos) {
    _area = Rect2i.CenteredAt(pos, width, height);
  }

  @property {
    Rect2i area() { return _area; }
    static {
      int width() { return _texture.width; }
      int height() { return _texture.height; }
    }
  }

  void draw() {
    _texture.draw(area.center);
  }

  private Rect2i _area;
}

class BattlerCombatView : CombatView {
  this(Vector2i pos, CombatPrediction attack, CombatPrediction counter) {
    super(pos);
    _attack = attack;
    _counter = counter;
  }

  override void draw() {
    super.draw();
    drawPrediction(_attack, _area.topLeft);
    drawPrediction(_counter, _area.topLeft + spacing);
  }

  private:
  CombatPrediction _attack, _counter;

  void drawPrediction(CombatPrediction pred, Vector2i offset) {
    auto unit = pred.attacker;
    unit.sprite.draw(offset + offsetSprite);
    unit.equippedWeapon.sprite.draw(offset + offsetWeaponSprite);
    _font.draw(unit.name                , offset + offsetName);
    _font.draw(unit.equippedWeapon.name , offset + offsetWeaponName);
    _font.draw(pred.damage              , offset + offsetDamage);
    _font.draw(pred.hit                 , offset + offsetHit);
    _font.draw(pred.crit                , offset + offsetCrit);
  }
}

class WallCombatView : CombatView {
  this(Vector2i pos, Battler attacker, Wall wall) {
    super(pos);
    _attacker = attacker;
    _wall = wall;
  }

  override void draw() {
    super.draw();
    auto offset = area.topLeft;
    // draw attacker
    _attacker.sprite.draw(offset + offsetSprite);
    _attacker.equippedWeapon.sprite.draw(offset + offsetWeaponSprite);
    _font.draw(_attacker.name                , offset + offsetName);
    _font.draw(_attacker.equippedWeapon.name , offset + offsetWeaponName);
    _font.draw(_attacker.attackDamage        , offset + offsetDamage);
    _font.draw(_attacker.attackHit           , offset + offsetHit);
    _font.draw(_attacker.attackCrit          , offset + offsetCrit);

    _font.draw(_wall.name , offset + offsetSprite     + spacing);
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
