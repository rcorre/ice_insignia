module gui.level_up_view;

import std.array;
import std.string;
import std.range;
import std.traits;
import allegro;
import geometry.all;
import graphics.all;
import gui.all;
import model.character;
import model.battler;

private enum {
  animationName = "levelUpArrow",
  arrowOffset = Vector2i(10, 5),
  textOffset = Vector2i(-11, -10),
  bonusColor = Color(0, 0.8, 0.2)
}

/// displays info about a character's stats
class LevelUpView : CharacterSheet {
  this(Vector2i topLeft, Battler battler, AttributeSet bonuses) {
    super(topLeft, battler, true);
    _bonuses = bonuses;
    _attributesToLevel = array([EnumMembers!Attribute].filter!(a => bonuses[a] != 0));
    _bonusText = array(_attributesToLevel.map!(a => format("%+d", bonuses[a])));
  }

  @property {
    bool doneAnimating() { return _attributesToLevel.empty; }
  }

  void update(float time) {
    if (!_attributesToLevel.empty && _arrowAnimations.empty) {
      startAnimation;
    }

    foreach(anim ; _arrowAnimations) {
      anim.update(time);
    }
  }

  override void draw() {
    super.draw;
    foreach(i, pos, anim ; lockstep(_positions, _arrowAnimations)) {
      anim.draw(pos);
      if (anim.isStopped) {
        _font.draw(_bonusText[i], pos + textOffset, anim.tint);
      }
    }
  }

  void startAnimation() {
    if (_attributesToLevel.empty) { return; }
    auto bar = statBarFor(_attributesToLevel.front);
    _bars ~= bar;
    _positions ~= bar.bounds.topRight + arrowOffset;
    auto sprite = new AnimatedSprite(animationName, &endAnimation);
    _arrowAnimations ~= sprite;
    sprite.tint = _bonuses[_attributesToLevel.front] > 0 ? Color.green : Color.red;
  }

  void endAnimation() {
    if (_attributesToLevel.front == Attribute.maxHp) {
      _bars.front.maxVal = _bars.front.maxVal + _bonuses[_attributesToLevel.front];
    }
    else {
      _bars.front.val = _bars.front.val + 1;
    }
    _attributesToLevel.popFront;
    _bars.popFront;
    startAnimation;
  }

  private:
  AttributeSet _bonuses;
  Attribute[] _attributesToLevel;
  AnimatedSprite[] _arrowAnimations;
  string[] _bonusText;
  Vector2i[] _positions;
  ProgressBar!int[] _bars;
}

static Font _font;
static this() {
  _font = getFont("attributeBonus");
}
