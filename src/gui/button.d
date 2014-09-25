module gui.button;

import geometry.all;
import graphics.all;
import util.input;
import gui.element;

class Button : GUIElement {
  alias Action = void delegate();
  this(Vector2i pos, Action onPress, string spriteName) {
    _onPress = onPress;
    _sprite = new Sprite(spriteName);
    super(pos, Anchor.center);
  }

  override {
    @property {
      int width() { return _sprite.width; }
      int height() { return _sprite.height; }
    }

    void handleSelect() {
      _onPress();
    }

    void draw() {
      _sprite.draw(bounds.center);
    }
  }

  private:
  Sprite _sprite;
  Action _onPress;
}
