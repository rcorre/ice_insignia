module gui.container;

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
      if (_selectedSlot) {
        _selectedSlot.handleSelect();
      }
    }

    void draw() {
      _texture.draw(bounds.center);
      foreach(slot ; _slots) {
        slot.draw();
      }
      if (_selectedSlot) {
        _selectedSlot.bounds.drawFilled(Color(0, 0.5, 0, 0.5));
      }
    }

    void update() {
      foreach(slot ; _slots) {
        slot.update();
      }
    }

    void handleHover() {
      if (_selectedSlot) {
        _selectedSlot.handleHover;
      }
    }

    void handleMove(Direction dir) {
      if (_selectedSlot && dir in _selectedSlot.neighbors) {
        _selectedSlot = _selectedSlot.neighbors[dir];
      }
    }
  }

  final void addElement(GUIElement element, GUIElement[Direction] neighbors = (GUIElement[Direction]).init) {
    element.topLeft = element.topLeft + topLeft;
    auto slot = new Slot;
    slot.element = element;
    slot.neighbors = neighbors;
    _slots ~= slot;
  }

  private:
  Texture _texture;
  Slot[] _slots;
  Slot _selectedSlot;
}

class Slot {
  alias element this;
  GUIElement[Direction] neighbors;
  GUIElement element;
}
