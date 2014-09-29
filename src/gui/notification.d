module gui.notification;

import geometry.all;
import graphics.all;

private enum {
  bgColor = Color(0, 0, 0.9, 0.6),
  textColor = Color.black,
}

class Notification {
  this(Vector2i center, string text) {
    _text = text;
    auto size = _font.textSize(text);
    _area = Rect2i.CenteredAt(center, size.width, size.height);
  }

  void draw() {
    _area.drawFilled(bgColor);
    _font.drawCentered(_text, _area.center, textColor);
  }

  private:
  Rect2i _area;
  string _text;
}

private static Font _font;

static this() {
  _font = getFont("notification");
}
