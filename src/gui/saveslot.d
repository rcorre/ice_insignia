module gui.saveslot;

import gui.element;
import gui.container;
import gui.saveslot;
import graphics.all;
import geometry.all;
import util.savegame;

class SaveSlot : GUIElement {
  this(Vector2i topLeft, int idx) {
    super(topLeft, Anchor.topLeft);
  }

  override {
    void handleSelect() {
    }

    void draw() {
      _texture.draw(topLeft);
    }

    @property {
      int width() { return _texture.width; }
      int height() { return _texture.height; }
    }
  }
}

private:
Texture _texture;
static this() {
  _texture = getTexture("saveslot");
}
