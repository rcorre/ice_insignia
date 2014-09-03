module tilemap.loader;

import std.conv;
import std.range : empty;
import std.array : array;
import std.algorithm : find, sort, filter, map;
import allegro;
import util.jsonizer;
import tilemap.tile;
import tilemap.tilemap;
import model.battler;
import model.character;
import graphics.sprite;
import graphics.texture;
import geometry.vector;

enum mapFormat = Paths.mapDir ~ "/map%d.json";

LevelData loadLevel(int mapNumber) {
  string path = format(mapFormat, mapNumber);
  auto mapData = readJSON!MapData(path);
  auto level = new LevelData;
  level.map = mapData.constructMap();
  level.enemies = mapData.constructEnemies();
  level.spawnPoints = mapData.getSpawnPoints();
  return level;
}

class LevelData {
  TileMap map;
  Vector2i[] spawnPoints;
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

  Vector2i[] getSpawnPoints() {
    auto allyLayer = layers.find!(x => x.name == "Allies");
    assert(!allyLayer.empty, "could not find layer named Allies");
    auto spawners = allyLayer[0].objects.filter!(x => x.type == "spawn");
    auto points = array(map!(p => Vector2i(p.x + tilewidth / 2, p.y - tileheight / 2))(spawners));
    return points;
  }

  Tile constructTile(int row, int col, int terrainGid, int featureGid, TileSet[] tilesets) {
    auto terrainSprite = gidToSprite(terrainGid, tilesets);
    auto featureSprite = gidToSprite(featureGid, tilesets);
    TileProperties props;
    if (featureGid != 0) { // use terrain props only if feature props don't exist
      props = gidToProperties(featureGid, tilesets);
    }
    else {
      props = gidToProperties(terrainGid, tilesets);
    }
    auto name = props.name;
    auto moveCost = props.moveCost;
    auto avoid = props.avoid;
    auto defense = props.defense;
    return new Tile(row, col, terrainSprite, featureSprite, name, moveCost, defense, avoid);
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
    // type is used to store level
    auto character = generateCharacter(name, to!int(type), properties.keys);

    int col = x / tileWidth;
    int row = y / tileHeight;
    auto pos = Vector2i(x, y) + Vector2i(tileWidth, tileHeight) / 2;

    auto aiType = properties.get("aiType", "agressive");

    return new Battler(character, row, col, pos, BattleTeam.enemy, aiType);
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
    string name = "Unknown";
  }
}

TileSet gidToTileset(int gid, TileSet[] tilesets) {
  if (gid == 0) { return null; }
  auto tileSet = tilesets.find!(x => x.firstgid <= gid);
  assert(!tileSet.empty, "could not match gid " ~ to!string(gid));
  return tileSet[0];
}

Sprite gidToSprite(int gid, TileSet[] tilesets) {
  // match gid to tileset
  if (gid == 0) { return null; }
  auto tileSet = gidToTileset(gid, tilesets);
  return tileSet.createTileSprite(gid);
}

TileProperties gidToProperties(int gid, TileSet[] tilesets) {
  auto tileset = gidToTileset(gid, tilesets);
  return tileset.tileproperties.get(to!string(gid - 1), new TileProperties);
}
