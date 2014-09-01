module gui.item_view;

import std.conv;
import std.string : format;
import graphics.all;
import geometry.all;
import model.item;

private enum {
  textureName = "item_view",
  fontName = "weaponInfo",
  spriteOffset = Vector2i(-66, -42),
  nameOffset   = Vector2i(-38, -49),
  dmgOffset    = Vector2i(-58,  -8),
  crtOffset    = Vector2i( -1,  -8),
  rngOffset    = Vector2i( 61,  -8),
  hitOffset    = Vector2i(-57,  17),
  wgtOffset    = Vector2i(  0,  17),
  typOffset    = Vector2i( 55,  15),
}

/// display info about an item
class ItemView {
  this(Item item, Vector2i pos) {
    _item = item;
    _area = Rect2i.CenteredAt(pos, _texture.width, _texture.height);
  }

  void draw() {
    auto pos = _area.center;
    _texture.draw(pos);
    _item.sprite.draw(pos + spriteOffset);
    _font.draw(_item.name,   pos + nameOffset);
    _font.draw(_item.damage, pos + dmgOffset);
    _font.draw(_item.hit   , pos + hitOffset);
    _font.draw(_item.crit  , pos + crtOffset);
    _font.draw(_item.weight, pos + wgtOffset);
    _font.draw(format("%d-%d", _item.minRange, _item.maxRange), pos + rngOffset);
    _font.draw(_item.type  , pos + typOffset);
  }

  void keepInside(Rect2i camera, int buffer = 0) {
    _area.keepInside(camera, buffer);
  }

  private:
  Item _item;
  Rect2i _area;

  static Texture _texture;
  static Font _font;

  static this() {
    _texture = getTexture(textureName);
    _font = getFont(fontName);
  }
}
