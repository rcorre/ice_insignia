module graphics.animation;

import allegro;
import util.config;
import std.conv;
import graphics.sprite;
import graphics.color;

class AnimatedSprite : Sprite {
  this(string name, ALLEGRO_COLOR tint = Color.white) {
    super(name, tint);

    auto data = _animationData.entries[name];
    _startCol = _col;
    _endCol = _col + to!int(data["length"]);
    _frameTime = to!float(data["frameTime"]);
    _timer = _frameTime;
  }

  override void update(float time) {
    super.update(time);
    _timer -= time;
    if (_timer < 0) {
      _timer = _frameTime;
      ++_col;
      if (_col > _endCol) {
        _col = _startCol;
      }
    }
  }

  private:
  float _timer, _frameTime;
  int _startCol, _endCol;
}

private ConfigData _animationData;

static this() {
  _animationData = loadConfigFile(Paths.spriteData);
}
