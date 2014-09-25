module gui.saveslot;

import gui.element;
import gui.container;
import gui.saveslot;
import graphics.all;
import geometry.all;
import util.savegame;

class SaveSlot : GUIElement {
  this(Vector2i topLeft, SaveData data, void delegate(SaveData) onSelect) {
    super(topLeft, Anchor.topLeft);
    _onSelect = onSelect;
    _data = data;
  }

  override {
    void handleSelect() {
      _onSelect(_data);
    }

    void draw() {
      _texture.draw(center);
    }

    @property {
      int width() { return _texture.width; }
      int height() { return _texture.height; }
    }
  }

  private:
  SaveData _data;
  void delegate(SaveData) _onSelect;
}

private:
Texture _texture;
static this() {
  _texture = getTexture("saveslot");
}
