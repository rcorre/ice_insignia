module state.battle;

import std.array;
import std.algorithm : map, all;
import allegro;
import state.gamestate;
import tilemap.all;
import geometry.all;
import util.input;
import graphics.all;
import model.battler;
import model.character;
import gui.all;

private enum {
  scrollSpeed = 500,     /// camera scroll rate (pixels/sec)
  battlerMoveSpeed = 200,/// battler move speed (pixels/sec)
  tileInfoPos = cast(Vector2i) Vector2f(Settings.screenW * 0.9f, Settings.screenH * 0.9f)
}

class Battle : GameState {
  this(string mapName, Character[] playerUnits) {
    auto data = loadBattle(mapName);
    _map = data.map;
    _enemies = data.enemies;
    foreach(enemy ; _enemies) { // place enemies
      placeBattler(enemy, _map.tileAt(enemy.row, enemy.col));
    }

    foreach(idx, character ; playerUnits) { // place player units at spawn points
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

    foreach(battler ; _battlers) {
      battler.sprite.update(time);
    }

    auto newState = _state.update(time);
    if (newState) {
      _state.onExit();
      _state = newState;
    }

    // handle mouse -- display tile info
    auto tile = _map.tileAtPos(_camera.topLeft + _input.mousePos);
    if (tile) {
      _tileInfoBox = new TileInfoBox(tileInfoPos, tile.name, tile.defense, tile.avoid);
    }
    else {
      _tileInfoBox = null;
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
    if (_tileInfoBox) {
      _tileInfoBox.draw();
    }
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
  TileInfoBox _tileInfoBox;

  void placeBattler(Battler b, Tile t) {
    t.battler = b;
    b.row = t.row;
    b.col = t.col;
    b.pos = _map.tileCoordToPos(t.row, t.col);
  }

  abstract class State {
    State update(float time);
    void draw() {}
    void onExit() {}
  }

  class PlayerTurn : State {
    this() {
      _turnOver = _allies.all!"a.moved";
    }

    override State update(float time) {
      if (_turnOver || _input.endTurn) {
        foreach(battler ; _allies) {
          battler.moved = false;
        }
        return new PlayerTurn;
      }

      if (_input.confirm) {
        auto tile = _map.tileAtPos(_camera.topLeft + _input.mousePos);
        if (tile && tile.battler && !tile.battler.moved) {
          return new PlayerUnitSelected(tile.battler, tile);
        }
      }
      return null;
    }

    private:
    bool _turnOver;
  }

  class PlayerUnitSelected : State {
    this(Battler battler, Tile tile) {
      _battler = battler;
      _tile = tile;
      _pathFinder = new PathFinder(_map, _tile, _battler.move);
      _tileSelector = new AnimatedSprite("tile_highlight");
      _tileSelector.tint = moveTint;
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
        nodes.draw(lineWidth, lineTint);
      }
    }

    private:
    enum {
      moveTint = ALLEGRO_COLOR(0,0.0,0.9,0.7),
      lineTint = ALLEGRO_COLOR(0,1,1,0.5),
      lineWidth = 3
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
      placeBattler(_battler, path.back); // place battler on final tile
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
    private enum targetShade = ucolor(255, 0, 0, 255);

    this(Battler battler, Tile prevTile) {
      _battler = battler;
      _prevTile = prevTile;
      auto selectPos = _battler.pos - _camera.topLeft - Vector2i(50, 50);
      _selectionView = new SelectionView(selectPos, getActions());
      _targetSprite = new AnimatedSprite("target", targetShade);
    }

    override State update(float time) {
      if (_battler.moved) { // move has completed
        return new PlayerTurn;
      }

      _targetSprite.update(time);
      _selectionView.handleMouse(_input.mousePos, _input.confirm);

      if (_input.cancel) {
        placeBattler(_battler, _prevTile);
        return new PlayerTurn;
      }
      if (_input.confirm ) {
        auto tile = _map.tileAtPos(_input.mousePos + _camera.topLeft);
        if (tile.battler && _battler.canAttack(tile.battler)) {
          return new ExecuteAttack(_battler, tile.battler);
        }
      }
      return null;
    }

    override void draw() {
      _selectionView.draw();
      foreach(enemy ; _enemies) {
        if (_battler.canAttack(enemy)) {
          _targetSprite.draw(enemy.pos - _camera.topLeft);
        }
      }
    }

    private:
    Battler _battler;
    Tile _prevTile;
    SelectionView _selectionView;
    AnimatedSprite _targetSprite;

    SelectionView.Action[string] getActions() {
      return ["Inventory": &itemAction, "Wait": &waitAction];
    }

    void itemAction() {
    }

    void waitAction() {
      _battler.moved = true;
    }
  }

  class ExecuteAttack : State {
    enum {
      attackSpeed = 30,   /// movement rate of attack animation
      attackShiftDist = 8 /// pixels to shift when showing attack
    }

    this(Battler attacker, Battler defender) {
      assert(attacker.equippedWeapon.isWeapon);
      _attacker = attacker;
      _defender = defender;
      auto attackDirection = (defender.pos - attacker.pos).normalized;
      _startPos = attacker.pos;
      _endPos = attacker.pos + attackDirection * attackShiftDist;
    }

    override State update(float time) {
      if (!_destReached) {
        _dist += attackShiftDist * time;
         _attacker.pos = _attacker.pos.movedTo(_endPos, _dist, _destReached);
         if (_destReached) {
           _dist = 0;
           _defender.sprite.flash(0.2, Tint.black);
         }
      }
      else {
        _dist += attackShiftDist * time;
        _attacker.pos = _attacker.pos.movedTo(_startPos, _dist, _returned);
        if (_returned) {
          _attacker.moved = true; // end attacker's turn
          return new PlayerTurn;
        }
      }
      return null;
    }

    private:
    Battler _attacker, _defender;
    Vector2i _startPos, _endPos;
    bool _destReached, _returned;
    float _dist = 0;
  }
}
