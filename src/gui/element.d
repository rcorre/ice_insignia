module gui.element;

import geometry.all;
import graphics.all;
import util.input;

enum Anchor {
  topLeft,
  center
}

abstract class GUIElement {
  this(Vector2i pos, Anchor anchorType) {
    final switch (anchorType) {
      case Anchor.topLeft:
        _bounds = Rect2i(pos, width, height);
        break;
      case Anchor.center:
        _bounds = Rect2i.CenteredAt(pos, width, height);
        break;
    }
  }

  // concrete
  @property final {
    auto topLeft() { return _bounds.topLeft; }
    void topLeft(Vector2i pos) { _bounds.topLeft = pos; }

    auto center() { return _bounds.center; }
    void center(Vector2i pos) { _bounds.center = pos; }

    Rect2i bounds() { return _bounds; }
  }

  void handleInput(InputManager input) {
    if (input.selectRight) {
      moveCursor(Vector2i(1, 0));
    }
    else if (input.selectLeft) {
      moveCursor(Vector2i(-1, 0));
    }
    else if (input.selectUp) {
      moveCursor(Vector2i(0, -1));
    }
    else if (input.selectDown) {
      moveCursor(Vector2i(0, 1));
    }
    else if (input.confirm) {
      handleSelect;
    }
    else if (input.cancel) {
      handleCancel;
    }
  }

  // abstract
  @property {
    int width();
    int height();
  }

  void handleSelect();
  void draw();

  // optional
  void update(float time) {}
  void handleHover() {}
  void handleCancel() {};
  void moveCursor(Vector2i direction) {}

  protected:
  GUIElement _parent;

  private:
  Rect2i _bounds;
}
