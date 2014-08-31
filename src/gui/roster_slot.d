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
  Character character;

  this(Vector2i pos, Character character) {
    this.character = character;
    if (character) {
      _sprite = new CharacterSprite(character.model);
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
  CharacterSprite _sprite;
}
