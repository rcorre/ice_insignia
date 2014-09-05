module gui.level_up_view;

import std.array;
import std.traits;
import allegro;
import geometry.all;
import graphics.all;
import gui.all;
import model.character;
import model.battler;

private enum {
  animationName = "levelUpArrow"
}

/// displays info about a character's stats
class LevelUpView : CharacterSheet {
  this(Vector2i topLeft, Battler battler, AttributeSet bonuses) {
    super(topLeft, battler, true);
    _bonuses = array([EnumMembers!Attribute].filter!(a => bonuses[a] > 0));
    if (!_bonuses.empty) {
      startAnimation;
    }
  }

  @property {
    bool doneAnimating() { return _bonuses.empty; }
  }

  void update(float time) {
    if (doneAnimating) { return; }
    if (_arrowAnimations.front.isStopped) {
      startAnimation; // start next arrow animation
    }

    foreach(anim ; _arrowAnimations) {
      anim.update(time);
    }
  }

  override void draw() {
    super.draw;
    foreach(idx, anim ; _arrowAnimations) {
      auto bar = statBarFor(idx);
      anim.draw(bar.bounds.center);
    }
  }

  void startAnimation() {
    _bonuses.popFront;
    _arrowAnimations ~= new AnimatedSprite(animationName);
  }

  private:
  Attribute[] _bonuses;
  AnimatedSprite[] _arrowAnimations;
}
