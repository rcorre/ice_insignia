module gui.container;

import std.algorithm;
import std.array;
import gui.element;
import geometry.all;
import graphics.all;
import util.all;

class GUIContainer : GUIElement {
  this(Vector2i pos, Anchor anchorType, string textureName, Sprite cursorSprite) {
    _texture = getTexture(textureName);
    super(pos, anchorType);
    _cursor = cursorSprite;
  }

  // abstract
  override {
    @property {
      int width() { return _texture.width; }
      int height() { return _texture.height; }
    }

    void handleSelect() {
      if (_selectedElement) {
        _selectedElement.handleSelect();
      }
    }

    void draw() {
      _texture.draw(bounds.center);
      foreach(slot ; _elements) {
        slot.draw();
      }
      if (_selectedElement && showCursor) {
        _cursor.draw(_selectedElement.center);
      }
    }

    void update(float time) {
      foreach(slot ; _elements) {
        slot.update(time);
      }
      _cursor.update(time);
    }

    void handleHover() {
      if (_selectedElement) {
        _selectedElement.handleHover;
      }
    }

    void moveCursor(Vector2i direction) {
      GUIElement[] r;
      if (_selectedElement) {
        if (direction.x > 0) {
          r = _elements.filter!(x => x.bounds.left > _selectedElement.bounds.right).array;
        }
        else if (direction.x < 0) {
          r = _elements.filter!(x => x.bounds.right < _selectedElement.bounds.left).array;
        }
        else if (direction.y > 0) {
          r = _elements.filter!(x => x.bounds.top > _selectedElement.bounds.bottom).array;
        }
        else if (direction.y < 0) {
          r = _elements.filter!(x => x.bounds.bottom < _selectedElement.bounds.top).array;
        }
        if (!r.empty) {
          playSound("cursor");
          auto pos = _selectedElement.center;
          r.sort!((a,b) => distance(pos, a.bounds.center) < distance(pos, b.bounds.center));
          _selectedElement = r.front;
          _selectedElement.handleHover;
        }
      }
    }
  }

  final {
    T addElement(T : GUIElement)(T element) {
      element.topLeft = element.topLeft + topLeft;
      _elements ~= element;
      if (_selectedElement is null) {
        _selectedElement = element;
        _selectedElement.handleHover;
      }
      return element;
    }

    void removeElement(GUIElement element) {
      auto idx = _elements.countUntil(element);
      if (idx >= 0) {
        _elements = _elements.remove(idx);
      }
    }

    auto elementsOfType(T)() {
      return elements.map!"cast(T) a".filter!"a !is null";
    }

    @property auto selectedElement() { return _selectedElement; }
  }

  protected:
  bool showCursor = true;

  private:
  Texture _texture;
  GUIElement[] _elements;
  GUIElement _selectedElement;
  Sprite _cursor;
}
