module map.loader;

import std.algorithm : find;
import allegro;
import util.jsonizer;
import map.tile;
import map.tilemap;
import graphics.sprite;
import graphics.texture;

TileMap loadMap(string mapName) {
  string path = Paths.mapDir ~ mapName ~ ".json";
  auto mapData = readJSON!MapData(path);
  return mapData.constructMap();
}

private:
enum LayerType {
  tilelayer,
  objectgroup
}

enum Orientation {
  orthogonal,
  isometric
}

class MapData {
  mixin JsonizeMe;

  TileMap constructMap() {
    auto terrainData = layers[0].data;
    auto tiles = new Tile[][height];
    for(int row = 0 ; row < height ; ++row) {
      tiles[row] = new Tile[width];
      for(int col = 0 ; col < width ; ++col) {
        tiles[row][col] = constructTile(row, col, terrainData[row * width + col], tilesets);
      }
    }

    return new TileMap(tiles, tilewidth, tileheight);
  }

  Tile constructTile(int row, int col, int gid, TileSet[] tilesets) {
    // match gid to tileset
    auto tileSet = tilesets.find!((tileset) => tileset.firstgid <= gid)[0];
    auto sprite = tileSet.createTileSprite(gid);
    return new Tile(row, col, sprite);
  }

  @jsonize {
    int width, height;         // in number of tiles
    int tilewidth, tileheight; // in pixels
    MapLayer[] layers;
    Orientation orientation;
    string[string] properties;
    TileSet[] tilesets;
  }
}


class MapLayer {
  mixin JsonizeMe;
  @jsonize {
    int[] data;
    int width, height;
    string name;
    float opacity;
    LayerType type;
    bool visible;
    int x, y;
  }
}

class TileSet {
  mixin JsonizeMe;
  @jsonize {
    string name;
    int firstgid;
    int tilewidth, tileheight;
    int imagewidth, imageheight;
    TileProperties[string] tileproperties;
  }

  Sprite createTileSprite(int gid) {
    auto texture = getTexture(name);
    int tid = gid - firstgid; // convert global id into local tile id
    return new Sprite(texture, tid);
  }
}

class TileProperties {
  mixin JsonizeMe;
  @jsonize {
    int avoid          = 0;
    int defense        = 0;
    int moveCost       = 1;
    string terrainName = "";
  }
}

unittest {
  auto map = readJSON!MapData("content/maps/test.json");
  assert(map.width == 4 && map.height == 4);
  auto layer = map.layers[0];
  assert(layer.data.length == 16);
  assert(layer.data[0] == 10 && layer.data[9] == 61);
  assert(layer.name == "Terrain" && layer.type == LayerType.tilelayer);
  assert(layer.visible == true && layer.opacity == 1);
}
