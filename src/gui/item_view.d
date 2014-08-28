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
  typOffset    = Vector2i( 61,  17),
}

/// display info about an item
class ItemView {
  this(Item item, Vector2i pos) {
    _item = item;
    _pos = pos;
  }

  void draw() {
    _texture.draw(_pos);
    _item.draw(_pos + spriteOffset);
    _font.draw(_item.name,   _pos + nameOffset);
    _font.draw(_item.damage, _pos + dmgOffset);
    _font.draw(_item.hit   , _pos + hitOffset);
    _font.draw(_item.crit  , _pos + crtOffset);
    _font.draw(_item.weight, _pos + wgtOffset);
    _font.draw(format("%d-%d", _item.minRange, _item.maxRange), _pos + rngOffset);
    _font.draw(_item.type  , _pos + typOffset);
  }

  private:
  Item _item;
  Vector2i _pos;

  static Texture _texture;
  static Font _font;

  static this() {
    _texture = getTexture(textureName);
    _font = getFont(fontName);
  }
}
