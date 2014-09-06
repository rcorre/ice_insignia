module gui.level_up_view;

import std.array;
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
  arrowOffset = Vector2i(10, 5)
}

/// displays info about a character's stats
class LevelUpView : CharacterSheet {
  this(Vector2i topLeft, Battler battler, AttributeSet bonuses) {
    super(topLeft, battler, true);
    _bonuses = array([EnumMembers!Attribute].filter!(a => bonuses[a] > 0));
  }

  @property {
    bool doneAnimating() { return _bonuses.empty && _arrowAnimations.back.isStopped; }
  }

  void update(float time) {
    if (!_bonuses.empty && _arrowAnimations.empty) {
      startAnimation;
    }

    foreach(anim ; _arrowAnimations) {
      anim.update(time);
    }
  }

  override void draw() {
    super.draw;
    foreach(pos, anim ; zip(_positions, _arrowAnimations)) {
      anim.draw(pos);
    }
  }

  void startAnimation() {
    if (_bonuses.empty) { return; }
    auto bar = statBarFor(_bonuses.front);
    _bars ~= bar;
    _positions ~= bar.bounds.topRight + arrowOffset;
    _arrowAnimations ~= new AnimatedSprite(animationName, &endAnimation);
  }

  void endAnimation() {
    if (_bonuses.front == Attribute.maxHp) {
      _bars.front.maxVal = _bars.front.maxVal + 1;
    }
    else {
      _bars.front.val = _bars.front.val + 1;
    }
    _bonuses.popFront;
    _bars.popFront;
    startAnimation;
  }

  private:
  Attribute[] _bonuses;
  AnimatedSprite[] _arrowAnimations;
  Vector2i[] _positions;
  ProgressBar!int[] _bars;
}
