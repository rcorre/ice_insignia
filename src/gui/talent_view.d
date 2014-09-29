module gui.talent_view;

import std.traits;
import graphics.all;
import geometry.all;
import model.talent;
import model.attribute;

private enum {
  textureName       = "talent_view",
  titleFont         = "talentName",
  descriptionFont   = "talentDescription",
  spriteOffset      = Vector2i(30, 27),
  titleOffset       = Vector2i(56, 18),
  descriptionOffset = Vector2i(15, 50),
  bonusOffset = Vector2i(15, 55),
  bonusColor = Color(0, 0.5, 0.2),
  penaltyColor = Color(0.6, 0.0, 0.0),
}

/// display info about an item
class TalentView {
  this(Talent talent, Vector2i topLeft) {
    _talent = talent;
    _area = Rect2i(topLeft, _texture.width, _texture.height);
    auto pos = bonusOffset;
    foreach(att ; EnumMembers!Attribute) {
      BonusText text;
      if (_talent.potential[att] > 0) {
        text.text = att.abbreviation ~ " +";
        text.color = bonusColor;
      }
      else if (_talent.potential[att] < 0) {
        text.text = att.abbreviation ~ " -";
        text.color = penaltyColor;
      }
      text.pos = pos;
      auto height = _descriptionFont.heightOf(text.text);
      pos.y += height;
      //_area.height += height;
      _bonusInfo ~= text;
    }
    //_scale = Vector2f(1f, _area.height / _texture.height);
    _scale = Vector2f(1f, 1f);
  }

  void draw() {
    auto pos = _area.topLeft;
    _texture.draw(_area.center, _scale);
    _talent.sprite.draw(pos + spriteOffset);
    _titleFont.draw(_talent.title, pos + titleOffset);
    _descriptionFont.draw(_talent.description, pos + descriptionOffset);
    foreach (bonus ; _bonusInfo) {
      _descriptionFont.draw(bonus.text, bonus.pos + pos, bonus.color);
    }
  }

  void keepInside(Rect2i camera, int buffer = 0) {
    _area.keepInside(camera, buffer);
  }

  static @property width() { return _texture.width; }

  private:
  Talent _talent;
  Rect2i _area;
  Vector2f _scale;
  BonusText[] _bonusInfo;

  static Texture _texture;
  static Font _descriptionFont, _titleFont;

  static this() {
    _texture = getTexture(textureName);
    _titleFont = getFont(titleFont);
    _descriptionFont = getFont(descriptionFont);
  }
}

private struct BonusText {
  string text;
  Vector2i pos;
  Color color;
}
