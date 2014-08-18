module state.battle;

import std.array : array;
import std.algorithm : map;
import allegro;
import state.gamestate;
import tilemap.all;
import geometry.all;
import util.input;
import graphics.all;
import model.battler;
import model.character;

enum scrollSpeed = 500;

class Battle : GameState {
  this(string mapName, Character[] playerUnits) {
    auto data = loadBattle(mapName);
    _map = data.map;
    _enemies = data.enemies;
    foreach(idx, character ; playerUnits) {
      assert(idx < data.spawnPoints.length, "not enough spawn points for player units");
      auto pos = data.spawnPoints[idx];
      auto tile = _map.tileAtPos(pos);
      auto sprite = new Sprite("blue_recruit");
      Battler b = new Battler(character, tile.row, tile.col, pos, sprite, BattleTeam.ally);
      _allies ~= b;
      placeBattler(b, tile);
    }
    _neutrals = [];
    _battlers = _enemies ~ _allies ~ _neutrals;
    _camera = Rect2i(0, 0, Settings.screenW, Settings.screenH);
    _input = new InputManager;
    _state = new PlayerTurn;
  }

  override GameState update(float time) {
    _input.update();
    _camera.topLeft = _camera.topLeft + cast(Vector2i) (_input.scrollDirection * time * scrollSpeed);
    _camera.keepInside(_map.bounds);
    auto newState = _state.update(time);
    if (newState) {
      _state.onExit();
      _state = newState;
    }
    return null;
  }

  override void draw() {
    _map.draw(Vector2i(0,0), _camera);
    foreach(battler ; _battlers) {
      auto sprite = battler.sprite;
      auto rect = Rect2i.CenteredAt(battler.pos, sprite.width, sprite.height);
      if (_camera.intersects(rect)) {
        sprite.draw(rect.center - _camera.topLeft);
      }
    }
    _state.draw();
  }

  override void onExit() {
  }

  private:
  TileMap _map;
  Rect2i _camera;
  Vector2i _scrollVelocity;
  InputManager _input;
  Battler[] _battlers;
  Battler[] _allies;
  Battler[] _enemies;
  Battler[] _neutrals;
  State _state;

  void placeBattler(Battler b, Tile t) {
    t.battler = b;
    b.row = t.row;
    b.col = t.col;
    b.pos = _map.tileCoordToPos(t.row, t.col);
    debug {
      import std.stdio;
      writeln("placing battler at " , t.row, " " , t.col);
      assert(t.battler !is null);
    }
  }

  abstract class State {
    State update(float time);
    void draw() {}
    void onExit() {}
  }

  class PlayerTurn : State {
    override State update(float time) {
      if (_input.mouseClicked(MouseButton.lmb)) {
        auto tile = _map.tileAtPos(_camera.topLeft + _input.mousePos);
        debug {
          import std.stdio;
          writeln(tile !is null);
          writeln(tile.row , " " , tile.col);
          writeln(tile.battler !is null);
        }
        if (tile && tile.battler) {
          return new PlayerUnitSelected(tile.battler, tile);
        }
      }
      return null;
    }
  }

  class PlayerUnitSelected : State {
    this(Battler battler, Tile tile) {
      _battler = battler;
      _tile = tile;
      _pathFinder = new PathFinder(_map, _tile, _battler.move);
      _tileSelector = new AnimatedSprite("tile_highlight");
    }

    override State update(float time) {
      _tileSelector.update(time);
      auto tileUnderMouse = _map.tileAtPos(_input.mousePos + _camera.topLeft);
      if (tileUnderMouse) {
        _selectedPath = _pathFinder.pathTo(tileUnderMouse);
      }
      return null;
    }

    override void draw() {
      foreach (tile ; _pathFinder.tilesInRange) {
        auto pos = _map.tileToPos(tile) - _camera.topLeft;
        _tileSelector.draw(pos);
      }

      if (_selectedPath) {
        auto nodes = array(_selectedPath.map!(t => _map.tileToPos(t) - _camera.topLeft));
        nodes.draw(3, al_map_rgba_f(0,1,1,0.5));
      }
    }

    private:
    enum {
      minAlpha = 0.2f,
      maxAlpha = 0.5f,
      pulseRate = 0.6f
    }
    Battler _battler;
    Tile _tile;
    Tile[] _selectedPath;
    Vector2i _pathPoints;
    PathFinder _pathFinder;
    AnimatedSprite _tileSelector;
  }
}
