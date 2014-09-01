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

  this(Vector2i pos, Character character, Action action) {
    this.character = character;
    _action = action;
    super(pos, Anchor.center);
  }

  @property {
    auto character() { return _character; }
    void character(Character newChar) {
      _character = newChar;
      _sprite = newChar ? new CharacterSprite(newChar.model) : null;
    }
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
  Character _character;
  Action _action;
}
