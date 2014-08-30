module gui.roster_slot;

import gui.element;
import geometry.all;
import graphics.all;
import model.character;

class RosterSlot : GUIElement {
  this(Vector2i pos, Anchor anchorType, Character character) {
    _character = character;
    _sprite = new Sprite("blue_recruit");
    super(pos, Anchor.center);
  }

  override {
    @property {
      int width() {
        return _sprite.width;
      }
      int height() {
        return _sprite.height;
      }
    }

    void handleSelect() {
    }

    void draw() {
      _sprite.draw(bounds.center);
    }

    // optional
    void update() {}
    void handleHover() {}
    void handleMove(Direction dir) {}
  }

  private:
  Character _character;
  Sprite _sprite;
}
