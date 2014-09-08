module gui.talent_view;

import graphics.all;
import geometry.all;
import model.talent;

private enum {
  textureName       = "talent_view",
  titleFont         = "talentName",
  descriptionFont   = "talentDescription",
  spriteOffset      = Vector2i(30, 27),
  titleOffset       = Vector2i(56, 18),
  descriptionOffset = Vector2i(15, 50),
}

/// display info about an item
class TalentView {
  this(Talent talent, Vector2i topLeft) {
    _talent = talent;
    _area = Rect2i(topLeft, _texture.width, _texture.height);
  }

  void draw() {
    auto pos = _area.topLeft;
    _texture.draw(_area.center);
    _talent.sprite.draw(pos + spriteOffset);
    _titleFont.draw(_talent.title, pos + titleOffset);
    _descriptionFont.draw(_talent.description, pos + descriptionOffset);
  }

  void keepInside(Rect2i camera, int buffer = 0) {
    _area.keepInside(camera, buffer);
  }

  static @property width() { return _texture.width; }

  private:
  Talent _talent;
  Rect2i _area;

  static Texture _texture;
  static Font _descriptionFont, _titleFont;

  static this() {
    _texture = getTexture(textureName);
    _titleFont = getFont(titleFont);
    _descriptionFont = getFont(descriptionFont);
  }
}
