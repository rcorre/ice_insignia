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
    _bonuses.popFront;
    _arrowAnimations ~= new AnimatedSprite(animationName, &endAnimation);
  }

  void endAnimation() {
    _bars.front.val = _bars.front.val + 1;
    _bars.popFront;
    startAnimation;
  }

  private:
  Attribute[] _bonuses;
  AnimatedSprite[] _arrowAnimations;
  Vector2i[] _positions;
  ProgressBar!int[] _bars;
}
