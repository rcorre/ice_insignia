module gui.roster_slot;

import gui.element;
import geometry.all;
import graphics.all;
import model.character;

private enum {
  Color bgColor = Color.gray,
  Color borderColor = Color.black,
  int slotSize = 40,
  float borderThickness = 2,
}

class RosterSlot : GUIElement {
  alias Action = void delegate(Character);
  Character character;

  this(Vector2i pos, Character character, Action action) {
    this.character = character;
    if (character) {
      _sprite = new CharacterSprite(character.model);
    }
    _action = action;
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
      _action(character);
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
  Action _action;
}
