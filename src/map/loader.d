module map.loader;

import std.conv;
import std.range : empty;
import std.algorithm : find, sort;
import allegro;
import util.jsonizer;
import map.tile;
import map.tilemap;
import model.battler;
import model.character;
import graphics.sprite;
import graphics.texture;
import geometry.vector;

LevelData loadBattle(string mapName) {
  string path = Paths.mapDir ~ mapName ~ ".json";
  auto mapData = readJSON!MapData(path);
  auto level = new LevelData;
  level.map = mapData.constructMap();
  level.enemies = mapData.constructEnemies();
  return level;
}

class LevelData {
  TileMap map;
  Battler[] allies;
  Battler[] enemies;
  Battler[] neutrals;
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
    auto featureData = layers[1].data;
    auto tiles = new Tile[][height];
    // order tilesets with highest firstgid first
    tilesets.sort!((a,b) => a.firstgid > b.firstgid);
    for(int row = 0 ; row < height ; ++row) {
      tiles[row] = new Tile[width];
      for(int col = 0 ; col < width ; ++col) {
        auto terrainID = terrainData[row * width + col];
        auto featureID = featureData[row * width + col];
        tiles[row][col] = constructTile(row, col, terrainID, featureID, tilesets);
      }
    }

    return new TileMap(tiles, tilewidth, tileheight);
  }

  Battler[] constructEnemies() {
    Battler[] enemies;
    auto enemyLayer = layers.find!(x => x.name == "Enemies");
    assert(!enemyLayer.empty, "could not find layer named Enemies");
    foreach(obj ; enemyLayer[0].objects) {
      enemies ~= obj.generateEnemy(tilewidth, tileheight, tilesets);
    }
    return enemies;
  }

  Tile constructTile(int row, int col, int terrainGid, int featureGid, TileSet[] tilesets) {
    auto terrainSprite = gidToSprite(terrainGid, tilesets);
    auto featureSprite = gidToSprite(featureGid, tilesets);
    return new Tile(row, col, terrainSprite, featureSprite);
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
    MapObject[] objects;
    int width, height;
    string name;
    float opacity;
    LayerType type;
    bool visible;
    int x, y;
  }
}

class MapObject {
  mixin JsonizeMe;

  Battler generateEnemy(int tileWidth, int tileHeight, TileSet[] tilesets) {
    auto character = loadCharacter(name);
    auto level = to!int(properties.get("level", "1"));
    for(int i = 1 ; i < level ; i++) {
      character.levelUp();
    }

    auto sprite = gidToSprite(gid, tilesets);
    int col = x / tileWidth;
    int row = y / tileHeight;
    auto pos = Vector2i(x, y) + sprite.size / 2;

    return new Battler(character, row, col, pos, sprite);
  }

  @jsonize @property {
    int gid;
    int width, height;
    string name;
    string[string] properties;
    string type;
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

Sprite gidToSprite(int gid, TileSet[] tilesets) {
  // match gid to tileset
  if (gid == 0) { return null; }
  auto tileSet = tilesets.find!(x => x.firstgid <= gid);
  assert(!tileSet.empty, "could not match gid " ~ to!string(gid));
  return tileSet[0].createTileSprite(gid);
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
