module gui.item_view;

import std.conv;
import std.string;
import std.string : format;
import graphics.all;
import geometry.all;
import model.item;

private enum {
  textureName = "item_view",
  fontName = "weaponInfo",
  spriteOffset = Vector2i(-68, -40),
  nameOffset   = Vector2i(-42, -49),
  dmgOffset    = Vector2i(-58,  -8),
  crtOffset    = Vector2i( -1,  -8),
  rngOffset    = Vector2i( 61,  4),
  hitOffset    = Vector2i(-57,  17),
  wgtOffset    = Vector2i(  0,  17),
  typOffset    = Vector2i( 55,  17),
  infoOffset   = Vector2i(-81,  41),
  classOffset  = Vector2i( 68, -25),
}

/// display info about an item
class ItemView {
  this(Item item, Vector2i pos) {
    _item = item;
    _area = Rect2i.CenteredAt(pos, _texture.width, _texture.height);
    if (_item.type != ItemType.other) {
      _classSprite = new Sprite(_item.type.to!string.chompPrefix("ItemType.") ~ item.tier.to!string);
    }
  }

  void draw() {
    auto pos = _area.center;
    _texture.draw(pos);
    _item.sprite.draw(pos + spriteOffset);
    if (_classSprite !is null) {
      _classSprite.draw(pos + classOffset);
    }
    _font.draw(_item.name,   pos + nameOffset);
    _font.draw(_item.damage, pos + dmgOffset);
    _font.draw(_item.hit   , pos + hitOffset);
    _font.draw(_item.crit  , pos + crtOffset);
    _font.draw(_item.weight, pos + wgtOffset);
    _font.draw(format("%d-%d", _item.minRange, _item.maxRange), pos + rngOffset);
    _font.draw(_item.type  , pos + typOffset);
    _font.draw(_item.text  , pos + infoOffset);
  }

  void keepInside(Rect2i camera, int buffer = 0) {
    _area.keepInside(camera, buffer);
  }

  static auto size() {
    return Vector2i(_texture.width, _texture.height);
  }

  private:
  Item _item;
  Rect2i _area;
  Sprite _classSprite;

  static Texture _texture;
  static Font _font;

  static this() {
    _texture = getTexture(textureName);
    _font = getFont(fontName);
  }
}
