module gui.element;

import geometry.all;
import graphics.all;

enum Anchor {
  topLeft,
  center
}

enum Direction {
  left,
  right,
  up,
  down
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

  // abstract
  @property {
    int width();
    int height();
  }

  void handleSelect();
  void draw();

  // optional
  void update() {}
  void handleHover() {}
  void handleMove(Direction dir) {}

  // concrete
  @property final {
    auto topLeft() { return _bounds.topLeft; }
    void topLeft(Vector2i pos) { _bounds.topLeft = pos; }

    auto center() { return _bounds.center; }
    void center(Vector2i pos) { _bounds.center = pos; }

    Rect2i bounds() { return _bounds; }
  }

  private:
  Rect2i _bounds;
}
