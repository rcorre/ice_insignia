module graphics.sprite;

import std.string;
import std.array;
import std.conv;
import allegro;
import geometry.vector;
import graphics.texture;
import util.config;

/// displays a single frame of a texture
class Sprite {
  this(string spriteName) {
    assert(spriteName in _spriteData.entries, spriteName ~ " is not defined in " ~ Paths.spriteData);
    auto data = _spriteData.entries[spriteName];
    _name = spriteName;
    _texture = getTexture(data["texture"]);
    _row = to!int(data["row"]);
    _col = to!int(data["col"]);
    _baseScale = to!int(data.get("baseScale", "1"));
  }

  this(Texture spriteSheet, int spriteIdx, float baseScale = 1) {
    _texture = spriteSheet;
    _row = spriteIdx / _texture.numCols;
    _col = spriteIdx % _texture.numCols;
    _baseScale = baseScale;
  }

  void draw(Vector2i pos) {
    _texture.draw(_row, _col, pos, totalScale, _tint, _angle);
  }

  @property {
    /// unique name used to look up sprite data
    string name() { return _name; }
    /// width of the sprite after scaling (px)
    auto width() { return _texture.frameWidth * totalScale; }
    /// height of the sprite after scaling (px)
    auto height() { return _texture.frameHeight * totalScale; }
    /// tint color of the sprite
    auto tint()                    { return _tint; }
    auto tint(ALLEGRO_COLOR color) { return _tint = color; }
    /// get the rotation angle of the sprite (radians)
    auto angle()            { return _angle; }
    auto angle(float angle) { return _angle = angle; }
    /// the scale factor of the sprite
    auto scale()            { return _scaleFactor; }
    auto scale(float scale) { return _scaleFactor = scale; }
    /// the total scale factor from the original image
    auto totalScale() { return _scaleFactor * _baseScale; }
  }

  private:
  string _name;
  Texture _texture;
  const float _baseScale;
  int _row, _col;
  float _scaleFactor  = 1;
  float _angle        = 0;
  ALLEGRO_COLOR _tint = Color.white;
}

private ConfigData _spriteData;

static this() {
  _spriteData = loadConfigFile(Paths.spriteData);
}
