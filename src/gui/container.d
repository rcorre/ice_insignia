module gui.container;

import std.algorithm;
import std.array;
import gui.element;
import geometry.all;
import graphics.all;

class GUIContainer : GUIElement {
  this(Vector2i pos, Anchor anchorType, string textureName) {
    _texture = getTexture(textureName);
    super(pos, anchorType);
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
      if (_selectedElement) {
        _selectedElement.bounds.drawFilled(Color(0, 0.5, 0, 0.5));
      }
    }

    void update() {
      foreach(slot ; _elements) {
        slot.update();
      }
    }

    void handleHover() {
      if (_selectedElement) {
        _selectedElement.handleHover;
      }
    }

    void moveCursor(Vector2i direction) {
      //TODO: this is such a mess
      if (_selectedElement) {
        if (direction.x > 0) {
          auto r = _elements.filter!(x => x.bounds.left > _selectedElement.bounds.right).array;
          if (!r.empty) {
            r.sort!((a,b) => a.bounds.left < b.bounds.left);
            if (!r.empty) {
              _selectedElement = r.front;
            }
          }
        }
        else if (direction.x < 0) {
          auto r = _elements.filter!(x => x.bounds.right < _selectedElement.bounds.left).array;
          if (!r.empty) {
            r.sort!((a,b) => a.bounds.right > b.bounds.right);
            if (!r.empty) {
              _selectedElement = r.front;
            }
          }
        }
        else if (direction.y > 0) {
          auto r = _elements.filter!(x => x.bounds.top > _selectedElement.bounds.bottom).array;
          if (!r.empty) {
            r.sort!((a,b) => a.bounds.top < b.bounds.top);
            if (!r.empty) {
              _selectedElement = r.front;
            }
          }
        }
        else if (direction.y < 0) {
          auto r = _elements.filter!(x => x.bounds.bottom < _selectedElement.bounds.top).array;
          if (!r.empty) {
            r.sort!((a,b) => a.bounds.bottom > b.bounds.bottom);
            if (!r.empty) {
              _selectedElement = r.front;
            }
          }
        }
      }
    }
  }

  final void addElement(GUIElement element) {
    element.topLeft = element.topLeft + topLeft;
    _elements ~= element;
    if (_selectedElement is null) {
      _selectedElement = element;
    }
  }

  private:
  Texture _texture;
  GUIElement[] _elements;
  GUIElement _selectedElement;
}
