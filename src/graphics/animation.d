module graphics.animation;

import allegro;
import util.config;
import std.conv;
import graphics.sprite;
import graphics.color;

class AnimatedSprite : Sprite {
  alias Action = void delegate();
  // TODO: replace no with stop (stop animating) or destroy (remove sprite)
  enum Repeat {
    unspecified, /// use value from config file
    no,          /// run only once
    loop,        /// loop back to beginning
    rebound      /// reverse animation direction
  }

  this(string name, Color tint = Color.white, Repeat repeat = Repeat.unspecified,
      Action onAnimationEnd = null)
  {
    super(name, tint);
    auto data = _animationData.entries[name];
    _startCol = _col;
    _endCol = _col + to!int(data["length"]);
    _frameTime = to!float(data["frameTime"]);
    if (repeat == Repeat.unspecified) { // try to load repeat setting from config
      repeat = to!Repeat(data.get("repeat", "no")); // default to Repeat.no if not found
    }
    _repeat = repeat;
    _timer = _frameTime;
    _onAnimationEnd = onAnimationEnd;
  }

  this(string name, Action onAnimationEnd) {
    this(name, Color.white, Repeat.unspecified, onAnimationEnd);
  }

  override void update(float time) {
    super.update(time);
    if (!_animate) { return; }

    _timer -= time;
    if (_timer < 0) {
      _timer = _frameTime;
      ++_col;
      if (_col == _endCol) {
        if (_onAnimationEnd) { _onAnimationEnd(); }
        final switch(_repeat) with(Repeat) {
          case no:
            _animate = false;
            _col = _endCol - 1;
            break;
          case loop:
            _col = _startCol;
            break;
          case rebound:
            assert(0, "AnimatedSprite.Repeat.rebound not implemented");
          case unspecified:
            assert(0, "AnimatedSprite.Repeat should never be unspecified");
        }
      }
    }
  }

  @property isStopped() { return !_animate; }

  private:
  float _timer, _frameTime;
  int _startCol, _endCol;
  Repeat _repeat;
  bool _animate = true;
  Action _onAnimationEnd;
}

private ConfigData _animationData;

static this() {
  _animationData = loadConfigFile(Paths.spriteData);
}
