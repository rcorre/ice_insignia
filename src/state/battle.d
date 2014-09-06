module state.battle;

import std.array;
import std.math;
import std.range;
import std.typecons : tuple;
import std.algorithm : map, all;
import allegro;
import state.gamestate;
import state.combat_calc;
import util.input;
import model.battler;
import model.character;
import model.item;
import gui.all;
import ai.all;
import graphics.all;
import tilemap.all;
import geometry.all;

private enum {
  scrollSpeed = 12,       /// camera scroll rate (pixels/sec)
  battlerMoveSpeed = 300, /// battler move speed (pixels/sec)
  attackSpeed = 12,       /// movement rate of attack animation
  attackShiftDist = 8,    /// pixels to shift when showing attack
  pauseTime = 0.5,        /// time to pause between states

  tileInfoPos    = cast(Vector2i) Vector2f(Settings.screenW * 0.9f, Settings.screenH * 0.9f),
  battlerInfoPos = cast(Vector2i) Vector2f(Settings.screenW * 0.1f, Settings.screenH * 0.9f),

  battleInfoOffset = Vector2i(16, 16),
  characterSheetPos = Vector2i(128, 56),
  itemInfoOffset = Vector2i(220, 0),
}

class Battle : GameState {
  this(LevelData data, Character[] playerUnits) {
    _map = data.map;
    _enemies = data.enemies;
    foreach(enemy ; _enemies) { // place enemies
      placeBattler(enemy, _map.tileAt(enemy.row, enemy.col));
    }
    foreach(idx, character ; playerUnits.take(data.spawnPoints.length)) { // place player units at spawn points
      auto pos = data.spawnPoints[idx];
      auto tile = _map.tileAtPos(pos);
      Battler b = new Battler(character, tile.row, tile.col, pos, BattleTeam.ally);
      _allies ~= b;
      placeBattler(b, tile);
    }

    _neutrals = [];
    _battlers = _enemies ~ _allies ~ _neutrals;
    _camera = Rect2i(0, 0, Settings.screenW, Settings.screenH);
    _input = new InputManager;
    _tileCursor = new TileCursor;
    _state = new PlayerTurn;
  }

  override GameState update(float time) {
    _input.update(time);
    _tileCursor.update(time);

    foreach(battler ; _battlers) {
      battler.update(time);
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
      if (tile.battler) {
        _battlerInfoBox = new BattlerInfoBox(battlerInfoPos, tile.battler);
      }
      else {
        _battlerInfoBox = null;
      }
    }
    else {
      _tileInfoBox = null;
      _battlerInfoBox = null;
    }
    return null;
  }

