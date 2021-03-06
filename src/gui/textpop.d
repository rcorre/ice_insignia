module gui.textpop;

import geometry.all;
import graphics.all;
import gui.textbox;

private enum {
  velocity = Vector2f(0, -3000),
  duration = 3f,
  fontName = "textPop"
}

class TextPopup : Textbox {
  this(Vector2i pos, string text, Color textColor = Color.black, Color bgColor = Color.clear) {
    this(pos, [text], textColor, bgColor);
  }

  this(Vector2i pos, string[] text, Color textColor = Color.black, Color bgColor = Color.clear) {
    super(pos, text, fontName, textColor, bgColor);
  }

  @property bool expired() { return _timer <= 0; }

  void update(float time) {
    _area.center += velocity * time;
    _timer -= time;
  }

  override void draw() {
    if (_timer > 0) {
      super.draw;
    }
  }

  private:
  float _timer = duration;
}
