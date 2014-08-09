module graphics.texture;

import std.string;
import std.conv;
import allegro;
import data.config;
import geometry.all;

class Texture {
  @property {
    /// number of frame columns in the texture
    int numRows() { return width / frameWidth; }
    /// number of frame rows in the texture
    int numCols() { return height / frameHeight; }
    /// width of entire texture (px)
    int width()  { return _width; }
    /// height of entire texture (px)
    int height() { return _height; }
    /// width of a single texture frame (px)
    int frameWidth()  { return _frameWidth; }
    /// height of a single texture frame (px)
    int frameHeight() { return _frameHeight; }
    /// center position of a single frame (relative to the frame itself)
    Vector2i frameCenter() { return _frameCenter; }
  }

  void draw(int row, int col, Vector2i pos, float scale = 1, ALLEGRO_COLOR tint = Color.white, float angle = 0) {
    assert(col >= 0 && col < numCols && row >= 0 && row < numRows);
    auto frame = Rect2i(col * frameWidth, row * frameHeight, frameWidth, frameHeight);
    al_draw_tinted_scaled_rotated_bitmap_region(_bmp, // bitmap
        frame.x, frame.y, frame.width, frame.height,  // bitmap region
        tint,                                         // color
        frameCenter.x, frameCenter.y,                 // frame center position
        pos.x, pos.y,                                 // position to place center of frame at
        scale, scale,                                 // x and y scale
        angle, 0);                                    // rotation and flats
  }

  private:
  ALLEGRO_BITMAP* _bmp;
  const int _width, _height;
  const int _frameWidth, _frameHeight;
  const Vector2i _frameCenter;

  this(ALLEGRO_BITMAP *bmp, int frameWidth, int frameHeight) {
    _bmp         = bmp;
    _frameWidth  = frameWidth;
    _frameHeight = frameHeight;
    _width       = al_get_bitmap_width(bmp);
    _height      = al_get_bitmap_height(bmp);
    _frameCenter = Vector2i(frameWidth / 2, frameHeight / 2);
  }
}

private Texture[string] _textureStore;

Texture getTexture(string name) {
  assert(name in _textureStore, name ~ " is not a texture");
  return _textureStore[name];
}

static this() { // automatically load a texture for each entry in the texture sheet config file
  auto textureData = loadConfigFile(Paths.textureData);
  auto textureDir = textureData.globals["texture_dir"];
  foreach (textureName, textureInfo; textureData.entries) {
    auto path = toStringz(textureDir ~ "/" ~ textureInfo["filename"]);
    auto bmp = al_load_bitmap(path);
    assert(bmp, format("failed to load image %s", to!string(path)));
    auto frameSize = split(textureInfo["frameSize"], ",");
    _textureStore[textureName] = new Texture(bmp, to!int(frameSize[0]), to!int(frameSize[1]));
  }
}

static ~this() { // destroy all bitmaps and clear texture store
  foreach (texture ; _textureStore) {
    al_destroy_bitmap(texture._bmp);
  }
  _textureStore = null;
}
