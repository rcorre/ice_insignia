module state.battle;

import std.array;
import std.math;
import std.range : Cycle, cycle;
import std.typecons : tuple;
import std.algorithm : map, all;
import allegro;
import state.gamestate;
import state.combat_calc;
import tilemap.all;
import geometry.all;
import util.input;
import graphics.all;
import model.battler;
import model.character;
import gui.all;

private enum {
  scrollSpeed = 12,       /// camera scroll rate (pixels/sec)
  battlerMoveSpeed = 250, /// battler move speed (pixels/sec)
  tileInfoPos = cast(Vector2i) Vector2f(Settings.screenW * 0.9f, Settings.screenH * 0.9f),
  attackSpeed = 80,     /// movement rate of attack animation
  attackShiftDist = 8,  /// pixels to shift when showing attack
  damageFlashTime = 0.1 /// duration of flash used to indicate damage
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
    _tileCursor = new TileCursor;
  }

  override GameState update(float time) {
    _input.update(time);
    _tileCursor.update(time);

    foreach(battler ; _battlers) {
      battler.sprite.update(time);
    }

    auto newState = _state.update(time);
    if (newState) {
      _state.onExit();
      _state = newState;
    }

    // handle mouse -- display tile info
    auto tile = _tileCursor.tile;
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
  int _cursorRow, _cursorCol;
  TileCursor _tileCursor;

  void placeBattler(Battler b, Tile t) {
    auto currentTile = _map.tileAt(b.row, b.col);
    currentTile.battler = null; // remove from current tile
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
      auto moveableAllies = _allies.filter!"!a.moved";
      _turnOver = moveableAllies.empty;
      _unitJumpList = cycle(array(moveableAllies));
    }

    override State update(float time) {
      _tileCursor.handleInput(_input);
      if (_turnOver || _input.endTurn) {
        foreach(battler ; _allies) {
          battler.moved = false;
        }
        return new PlayerTurn; // TODO: enemy turn
      }

      _cursorRow = clamp(_cursorRow + _input.scrollDirection.y, 0, _map.numRows - 1);
      _cursorCol = clamp(_cursorCol + _input.scrollDirection.x, 0, _map.numCols - 1);

      // select unit under cursor
      if (_input.confirm) {
        auto tile = _tileCursor.tile;
        if (tile && tile.battler && !tile.battler.moved) {
          return new PlayerUnitSelected(tile.battler, tile);
        }
      }
      // jump to next ready unit
      if (_input.nextUnit) {
        auto nextBattler = _unitJumpList[_unitJumpIdx++];
        _tileCursor.place(_map.tileAt(nextBattler.row, nextBattler.col));
      }
      return null;
    }

    override void draw() {
      _tileCursor.draw();
    }

    private:
    bool _turnOver;
    uint _unitJumpIdx;
    Cycle!(Battler[]) _unitJumpList;
  }

  class PlayerUnitSelected : State {
    this(Battler battler, Tile tile) {
      _battler = battler;
      _tile = tile;
      _pathFinder = new PathFinder(_map, _tile, _battler.move);
      _tileHighlight = new AnimatedSprite("tile_highlight");
      _tileHighlight.tint = moveTint;
    }

    override State update(float time) {
      _tileCursor.handleInput(_input);
      _tileHighlight.update(time);
      auto tile = _tileCursor.tile;
      if (tile) {
        _selectedPath = _pathFinder.pathTo(tile);
        if (_selectedPath && _input.confirm) {
          return new MoveBattler(_battler, _tile, _selectedPath);
        }
      }
      if (_input.cancel) {
        return new PlayerTurn;
      }
      return null;
    }

    override void draw() {
      _tileCursor.draw();
      foreach (tile ; _pathFinder.tilesInRange) {
        auto pos = _map.tileToPos(tile) - _camera.topLeft;
        _tileHighlight.draw(pos);
      }

      if (_selectedPath) {
        auto nodes = array(_selectedPath.map!(t => _map.tileToPos(t) - _camera.topLeft));
        nodes.draw(lineWidth, lineTint);
      }
    }

    private:
    enum {
      moveTint = Color(0,0.0,0.9,0.7),
      lineTint = Color(0,1,1,0.5),
      lineWidth = 3
    }
    Battler _battler;
    Tile _tile;
    Tile[] _selectedPath;
    Vector2i _pathPoints;
    PathFinder _pathFinder;
    AnimatedSprite _tileHighlight;
  }

  class MoveBattler : State {
    this(Battler battler, Tile currentTile, Tile[] path) {
      _battler = battler;
      _path = path;
      _pos = cast(Vector2f) _battler.pos;
      _originTile = currentTile;
      _endTile = path.back;
      currentTile.battler = null;  // remove battler from current tile
    }

    override State update(float time) {
      if (_path.empty) { /// completed move
        placeBattler(_battler, _endTile); // place battler on final tile
        return new ChooseBattlerAction(_battler, _endTile, _originTile);
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
    Tile _originTile, _endTile;
    Vector2f _pos;
  }

  /// Battler has moved and must take an action or revert to the pre-move position
  class ChooseBattlerAction : State {
    private enum targetShade = ucolor(255, 0, 0, 255);

    this(Battler battler, Tile currentTile, Tile prevTile) {
      _battler = battler;
      _currentTile = currentTile;
      _prevTile = prevTile;
      _enemiesInRange = array(_enemies.filter!(a => _battler.canAttack(a)));
      _targetSprite = new AnimatedSprite("target", targetShade);
      auto selectPos = _battler.pos - _camera.topLeft - Vector2i(50, 50);
      _selectionView = new SelectionView(selectPos, getActions());
    }

    override State update(float time) {
      if (_requestedState) {
        return _requestedState;
      }

      _targetSprite.update(time);
      _selectionView.handleInput(_input);

      if (_input.cancel) {
        placeBattler(_battler, _prevTile);
        return new PlayerTurn;
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
    Battler[] _enemiesInRange;
    Tile _currentTile, _prevTile;
    SelectionView _selectionView;
    AnimatedSprite _targetSprite;
    State _requestedState;

    SelectionView.ActionEntry[] getActions() {
      SelectionView.ActionEntry[] actions;
      if (!_enemiesInRange.empty) {
        actions ~= tuple("Attack", &attackAction);
      }
      actions ~= tuple("Inventory", &itemAction);
      actions ~= tuple("Wait", &waitAction);
      return actions;
    }

    void itemAction() {
    }

    void attackAction() {
      _requestedState = new ConsiderAttack(_battler, _enemiesInRange);
    }

    void waitAction() {
      _battler.moved = true;
      _requestedState = new PlayerTurn;
    }
  }

  class ConsiderAttack : State {
    this(Battler attacker, Battler[] targets) {
      assert(!targets.empty);
      _attacker = attacker;
      _targets = targets;
      _attackTerrain = _map.tileAt(attacker.row, attacker.col);
      setTarget(targets[0]);
    }

    override State update(float time) {
      if (_input.confirm) {
        CombatResult[] attacks = [_attack.resolve()];
        if (_defender.canAttack(_attacker)) {
          attacks ~= _counter.resolve();
        }
        if (_attack.doubleHit) {
          attacks ~= _attack.resolve();
        }
        else if (_defender.canAttack(_attacker) && _counter.doubleHit) {
          attacks ~= _counter.resolve();
        }
        return new ExecuteCombat(attacks, _attacker);
      }
      else if (_input.selectLeft) {
        _targetIdx = (_targetIdx - 1) % _targets.length;
        setTarget(_targets[_targetIdx]);
      }
      else if (_input.selectRight) {
        _targetIdx = (_targetIdx + 1) % _targets.length;
        setTarget(_targets[_targetIdx]);
      }
      return null;
    }

    override void draw() {
      _tileCursor.draw();
      _view.draw();
    }

    private:
    Battler[] _targets;
    ulong _targetIdx;
    Battler _attacker, _defender;
    Tile _attackTerrain, _defendTerrain;
    CombatPrediction _attack, _counter;
    CombatView _view;

    void setTarget(Battler target) {
      _defender = target;
      _defendTerrain = _map.tileAt(target.row, target.col);
      _attack = new CombatPrediction(_attacker, _defender, _defendTerrain);
      _counter = new CombatPrediction(_defender, _attacker, _attackTerrain);
      _view = new CombatView(Vector2i(20, 20), _attack, _counter);
      _tileCursor.place(_defendTerrain);
    }
  }

  class ExecuteCombat : State {
    this(CombatResult[] attacks, Battler initialAttacker) {
      _attacks = attacks;
      _attacker = attacks[0].attacker;
      _defender = attacks[0].defender;
      auto attackDirection = (_defender.pos - _attacker.pos).normalized;
      _startPos = _attacker.pos;
      _endPos = _attacker.pos + attackDirection * attackShiftDist;
      _initialAttacker = initialAttacker;
    }

    override State update(float time) {
      if (!_destReached) {
        _dist += attackSpeed * time;
        _attacker.pos = _attacker.pos.movedTo(_endPos, _dist, _destReached);
        if (_destReached) {
          _dist = 0;
          _defender.sprite.flash(damageFlashTime, Color.black);
        }
      }
      else {
        _dist += attackSpeed * time;
        _attacker.pos = _attacker.pos.movedTo(_startPos, _dist, _returned);
        if (_returned) {
          _attacks.popFront;
          if (_attacks.empty) { // no attacks left to show
            _initialAttacker.moved = true; // end attacker's turn
            return new PlayerTurn;
          }
          else {
            return new ExecuteCombat(_attacks, _initialAttacker);
          }
        }
      }
      return null;
    }

    private:
    CombatResult[] _attacks;
    Battler _attacker, _defender;
    Battler _initialAttacker;
    Vector2i _startPos, _endPos;
    bool _destReached, _returned;
    float _dist = 0;
  }

  private class TileCursor {
    this() {
      _sprite = new AnimatedSprite("target", shade);
    }

    /// tile under cursor
    @property {
      Tile tile() { return _map.tileAt(_row, _col); }

      int left()   { return cast(int) (_pos.x - _map.tileWidth / 2); }
      int right()  { return cast(int) (_pos.x + _map.tileWidth / 2); }
      int top()    { return cast(int) (_pos.y - _map.tileHeight / 2); }
      int bottom() { return cast(int) (_pos.y + _map.tileHeight / 2); }
    }

    void update(float time) {
      _sprite.update(time);
    }

    void handleInput(InputManager input) {
      Vector2i direction;
      if (input.scrollDirection == Vector2i.Zero) {
        _pos = _map.tileCoordToPos(_row, _col);
      }
      else if (input.speedScroll) {
        direction = input.scrollDirection * 2;
      }
      else {
        direction = input.scrollDirection;
      }

      _pos = (_pos + direction * scrollSpeed).clamp(_map.bounds.topLeft, _map.bounds.bottomRight - _map.tileSize / 2);

      _camera.x = min(_camera.x, left);
      _camera.right = max(_camera.right, right);
      _camera.y = min(_camera.y, top);
      _camera.bottom = max(_camera.bottom, bottom);

      _camera.keepInside(_map.bounds);

      _row = _map.rowAt(cast(Vector2i)_pos);
      _col = _map.colAt(cast(Vector2i)_pos);
    }

    void draw() {
      _sprite.draw(cast(Vector2i)_pos - _camera.topLeft);
    }

    void place(Tile tile) {
      _pos = _map.tileToPos(tile);
      _row = tile.row;
      _col = tile.col;

      _camera.x = min(_camera.x, left);
      _camera.right = max(_camera.right, right);
      _camera.y = min(_camera.y, top);
      _camera.bottom = max(_camera.bottom, bottom);

      _camera.keepInside(_map.bounds);
    }

    private:
    enum shade = ucolor(255, 0, 0, 255);
    Vector2f _pos = Vector2f.Zero;
    int _row, _col;
    Sprite _sprite;
  }
}
