module state.battle;

import std.array;
import std.algorithm : map;
import allegro;
import state.gamestate;
import tilemap.all;
import geometry.all;
import util.input;
import graphics.all;
import model.battler;
import model.character;

private enum {
  scrollSpeed = 500,     /// camera scroll rate (pixels/sec)
  battlerMoveSpeed = 300 /// battler move speed (pixels/sec)
}

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
      if (_input.confirm) {
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
        if (_selectedPath && _input.confirm) {
          return new MoveBattler(_battler, _tile, _selectedPath);
        }
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

  class MoveBattler : State {
    this(Battler battler, Tile currentTile, Tile[] path) {
      _battler = battler;
      _path = path;
      _pos = cast(Vector2f) _battler.pos;
      _originTile = currentTile;
      currentTile.battler = null;  // remove battler from current tile
      path.back.battler = battler; // place battler on final tile
    }

    override State update(float time) {
      if (_path.empty) { /// completed move
        return new ChooseBattlerAction(_battler, _originTile);
      }

      auto target = cast(Vector2f) _map.tileToPos(_path.front); 
      auto disp = target - _pos;
      float dist = battlerMoveSpeed * time;
      if (disp.len <= dist) {
        _pos = target;
        _path.popFront;
      }
      else {
        _pos += disp.unit * dist;
      }
      _battler.pos = _pos;

      return null;
    }

    private:
    Battler _battler;
    Tile[] _path;
    Tile _originTile;
    Vector2f _pos;
  }

  /// Battler has moved and must take an action or revert to the pre-move position
  class ChooseBattlerAction : State {
    this(Battler battler, Tile prevTile) {
      _battler = battler;
      _prevTile = prevTile;
    }

    override State update(float time) {
      if (_input.cancel) {
        placeBattler(_battler, _prevTile);
        return new PlayerTurn;
      }
      return null;
    }

    private:
    Battler _battler;
    Tile _prevTile;
  }
}
