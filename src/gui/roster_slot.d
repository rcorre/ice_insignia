module gui.roster_slot;

import gui.element;
import geometry.all;
import graphics.all;
import model.character;

private enum {
  Color bgColor = Color.gray,
  Color borderColor = Color.black,
  int slotSize = 36,
  float borderThickness = 2,
}

class RosterSlot : GUIElement {
  this(Vector2i pos, Character character) {
    _character = character;
    if (_character) {
      _sprite = new Sprite(_character.spriteName);
    }
    super(pos, Anchor.center);
  }

  override {
    @property {
      int width() {
        return slotSize;
      }
      int height() {
        return slotSize;
      }
    }

    void handleSelect() {
    }

    void draw() {
      bounds.drawFilled(bgColor);
      bounds.draw(borderThickness, borderColor);
      if (_sprite) {
        _sprite.draw(bounds.center);
      }
    }
  }

  private:
  Character _character;
  Sprite _sprite;
}