  override void draw() {
    _map.draw(Vector2i(0,0), _camera);
    foreach(battler ; _battlers) {
      auto sprite = battler.sprite;
      auto rect = Rect2i.CenteredAt(battler.pos, sprite.width, sprite.height);
      if (_camera.intersects(rect)) {
        battler.draw(_camera.topLeft);
      }
    }
    _state.draw();

    _tileCursor.draw();
    if (_tileInfoBox) {
      _tileInfoBox.draw();
    }
    if (_battlerInfoBox) {
      _battlerInfoBox.draw();
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
  BattlerInfoBox _battlerInfoBox;
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
      if (!_turnOver) {
        _unitJumpList = cycle(array(moveableAllies));
        _tileCursor.active = true;
      }
    }

    override State update(float time) {
      _tileCursor.handleInput(_input);
      if (_turnOver || _input.endTurn) {
        foreach(battler ; _allies) {
          battler.moved = false;
        }
        return new EnemyTurn;
      }

      _cursorRow = cast(int) clamp(_cursorRow, 0, _map.numRows - 1);
      _cursorCol = cast(int) clamp(_cursorCol, 0, _map.numCols - 1);

      // select unit under cursor
      if (_input.confirm) {
        auto tile = _tileCursor.tile;
        if (tile && tile.battler && !tile.battler.moved) {
          return new PlayerUnitSelected(tile.battler, tile);
        }
      }
      // jump to next ready unit
      else if (_input.next) {
        auto nextBattler = _unitJumpList[_unitJumpIdx++];
        _tileCursor.place(_map.tileAt(nextBattler.row, nextBattler.col));
      }
      else if (_input.previous) {
        auto nextBattler = _unitJumpList[_unitJumpIdx--];
        _tileCursor.place(_map.tileAt(nextBattler.row, nextBattler.col));
      }
      else if (_input.inspect) {
        auto pos = Vector2i(Settings.screenW / 2, Settings.screenH / 2);
        auto battlerToInspect = _tileCursor.tile.battler;
        if (_characterSheet) {
          _characterSheet = null;
        }
        else if (battlerToInspect) {
          _characterSheet = new CharacterSheet(characterSheetPos, battlerToInspect);
        }
      }
      else if (_input.cancel) {
        _characterSheet = null;
      }

      // TODO: make character sheet a new state

      return null;
    }

    override void draw() {
      if (_characterSheet) {
        _characterSheet.draw();
      }
    }

    private:
    bool _turnOver;
    uint _unitJumpIdx;
    Cycle!(Battler[]) _unitJumpList;
    CharacterSheet _characterSheet;
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
        if (!_selectedPath) {
          _selectedPath = _pathFinder.pathToward(tile);
        }
        if (_selectedPath && _input.confirm) {
          _tileCursor.active = false;
          return new MoveBattler(_battler, _tile, _selectedPath);
        }
      }
      if (_input.cancel) {
        return new PlayerTurn;
      }
      return null;
    }

    override void draw() {
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
        if (_battler.team == BattleTeam.ally) {
          return new ChooseBattlerAction(_battler, _endTile, _originTile);
        }
        else {
          auto behavior = getAI(_battler, _map, _allies, _enemies);
          return new EnemyChooseAction(_battler, behavior);
        }
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
      _selectionView = new StringMenu(selectPos, getActions(), &handleSelection);
      _selectionView.keepInside(Rect2i(0, 0, _camera.width, _camera.height));
    }

    override State update(float time) {
      if (_requestedState) {
        return _requestedState;
      }

      _targetSprite.update(time);
      if (_inventoryView) {
        _inventoryView.handleInput(_input);
      }
      else {
        _selectionView.handleInput(_input);
      }

      if (_input.cancel) {
        if (_inventoryView) {
          _inventoryView = null;
        }
        else {
          placeBattler(_battler, _prevTile);
          return new PlayerTurn;
        }
      }
      return null;
    }

    override void draw() {
      foreach(enemy ; _enemies) {
        if (_battler.canAttack(enemy)) {
          _targetSprite.draw(enemy.pos - _camera.topLeft);
        }
      }
      if (_inventoryView) {
        _inventoryView.draw();
        if (_itemView) {
          _itemView.draw();
        }
      }
      else {
        _selectionView.draw();
      }
    }

    private:
    Battler _battler;
    Battler[] _enemiesInRange;
    Tile _currentTile, _prevTile;
    StringMenu _selectionView;
    InventoryMenu _inventoryView;
    ItemView _itemView;
    AnimatedSprite _targetSprite;
    State _requestedState;

    string[] getActions() {
      string[] actions;
      if (!_enemiesInRange.empty) {
        actions ~= "Attack";
      }
      actions ~= "Inventory";
      actions ~= "Wait";
      return actions;
    }

    void handleSelection(string action) {
      switch(action) {
        case "Attack":
          _requestedState = new ConsiderAttack(_battler, _enemiesInRange);
          break;
        case "Inventory":
          auto menuPos = _battler.pos - _camera.topLeft - Vector2i(50, 50);
          _inventoryView = new InventoryMenu(menuPos, _battler.items, &selectItem, &showItemInfo);
          _inventoryView.keepInside(Rect2i(0, 0, _camera.width, _camera.height));
          break;
        case "Wait":
          _battler.moved = true;
          _requestedState = new PlayerTurn;
          break;
        default:
      }
    }

    void selectItem(Item item) {
      _battler.equippedWeapon = item;
    }

    void showItemInfo(Item item ,Rect2i rect) {
      _itemView = item ? new ItemView(item, rect.topLeft + itemInfoOffset) : null;
      if (_itemView) {
        _itemView.keepInside(Rect2i(0, 0, _camera.width, _camera.height));
      }
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
        auto series = constructAttackSeries(_attack, _counter);
        return new ExecuteCombat(series, _attacker, series.playerXp);
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
    this(CombatResult[] attacks, Battler initialAttacker, int playerXp) {
      _attacks = attacks;
      _result = attacks[0];
      _attacker = _result.attacker;
      _defender = _result.defender;
      _initialAttacker = initialAttacker;
      showBattlerInfoBoxes(_attacker, _defender);
      _playerXp = playerXp;
    }

    override State update(float time) {
      if (!_started) {
        auto attackDirection = (_defender.pos - _attacker.pos).normalized;
        _attacker.sprite.shift(attackDirection * attackShiftDist, attackSpeed);
        if (_result.hit) {
          _defender.dealDamage(_result.damageDealt);
        }
        _started = true;
      }

      if (_attacker.sprite.isJiggling || _defender.sprite.isFlashing || _attacker.isHpTransitioning ||
          _defender.isHpTransitioning)
      {
        return null;
      }

      _attacks.popFront;
      if (_attacks.empty || !_attacker.alive || !_defender.alive) { // no attacks left to show
        Battler enemy = _attacker.team == BattleTeam.ally ? _defender : _attacker;
        enemy.hideInfoBox;
        _initialAttacker.moved = true; // end attacker's turn
        Battler friendly = _attacker.team == BattleTeam.ally ? _attacker : _defender;
        bool wasPlayerTurn = _initialAttacker.team == BattleTeam.ally;
        return new Wait(pauseTime, new AwardXp(friendly, _playerXp, wasPlayerTurn));
      }
      else {
        return new Wait(pauseTime, new ExecuteCombat(_attacks, _initialAttacker, _playerXp));
      }
      return null;
    }

    private:
    CombatResult[] _attacks;
    CombatResult _result;
    Battler _attacker, _defender;
    Battler _initialAttacker;
    bool _started;
    int _playerXp;

    // these methods try to place info boxes so they are visible and next to the battler they represent
    void showBattlerInfoBoxes(Battler b1, Battler b2) {
      // check if b1 is topRight
      if (b1.row < b2.row || b1.col > b2.col) {
        showTopRightInfo(b1);
        showBottomLeftInfo(b2);
      }
      else {
        showTopRightInfo(b2);
        showBottomLeftInfo(b1);
      }
    }

    void showTopRightInfo(Battler b) {
      auto size = Vector2i(BattlerInfoBox.width, BattlerInfoBox.height);
      auto shift = Vector2i(size.x, -size.y) / 2 + Vector2i(battleInfoOffset.x, -battleInfoOffset.y);
      auto area = Rect2i.CenteredAt(b.pos + shift - _camera.topLeft, size.x, size.y);
      if (area.top < 0) { area.y += shift.y; }
      if (area.right > _camera.width) { area.x -= shift.x; }

      b.showInfoBox(area.topLeft);
    }

    void showBottomLeftInfo(Battler b) {
      auto size = Vector2i(BattlerInfoBox.width, BattlerInfoBox.height);
      auto shift = Vector2i(-size.x, size.y) / 2 + Vector2i(-battleInfoOffset.x, battleInfoOffset.y);
      auto area = Rect2i.CenteredAt(b.pos + shift - _camera.topLeft, size.x, size.y);
      if (area.left < 0) { area.x += shift.x; }
      if (area.bottom > _camera.height) { area.y -= shift.y; }

      b.showInfoBox(area.topLeft);
    }
  }

  class AwardXp : State {
    this(Battler battler, int xp, bool wasPlayerTurn) {
      _battler = battler;
      _xp = xp;
      _wasPlayerTurn = wasPlayerTurn;
    }

    void start() {
      _leveled = _battler.awardXp(_xp, _awards, _leftoverXp);
      _started = true;
    }

    override State update(float time) {
      if (!_started) { start; }
      if (_battler.isXpTransitioning) {
        return null;
      }
      else if (_leveled) {
        return new Wait(pauseTime, new LevelUp(_battler, _awards, _wasPlayerTurn, _leftoverXp));
      }
      else {
        _battler.hideInfoBox;
        return _wasPlayerTurn ? new PlayerTurn : new EnemyTurn;
      }
    }

    private:
    Battler _battler;
    bool _started;
    bool _wasPlayerTurn;
    bool _leveled;
    AttributeSet _awards;
    int _xp, _leftoverXp;
  }

  class LevelUp : State {
    this(Battler battler, AttributeSet awards, bool wasPlayerTurn, int leftoverXp) {
      _view = new LevelUpView(Vector2i.Zero, battler, awards);
      _wasPlayerTurn = wasPlayerTurn;
      _battler = battler;
      _awards = awards;
      _leftoverXp = leftoverXp;
    }

    override State update(float time) {
      _view.update(time);
      if (_view.doneAnimating && (_input.confirm || _input.cancel || _input.inspect)) {
        _battler.applyLevelUp(_awards);
        if (_leftoverXp > 0) {
          return new AwardXp(_battler, _leftoverXp, _wasPlayerTurn);
        }
        return _wasPlayerTurn ? new PlayerTurn : new EnemyTurn;
      }
      return null;
    }

    override void draw() {
      _view.draw;
    }

    private:
    LevelUpView _view;
    bool _wasPlayerTurn;
    int _leftoverXp;
    AttributeSet _awards;
    Battler _battler;
  }

  class Wait : State {
    this(float time, State nextState) {
      _timer = time;
      _nextState = nextState;
    }

    override State update(float time) {
      _timer -= time;
      if (_timer < 0) {
        return _nextState;
      }
      return null;
    }

    private:
    float _timer;
    State _nextState;
  }

  class EnemyTurn : State {
    this() {
      auto findReady = _enemies.find!"!a.moved";
      if (findReady.empty) { // no unmoved enemies -- player turn
        _battler = null;
      }
      else {
        _battler = findReady.front;
        _behavior = new AgressiveAI(_battler, _map, _allies, _enemies);
      }
    }

    override State update(float time) {
      if (_battler is null) {
        foreach(enemy ; _enemies) {
          enemy.moved = false;
        }
        return new PlayerTurn;
      }

      auto path = _behavior.moveRequest;
      if (path) {
        auto selfTerrain = _map.tileAt(_battler.row, _battler.col);
        return new MoveBattler(_battler, selfTerrain, path);
      }
      return new EnemyChooseAction(_battler, _behavior);
    }

    private:
    Battler _battler;
    AI _behavior;
  }

  class EnemyChooseAction : State {
    this(Battler battler, AI behavior) {
      _battler = battler;
      _behavior = behavior;
    }

    override State update(float time) {
      auto selfTerrain = _map.tileAt(_battler.row, _battler.col);
      auto target = _behavior.attackRequest;
      if (target) {
        auto targetTerrain = _map.tileAt(target.row, target.col);
        auto attack  = new CombatPrediction(_battler, target, targetTerrain);
        auto counter = new CombatPrediction(target, _battler, selfTerrain);
        auto series = constructAttackSeries(attack, counter);
        return new ExecuteCombat(series, _battler, series.playerXp);
      }

      _battler.moved = true; // skip turn
      return new Wait(1, new EnemyTurn);
    }

    private:
    Battler _battler;
    AI _behavior;
  }

  private class TileCursor {
    bool active = true;

    this() {
      _sprite = new AnimatedSprite("target", shade);
    }

    /// tile under cursor
    @property {
      Tile tile() { return active ? _map.tileAt(_row, _col) : null; }

      int left()   { return cast(int) (_pos.x - _map.tileWidth / 2); }
      int right()  { return cast(int) (_pos.x + _map.tileWidth / 2); }
      int top()    { return cast(int) (_pos.y - _map.tileHeight / 2); }
      int bottom() { return cast(int) (_pos.y + _map.tileHeight / 2); }
    }

    void update(float time) {
      if (active) {
        _sprite.update(time);
      }
    }

    void handleInput(InputManager input) {
      if (!active) { return; }
      Vector2f direction;
      if (input.scrollDirection == Vector2f.Zero) {
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
      if (active) {
        _sprite.draw(cast(Vector2i)_pos - _camera.topLeft);
      }
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
