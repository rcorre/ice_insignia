module state.battle;

import std.array;
import std.math;
import std.range;
import std.algorithm;
import std.container;
import std.variant;
import allegro;
import state.gamestate;
import state.combat_calc;
import state.preparation;
import util.all;
import model.all;
import gui.all;
import ai.all;
import graphics.all;
import tilemap.all;
import geometry.all;

enum VictoryCondition {
  defeatBoss,
  seizeFlag,
  survive,
}

string victoryDescription(VictoryCondition cond, int number) {
  final switch (cond) with (VictoryCondition) {
    case defeatBoss:
      return number > 1 ? format("defeat %d champions", number) : "defeat the champion";
    case seizeFlag:
      return number > 1 ? format("sieze %d banners", number) : "sieze the banner";
    case survive:
      return format("survive for %d turns", number);
  }
}

private enum {
  scrollSpeed = 300,       /// camera scroll rate (pixels/sec)
  battlerMoveSpeed = 300, /// battler move speed (pixels/sec)
  attackSpeed = 12,       /// movement rate of attack animation
  attackShiftDist = 8,    /// pixels to shift when showing attack
  pauseTime = 0.5,        /// time to pause between states
  walkPauseTime = 0.1,    /// time to pause before moving battler to sync sound

  chestFadeTime = 0.5,
  doorFadeTime = 0.5,

  tileInfoPos    = cast(Vector2i) Vector2f(Settings.screenW * 0.9f, Settings.screenH * 0.9f),
  battlerInfoPos = cast(Vector2i) Vector2f(Settings.screenW * 0.1f, Settings.screenH * 0.9f),

  battleInfoOffset = Vector2i(16, 16),
  characterSheetPos = Vector2i(128, 56),
  talentMenuPos = Vector2i(600, 40),
  screenCenter = Vector2i(Settings.screenW, Settings.screenH) / 2,
  hpTransitionRate = 20,

  inspectIconOffset = Vector2i(16, -20),
  selectIconOffset = Vector2i(16, 20),

  targetShade = Color.red,
}

class Battle : GameState {
  this(LevelData levelData, Character[] playerUnits, SaveData saveData) {
    _saveData = saveData;
    _map = levelData.map;
    _enemies = levelData.enemies;
    _objects = levelData.objects;
    foreach(enemy ; _enemies) { // place enemies
      placeBattler(enemy, _map.tileAt(enemy.row, enemy.col));
    }
    foreach(idx, character ; playerUnits.take(levelData.spawnPoints.length)) { // place player units at spawn points
      auto pos = levelData.spawnPoints[idx];
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
    _objective = levelData.objective;
    _victoryCounter = levelData.victoryValue;
    pushState(new PlayerTurn);
    playBgMusic("battle");
    _walkSound = new SoundSample("walk");
    _xpSound = new SoundSample("experience");
    _targetSprite = new AnimatedSprite("target", targetShade);
  }

  override GameState update(float time) {
    _input.update(time);
    _tileCursor.update(time, _input);
    _targetSprite.update(time);

    foreach(battler ; _battlers) {
      battler.update(time);
    }

    currentState.updateState(time);

    // handle mouse -- display tile info
    auto tile = _tileCursor.tile;
    if (tile) {
      _tileInfoBox = new TileInfoBox(tileInfoPos, tile.name, tile.defense, tile.avoid);
      auto wall = cast(Wall) tile.object;
      if (tile.battler) {
        _battlerInfoBox = new BattlerInfoBox(battlerInfoPos, tile.battler);
      }
      else if (wall)  {
        _battlerInfoBox = new BattlerInfoBox(battlerInfoPos, wall);
      }
      else {
        _battlerInfoBox = null;
      }
    }
    else {
      _tileInfoBox = null;
      _battlerInfoBox = null;
    }
    return _nextState;
  }

  void endBattle(bool victory) {
    _nextState = new Preparation(_saveData, victory);
  }

  override void handleEvent(ALLEGRO_EVENT ev) {
    if (ev.type == ALLEGRO_EVENT_JOYSTICK_CONFIGURATION) {
      _input.reconfigureGamepad();
    }
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
    foreach(battler ; _battlers) { // second pass for info boxes
      auto sprite = battler.sprite;
      auto rect = Rect2i.CenteredAt(battler.pos, sprite.width, sprite.height);
      if (_camera.intersects(rect)) {
        battler.drawInfoBox;
      }
    }
    currentState.drawState();

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
  InputManager _input;
  Battler[] _battlers, _allies, _enemies, _neutrals;
  TileObject[] _objects;
  SList!State _stateStack;
  TileInfoBox _tileInfoBox;
  BattlerInfoBox _battlerInfoBox;
  TileCursor _tileCursor;
  VictoryCondition _objective;
  GameState _nextState;
  SaveData _saveData;
  SoundSample _walkSound, _xpSound;
  int _victoryCounter;
  AnimatedSprite _targetSprite;

  // state management
  @property auto currentState() { return _stateStack.front; }
  void pushState(State state) {
    _stateStack.insertFront(state);
  }
  void popState() {
    assert(!_stateStack.empty);
    _stateStack.front.onExit();
    _stateStack.removeFront;
  }
  void setState(State state) {
    popState();
    pushState(state);
  }

  void placeBattler(Battler b, Tile t) {
    auto currentTile = _map.tileAt(b.row, b.col);
    currentTile.battler = null; // remove from current tile
    t.battler = b;
    b.row = t.row;
    b.col = t.col;
    b.pos = _map.tileCoordToPos(t.row, t.col);
  }

  bool victoryCondMet() {
    final switch (_objective) with (VictoryCondition) {
      case defeatBoss:
        return !_enemies.canFind!(x => x.isBoss && x.alive);
      case seizeFlag:
        return _objects.map!(x => cast(Banner) x)
          .filter!(x => x !is null)
          .all!(x => x.team == BattleTeam.ally);
      case survive:
        return _victoryCounter == 0;
    }
  }

  bool defeatCondMet() {
    return _allies.all!(x => !x.alive);  // all allies defeated
  }

  abstract class State {
    private bool _started;
    final void updateState(float time) {
      if (!_started) {
        onStart();
        _started = true;
      }
      update(time);
    }
    final void drawState() {
      if (_started) {
        draw();
      }
    }
    void update(float time);
    void draw() {}
    void onStart() {}
    void onExit() {}
  }

  class PlayerTurn : State {
    this() {
    }

    override void onStart() {
      auto moveableAllies = _allies.filter!"!a.moved";
      _turnOver = moveableAllies.empty;
      if (!_turnOver && !moveableAllies.empty) {
        _unitJumpList = cycle(array(moveableAllies));
        _inspectJumpList = cycle(_allies ~ _enemies);
        _tileCursor.active = true;
      }
      foreach(battler ; _battlers) {
        battler.hideInfoBox;
      }
      _victorious = victoryCondMet();
      _defeated = defeatCondMet();
    }

    override void update(float time) {
      if (_victorious) {
        setState(new BattleOver(true));
        return;
      }
      else if (_defeated) {
        setState(new BattleOver(false));
        return;
      }
      if (_turnOver) {
        foreach(battler ; _allies) {
          battler.passTurn();
        }
        if (_objective == VictoryCondition.survive) {
          --_victoryCounter;
        }
        setState(new EnemyTurn);
      }

      // select unit under cursor
      if (_input.confirm) {
        auto tile = _tileCursor.tile;
        auto battler = _tileCursor.battler;
        if (tile && battler && !battler.moved && battler.team == BattleTeam.ally) {
          setState(new PlayerUnitSelected(tile.battler, tile));
        }
      }
      else if (_input.endTurn) {
        setState(new ConsiderSkip);
      }
      // jump to next ready unit
      else if (_input.next) {
        if (_characterSheet) {
          auto battlerToInspect = _inspectJumpList[++_inspectJumpIdx];
          _characterSheet = new CharacterSheet(characterSheetPos, battlerToInspect);
        }
        else {
          auto nextBattler = _unitJumpList[_unitJumpIdx++];
          _tileCursor.place(_map.tileAt(nextBattler.row, nextBattler.col));
        }
      }
      else if (_input.previous) {
        if (_characterSheet) {
          auto battlerToInspect = _inspectJumpList[--_inspectJumpIdx];
          _characterSheet = new CharacterSheet(characterSheetPos, battlerToInspect);
        }
        else {
          auto nextBattler = _unitJumpList[_unitJumpIdx--];
          _tileCursor.place(_map.tileAt(nextBattler.row, nextBattler.col));
        }
      }
      else if (_input.inspect) {
        if (_characterSheet) {
          _characterSheet = null;
          _tileCursor.active = true;
        }
        else {
          auto pos = Vector2i(Settings.screenW / 2, Settings.screenH / 2);
          auto battlerToInspect = _tileCursor.tile.battler;
          if (battlerToInspect) {
            _characterSheet = new CharacterSheet(characterSheetPos, battlerToInspect);
            _inspectJumpIdx = _inspectJumpList.countUntil(battlerToInspect);
            _tileCursor.active = false;
          }
        }
      }
      else if (_input.cancel) {
        _characterSheet = null;
        _tileCursor.active = true;
      }
      else if (_input.start) {
        pushState(new ShowMenu);
      }
    }

    override void draw() {
      if (_characterSheet) {
        _characterSheet.draw();
      }
      auto battler = _tileCursor.battler;
      auto pos = cast(Vector2i) _tileCursor.pos - _camera.topLeft + inspectIconOffset;
      if (battler is null) {
        drawInputIcon("start", pos, _input.gamepadConnected, "  Menu");
      }
      else {
        drawInputIcon("inspect", pos, _input.gamepadConnected, "inspect");
        if (battler.team == BattleTeam.ally) {
          pos = cast(Vector2i) _tileCursor.pos - _camera.topLeft + selectIconOffset;
          drawInputIcon("confirm", pos, _input.gamepadConnected, "select");
        }
      }
    }

    private:
    bool _turnOver, _victorious, _defeated;
    ulong _unitJumpIdx, _inspectJumpIdx;
    Cycle!(Battler[]) _unitJumpList, _inspectJumpList;
    CharacterSheet _characterSheet;
  }

  class ShowMenu : State {
    this() {
      _menu = new PreferencesMenu(screenCenter - Vector2i(50, 50));
    }

    override {
      void onStart() {
        _tileCursor.active = false;
      }

      void update(float time) {
        _menu.handleInput(_input);
        if (_input.cancel) {
          _tileCursor.active = true;
          popState();
        }
      }

      void draw() {
        _menu.draw();
      }
    }

    private:
    PreferencesMenu _menu;
  }

  class PlayerUnitSelected : State {
    this(Battler battler, Tile tile) {
      _battler = battler;
      _tile = tile;
      _pathFinder = new PathFinder(_map, _tile, _battler);
      _tileHighlight = new AnimatedSprite("tile_highlight");
      _tileHighlight.tint = moveTint;
    }

    override void update(float time) {
      _tileHighlight.update(time);
      auto tile = _tileCursor.tile;
      if (tile) {
        _selectedPath = _pathFinder.pathTo(tile);
        if (!_selectedPath) {
          _selectedPath = _pathFinder.pathToward(tile);
        }
        if (_selectedPath && _input.confirm) {
          _tileCursor.active = false;
          setState(new Wait(walkPauseTime, new MoveBattler(_battler, _tile, _selectedPath)));
        }
      }
      if (_input.cancel) {
        setState(new PlayerTurn);
      }
    }

    override void draw() {
      foreach (tile ; _pathFinder.tilesInRange) {
        auto pos = _map.tileToPos(tile) - _camera.topLeft;
        _tileHighlight.draw(pos);
      }

      if (_selectedPath) {
        auto nodes = array(_selectedPath.map!(t => _map.tileToPos(t) - _camera.topLeft));
        nodes.draw(lineWidth, lineTint);
        drawInputIcon("confirm", nodes.back, _input.gamepadConnected, "move");
      }
      drawInputIcon("cancel", _battler.pos - _camera.topLeft, _input.gamepadConnected, "back");
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
      _walkSound.play();
    }

    override void onStart() {
    }

    override void update(float time) {
      if (_path.empty) { /// completed move
        _walkSound.stop();
        placeBattler(_battler, _endTile); // place battler on final tile
        if (_battler.team == BattleTeam.ally) {
          setState(new ChooseBattlerAction(_battler, _endTile, _originTile));
        }
        else {
          auto behavior = getAI(_battler, _map, _allies, _enemies);
          setState(new EnemyChooseAction(_battler, behavior));
        }
      }
      else {
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
      }
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
      auto enemiesInRange = array(_enemies.filter!(a => _battler.canAttack(a)).map!(a =>
            Variant(a)));
      auto wallsInRange = array(_objects.filter!(a => _battler.canAttack(a)).map!(a => Variant(a)));
      _targetsInRange = enemiesInRange ~ wallsInRange;
      _stealableEnemies = array(_enemies.filter!(a => _battler.canStealFrom(a)));
      _magicableAllies = array(_allies.filter!(a => !_battler.magicOptions(a).empty));
      // find openable object
      if (cast(Chest) currentTile.object && _battler.getChestOpener(currentTile.object) !is null) {
        _chestTile = currentTile;
      }
      auto door = _objects.find!(x => battler.getDoorOpener(x) !is null);
      if (!door.empty) {
        _doorTile = _map.tileAt(door.front.row, door.front.col);
      }
      auto banner = cast(Banner) currentTile.object;
      if (banner !is null && banner.team != _battler.team) { // is there a banner to be seized?
        _bannerTile = currentTile;
      }
      auto neighbors = _map.neighbors(currentTile);
      _adjacentAllies = array(_map.neighbors(currentTile).map!(a => a.battler)
          .filter!(a => a !is null && a.team == BattleTeam.ally));
      // create menu
      auto selectPos = _battler.pos - _camera.topLeft - Vector2i(50, 50);
      _selectionView = new StringMenu(selectPos, getActions(), &handleSelection);
      _selectionView.keepInside(Rect2i(0, 0, _camera.width, _camera.height));
    }

    override void update(float time) {
      if (_requestedState) {
        setState(_requestedState);
        return;
      }

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
          setState(new PlayerTurn);
        }
      }
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
    Battler[] _stealableEnemies;
    Battler[] _adjacentAllies;
    Battler[] _magicableAllies;
    Variant[] _targetsInRange;
    Tile _doorTile, _chestTile, _bannerTile; // tile holding object of interest
    Tile _currentTile, _prevTile;
    StringMenu _selectionView;
    InventoryMenu _inventoryView;
    ItemView _itemView;
    State _requestedState;

    string[] getActions() {
      string[] actions;
      if (!_targetsInRange.empty) {
        actions ~= "Attack";
      }
      if (!_stealableEnemies.empty) {
        actions ~= "Steal";
      }
      if (_doorTile !is null) {
        actions ~= "Door";
      }
      if (_chestTile !is null) {
        actions ~= "Chest";
      }
      if (_bannerTile !is null) {
        actions ~= "Seize";
      }
      if (!_adjacentAllies.empty) {
        actions ~= "Trade";
      }
      if (!_magicableAllies.empty) {
        actions ~= "Magic";
      }
      actions ~= "Inventory";
      actions ~= "Wait";
      return actions;
    }

    void handleSelection(string action) {
      switch(action) {
        case "Attack":
          _requestedState = new ConsiderAttack(_battler, _targetsInRange, _prevTile);
          break;
        case "Inventory":
          _inventoryView = new InventoryMenu(screenCenter, _battler.items, &selectItem,
              &showItemInfo, &itemInputString, InventoryMenu.ShowPrice.no, true, true);
          break;
        case "Wait":
          _battler.moved = true;
          _requestedState = new PlayerTurn;
          break;
        case "Steal":
          _requestedState = new ConsiderSteal(_battler, _stealableEnemies);
          break;
        case "Chest":
          _requestedState = new OpenChest(_battler);
          break;
        case "Seize":
          _requestedState = new OpenChest(_battler);
          break;
        case "Door":
          _requestedState = new OpenDoor(_battler, _doorTile);
          break;
        case "Trade":
          _requestedState = new Trade(_battler, _adjacentAllies, _prevTile);
          break;
        case "Magic":
          _requestedState = new ConsiderMagic(_battler, _magicableAllies, _prevTile);
          break;
        default:
      }
    }

    void selectItem(Item item) {
      if (_battler.canWield(item)) {
        _battler.equippedWeapon = item;
      }
      else if (item.useOnSelf) {
        setState(new UseItem(_battler, item));
      }
    }

    void showItemInfo(Item item ,Rect2i rect) {
      _itemView = item ? new ItemView(item, rect.topLeft - ItemView.size / 2) : null;
      if (_itemView) {
        _itemView.keepInside(Rect2i(0, 0, _camera.width, _camera.height));
      }
    }

    string itemInputString(Item item) {
      if (_battler.canWield(item)) {
        return "equip";
      }
      else if (item.useOnSelf) {
        return "use";
      }
      return null;
    }
  }

  class UseItem : State {
    this(Battler battler, Item item) {
      _battler = battler;
      _item = item;
    }

    override void onStart() {
      bool _consumed = _battler.useItem(_item);
    }

    override void update(float time) {
      popState();
      _battler.moved = true;
      pushState((_battler.team == BattleTeam.ally ? new PlayerTurn : new EnemyTurn));
      pushState(new RestoreHealth(_battler, _item.heal, _item.statEffects));
      if (_consumed) {
        auto notification = new ItemNotification(screenCenter, _item, " consumed");
        pushState(new ShowItemNotification(notification));
      }
    }

    private:
    Battler _battler;
    Item _item;
    bool _consumed;
  }

  class RestoreHealth : State {
    this(Battler battler, int amount, AttributeSet statEffects) {
      _battler = battler;
      _amount = amount;
      _statEffects = statEffects;
      _anim = new AnimatedSprite("buff");
    }

    override void onStart() {
      _battler.showInfoBox(screenCenter);
      _battler.heal(_amount);
      _battler.applyStatEffects(_statEffects);
      string[] text = [format("%+d hp", _amount)];
      foreach(attr ; EnumMembers!Attribute) {
        int val = _statEffects[attr];
        if (attr != 0) {
          text ~= format("%+d %s", val, attr);
        }
      }
      playSound("heal");
    }

    override void update(float time) {
      _anim.update(time);
      if (_anim.isStopped && !(_battler.isHpTransitioning || _battler.sprite.isFlashing)) {
        popState();
      }
    }

    override void draw() {
      _anim.draw(_battler.pos - _camera.topLeft);
    }

    private:
    Battler _battler;
    int _amount;
    AnimatedSprite _anim;
    AttributeSet _statEffects;
  }

  class OpenDoor : State {
    this(Battler battler, Tile tile) {
      _battler = battler;
      _tile = tile;
      _sprite = tile.object.sprite;
    }

    override void onStart() {
      _sprite.fade(doorFadeTime, Color.clear);
      playSound("open");
    }

    override void update(float time) {
      _sprite.update(time);
      if (!_sprite.isFlashing) {
        popState();

        Item item = _battler.getDoorOpener(_tile.object);
        bool broke = _battler.useItem(item);

        _battler.moved = true;
        _tile.object = null; // remove door
        if (_battler.team == BattleTeam.ally) {
          int xp = computeLockpickXp(_battler);
          pushState(new AwardXp(_battler, xp, true));
        }
        else {
          pushState(new EnemyTurn);
        }
        if (broke) {
          auto notification = new ItemNotification(screenCenter, item, " consumed");
          pushState(new ShowItemNotification(notification));
        }
      }
    }

    private:
    Battler _battler;
    Tile _tile;
    Sprite _sprite;
    Item _brokenItem;
  }

  class ShowItemNotification : State {
    this(ItemNotification notification) {
      _notification = notification;
    }

    override void draw() {
      _notification.draw();
    }

    override void update(float time) {
      if (_input.confirm) {
        popState();
      }
    }

    private ItemNotification _notification;
  }

  class OpenChest : State {
    this(Battler battler) {
      _battler = battler;
      _tile = _map.tileAtPos(_battler.pos);
      _chest = cast(Chest) _tile.object;
      assert(_chest, "OpenChest could not find on battler's tile");
      assert(_chest.item, "no item in chest");
    }

    override void onStart() {
      _chest.sprite.fade(chestFadeTime, Color.clear);
    }

    override void update(float time) {
      _chest.sprite.update(time);
      if (!_chest.sprite.isFlashing) {
        popState();
        _battler.moved = true;
        _tile.object = null;
        auto item = _battler.getChestOpener(_chest);
        bool broke = _battler.useItem(item);
        if (_broke) {
          auto notification = new ItemNotification(screenCenter, item, " consumed");
          pushState(new ShowItemNotification(notification));
        }
        if (_battler.team == BattleTeam.ally) {
          int xp = computeLockpickXp(_battler);
          pushState(new AwardXp(_battler, xp, true, _chest.item));
        }
        else {
          pushState(new EnemyTurn);
        }
      }
    }

    private:
    Battler _battler;
    Chest _chest;
    Tile _tile;
    bool _broke;
  }

  class ConsiderAttack : State {
    this(Battler attacker, Variant[] targets, Tile prevTile) {
      assert(!targets.empty);
      _prevTile = prevTile;
      _attacker = attacker;
      _targets = bicycle(targets);
      _attackTerrain = _map.tileAt(attacker.row, attacker.col);
      setTarget(targets[0]);
    }

    override void update(float time) {
      _view.update(time);
      if (_input.confirm) {
        if (_targets.front.type == typeid(Battler)) {
          auto series = constructAttackSeries(_attack, _counter);
          setState(new ExecuteCombat(series, _attacker, series.playerXp));
        }
        else {
          popState();
          pushState(_attacker.team == BattleTeam.ally ? new PlayerTurn : new EnemyTurn);
          pushState(new AttackWall(_attacker, cast(Wall) _targets.front.get!TileObject));
        }
      }
      else if (_input.selectLeft) {
        setTarget(_targets.advance);
      }
      else if (_input.selectRight) {
        setTarget(_targets.reverse);
      }
      else if (_input.next) {
        _attacker.equippedWeapon = _itemChoices.advance;
        setTarget(_targets.front);
      }
      else if (_input.previous) {
        _attacker.equippedWeapon = _itemChoices.reverse;
        setTarget(_targets.front);
      }
      else if (_input.cancel) {
        setState(new ChooseBattlerAction(_attacker, _attackTerrain, _prevTile));
      }
    }

    override void draw() {
      Vector2i pos;
      if (_targets.front.type == typeid(Battler)) {
        pos = _targets.front.get!Battler.pos;
      }
      else {
        auto obj = _targets.front.get!TileObject;
        pos = _map.tileCoordToPos(obj.row, obj.col);
      }
      _targetSprite.draw(pos - _camera.topLeft);
      _view.draw(_input.gamepadConnected);
    }

    private:
    Bicycle!(Variant[]) _targets;
    Bicycle!(Item[]) _itemChoices;
    Battler _attacker;
    Attackable _defender;
    Tile _attackTerrain, _defendTerrain, _prevTile;
    CombatPrediction _attack, _counter;
    CombatView _view;

    void setTarget(Variant target) {
      if (target.type == typeid(Battler)) {
        Battler battler = target.get!Battler;
        setBattlerTarget(battler);
      }
      else {
        setWallTarget(cast(Wall) target.get!TileObject);
      }
    }

    void setWallTarget(Wall target) {
      _defender = target;
      _tileCursor.place(_map.tileAt(target.row, target.col));
      auto pos = _map.tileCoordToPos(target.row, target.col);
      _view = new WallCombatView(pos - _camera.topLeft, _attacker, target);
      _itemChoices = bicycle(_attacker.weaponOptions(target));
    }

    void setBattlerTarget(Battler target) {
      _defender = target;
      auto defender = cast(Battler) _defender;
      _defendTerrain = _map.tileAt(target.row, target.col);
      _attack = new CombatPrediction(_attacker, defender, _defendTerrain, false);
      _counter = new CombatPrediction(defender, _attacker, _attackTerrain, true);
      _view = new BattlerCombatView(defender.pos - _camera.topLeft, _attack, _counter);
      _tileCursor.place(_defendTerrain);
      _itemChoices = bicycle(_attacker.weaponOptions(defender));
    }
  }

  class ConsiderSteal : State {
    this(Battler battler, Battler[] targets) {
      _battler = battler;
      _targets = bicycle(targets);
      setTarget(_targets.front);
    }

    override void update(float time) {
      if (_selectedItem) {
        setState(new ExecuteSteal(_battler, _targets.front, _selectedItem));
        return;
      }
      _menu.handleInput(_input);
      if (_input.selectLeft) {
        setTarget(_targets.reverse);
      }
      else if (_input.selectRight) {
        setTarget(_targets.advance);
      }
    }

    override void draw() {
      _menu.draw();
      _targetSprite.draw(_targets.front.pos);
    }

    private:
    Battler _battler;
    Bicycle!(Battler[]) _targets;
    InventoryMenu _menu;
    Item _selectedItem;

    void setTarget(Battler target) {
      _tileCursor.place(_map.tileAtPos(target.pos));
      auto items = array(_targets.front.items[].filter!(x => x !is null).drop(1));
      _menu = new InventoryMenu(screenCenter, items, &onChoose, null, &iconString,
          InventoryMenu.ShowPrice.no, true, true);
    }

    void onChoose(Item item) {
      _selectedItem = item;
    }

    string iconString(Item item) {
      return "steal";
    }
  }

  class ConsiderMagic : State {
    this(Battler battler, Battler[] adjacentAllies, Tile prevTile) {
      _battler = battler;
      _targets = bicycle(adjacentAllies);
      _prevTile = prevTile;
    }

    override void onStart() {
      setTarget(_targets.front);
    }

    override void update(float time) {
      if (_input.selectLeft) {
        _targets.front.hideInfoBox;
        auto newTarget = _targets.reverse;
        setTarget(newTarget);
      }
      else if (_input.selectRight) {
        _targets.front.hideInfoBox;
        auto newTarget = _targets.advance;
        setTarget(newTarget);
      }
      else if (_input.cancel) {
        auto currentTile = _map.tileAt(_battler.row, _battler.col);
        setState(new ChooseBattlerAction(_battler, currentTile, _prevTile));
      }
      else {
        _magicMenu.handleInput(_input);
      }
    }

    override void draw() {
      _magicMenu.draw();
      _targetSprite.draw(_targets.front.pos - _camera.topLeft);
    }

    private:
    Battler _battler;
    Bicycle!(Battler[]) _targets;
    Tile _prevTile;
    InventoryMenu _magicMenu;

    void setTarget(Battler b) {
      showBattlerInfoBoxes(_battler, b);
      _magicMenu = new InventoryMenu(screenCenter, _battler.magicOptions(b), &onChoose, null,
          x => "cast", InventoryMenu.ShowPrice.no, true, true);
    }

    void onChoose(Item magic) {
      popState();
      pushState(new ExecuteMagic(_battler, _targets.front, magic));
      pushState(new Wait(pauseTime));
    }

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

  class ExecuteMagic : State {
    this(Battler caster, Battler target, Item magic) {
      _caster = caster;
      _target = target;
      _magic = magic;
    }

    override void onStart() {
      _target.heal(_magic.heal);
      _target.applyStatEffects(_magic.statEffects);
      _caster.useItem(_magic);
      _castAnim = new AnimatedSprite("castMagic");
    }

    override void update(float time) {
      _castAnim.update(time);
      if (_castAnim.isStopped) {
        bool wasPlayerTurn = _caster.team == BattleTeam.ally;
        _caster.moved = true;
        popState();
        pushState(new AwardXp(_caster, computeCastXp(_caster, _target), wasPlayerTurn));
        pushState(new Wait(pauseTime));
        pushState(new RestoreHealth(_target, _magic.heal, _magic.statEffects));
      }
    }

    override void draw() {
      _castAnim.draw(_caster.pos - _camera.topLeft);
    }

    private:
    Battler _caster, _target;
    Item _magic;
    AnimatedSprite _castAnim;
  }

  class ExecuteSteal : State {
    this(Battler stealer, Battler target, Item item) {
      _stealer = stealer;
      _target = target;
      _item = item;
      _item.drop = false;
    }

    override void update(float time) {
      if (!_started) {
        auto attackDirection = (_target.pos - _stealer.pos).normalized;
        _stealer.sprite.shift(attackDirection * attackShiftDist, attackSpeed);
        _started = true;
      }

      if (_stealer.sprite.isJiggling) {
        return;
      }

      if (_notification) {
        if (_input.confirm) {
          if (_stealer.team == BattleTeam.ally) {
            setState(new AwardXp(_stealer, computeStealXp(_stealer, _target), true));
            return;
          }
          else {
            setState(new EnemyTurn);
            return;
          }
        }
        else {
          return;
        }
      }

      _target.removeItem(_item);
      _stealer.addItem(_item);
      _notification = new ItemNotification(screenCenter, _item, " acquired");
    }

    override void draw() {
      if (_notification) {
        _notification.draw;
      }
    }

    private:
    Battler _stealer, _target;
    Item _item;
    ItemNotification _notification;
    bool _started;
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
      _anim = _result.critted ? new AnimatedSprite("critAttack") :
        new AnimatedSprite(format("%sAttack", _attacker.equippedWeapon.type));
    }

    override void update(float time) {
      _anim.update(time);
      if (!_started) {
        auto attackDirection = (_defender.pos - _attacker.pos).normalized;
        _attacker.sprite.shift(attackDirection * attackShiftDist, attackSpeed);
        if (_result.hit) {
          playSound(_result.critted ? "crit" : "hit");
          _defender.dealDamage(_result.damageDealt);
          if (_attacker.equippedWeapon.effect == ItemEffect.drain) {
            playSound("heal");
            _attacker.heal(_result.damageDealt / 2);
          }
          bool itemDestroyed = _attacker.useItem(_attacker.equippedWeapon);
          if (itemDestroyed) { // remove all further attacks from this character
            _attacks = _attacks.remove!(x => x.attacker == _attacker);
          }
        }
        else {
          playSound("miss");
        }
        _started = true;
      }

      if (_attacker.sprite.isJiggling || _defender.sprite.isFlashing || _attacker.isHpTransitioning ||
          _defender.isHpTransitioning)
      {
        return;
      }

      _attacks.popFront;
      if (_attacks.empty || !_attacker.alive || !_defender.alive) { // no attacks left to show
        Battler enemy = _attacker.team == BattleTeam.ally ? _defender : _attacker;
        _initialAttacker.moved = true; // end attacker's turn
        Battler friendly = _attacker.team == BattleTeam.ally ? _attacker : _defender;
        bool wasPlayerTurn = _initialAttacker.team == BattleTeam.ally;
        if (friendly.alive) {
          auto item = enemy.alive ? null : enemy.itemToDrop;
          setState(new Wait(pauseTime, new AwardXp(friendly, _playerXp, wasPlayerTurn, item)));
        }
        else {
          setState(new Wait(pauseTime, wasPlayerTurn ? new PlayerTurn : new EnemyTurn));
        }
      }
      else {
        setState(new Wait(pauseTime, new ExecuteCombat(_attacks, _initialAttacker, _playerXp)));
      }
    }

    override void draw() {
      _anim.draw(_defender.pos - _camera.topLeft);
    }

    private:
    CombatResult[] _attacks;
    CombatResult _result;
    Battler _attacker, _defender;
    Battler _initialAttacker;
    bool _started;
    int _playerXp;
    AnimatedSprite _anim;

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
      if (area.left < 0) { area.x -= shift.x; }
      if (area.bottom > _camera.height) { area.y -= shift.y; }

      b.showInfoBox(area.topLeft);
    }
  }

  class AttackWall : State {
    this(Battler attacker, Wall wall) {
      _attacker = attacker;
      _wall = wall;
      showInfoBox(_attacker, _wall);
    }

    override void onStart() {
      auto wallPos = _map.tileCoordToPos(_wall.row, _wall.col);
      auto attackDirection = (wallPos - _attacker.pos).normalized;
      _attacker.sprite.shift(attackDirection * attackShiftDist, attackSpeed);
      bool itemDestroyed = _attacker.useItem(_attacker.equippedWeapon);
      _info.healthBar.transition(max(0, _wall.hp - _attacker.attackDamage), hpTransitionRate);
      _wall.dealDamage(_attacker.attackDamage);
      _started = true;
    }

    override void update(float time) {
      _wall.sprite.update(time);
      _info.healthBar.update(time);
      if (_attacker.sprite.isJiggling || _wall.sprite.isFlashing || _info.healthBar.isTransitioning)
      {
        return;
      }

      _attacker.moved = true; // end attacker's turn
      if (!_wall.alive) {
        auto tile = _map.tileAt(_wall.row, _wall.col);
        tile.object = null;
      }
      popState();
      pushState(new Wait(pauseTime));
    }

    override void draw() {
      _info.draw;
    }

    private:
    Battler _attacker;
    Wall _wall;
    BattlerInfoBox _info;
    bool _started;

    void showInfoBox(Battler attacker, Wall wall) {
      // check if b1 is topRight
      if (wall.row < attacker.row || wall.col > attacker.col) {
        showTopRightInfo(wall);
      }
      else {
        showBottomLeftInfo(wall);
      }
    }

    void showTopRightInfo(Wall wall) {
      auto size = Vector2i(BattlerInfoBox.width, BattlerInfoBox.height);
      auto shift = Vector2i(size.x, -size.y) / 2 + Vector2i(battleInfoOffset.x, -battleInfoOffset.y);
      auto pos = _map.tileCoordToPos(wall.row, wall.col);
      auto area = Rect2i.CenteredAt(pos + shift - _camera.topLeft, size.x, size.y);
      if (area.top < 0) { area.y += shift.y; }
      if (area.right > _camera.width) { area.x -= shift.x; }

      _info = new BattlerInfoBox(area.topLeft, wall);
    }

    void showBottomLeftInfo(Wall wall) {
      auto size = Vector2i(BattlerInfoBox.width, BattlerInfoBox.height);
      auto shift = Vector2i(-size.x, size.y) / 2 + Vector2i(-battleInfoOffset.x, battleInfoOffset.y);
      auto pos = _map.tileCoordToPos(wall.row, wall.col);
      auto area = Rect2i.CenteredAt(pos + shift - _camera.topLeft, size.x, size.y);
      if (area.left < 0) { area.x += shift.x; }
      if (area.bottom > _camera.height) { area.y -= shift.y; }

      _info = new BattlerInfoBox(area.topLeft, wall);
    }
  }

  class AwardXp : State {
    this(Battler battler, int xp, bool wasPlayerTurn, Item itemToAward = null) {
      _battler = battler;
      _xp = xp;
      _wasPlayerTurn = wasPlayerTurn;
      if (itemToAward && battler.addItem(itemToAward)) {
        itemToAward.drop = false; // unmark the item as droppable
        auto pos = Vector2i(Settings.screenW, Settings.screenH) / 2;
        _itemNotification = new ItemNotification(pos, itemToAward, " acquired");
      }
      _battler.showInfoBox(screenCenter);
    }

    void begin() {
      _leveled = _battler.awardXp(_xp, _awards, _leftoverXp);
      _started = true;
      _xpSound.play();
    }

    void end() {
      _battler.hideInfoBox;
      _xpSound.stop();
    }

    override void update(float time) {
      if (_itemNotification) {
        if (_input.confirm) {
          _itemNotification = null;
        }
        return;
      }
      if (!_started) { begin; }
      if (_battler.isXpTransitioning) {
      }
      else if (_leveled) {
        setState(new Wait(pauseTime, new LevelUp(_battler, _awards, _wasPlayerTurn, _leftoverXp)));
      }
      else {
        setState(new Wait(pauseTime, _wasPlayerTurn ? new PlayerTurn : new EnemyTurn, &end));
      }
    }

    override void draw() {
      if (_itemNotification) { _itemNotification.draw; }
    }

    private:
    Battler _battler;
    bool _started;
    bool _wasPlayerTurn;
    bool _leveled;
    AttributeSet _awards;
    int _xp, _leftoverXp;
    ItemNotification _itemNotification;
  }

  class LevelUp : State {
    this(Battler battler, AttributeSet awards, bool wasPlayerTurn, int leftoverXp) {
      _view = new LevelUpView(Vector2i.Zero, battler, awards);
      _wasPlayerTurn = wasPlayerTurn;
      _battler = battler;
      _awards = awards;
      _leftoverXp = leftoverXp;
    }

    override void onStart() {
      playSound("levelup");
    }

    override void update(float time) {
      _view.update(time);
      if (_view.doneAnimating && (_input.confirm || _input.cancel || _input.inspect)) {
        _battler.applyLevelUp(_awards);
        if (_battler.canGetNewTalent) {
          setState(new AwardTalent(_battler, _view, _leftoverXp, _wasPlayerTurn));
        }
        else if (_leftoverXp > 0) {
          _battler.infoBox.xpBar.val = 0;
          setState(new AwardXp(_battler, _leftoverXp, _wasPlayerTurn));
        }
        else {
          _battler.hideInfoBox;
          setState(_wasPlayerTurn ? new PlayerTurn : new EnemyTurn);
        }
      }
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

  class AwardTalent : State {
    this(Battler battler, LevelUpView currentView, int leftoverXp, bool wasPlayerTurn) {
      _battler = battler;
      _view = currentView;
      _leftoverXp = leftoverXp;
      _talentChooser = new TalentMenu(talentMenuPos, battler.availableNewTalents, &chooseTalent, true);
      _wasPlayerTurn = wasPlayerTurn;
    }

    override void update(float time) {
      _view.update(time);
      if (_talentChooser) { // waiting to choose talent
        _talentChooser.handleInput(_input);
      }
      else if (_view.doneAnimating && _input.confirm) { // done showing talent increase
        _battler.addTalent(_chosenTalent);
        setState(new AwardXp(_battler, _leftoverXp, _wasPlayerTurn));
      }
    }

    override void draw() {
      _view.draw;
      if (_talentChooser) {
        _talentChooser.draw;
      }
    }

    private:
    LevelUpView _view;
    TalentMenu _talentChooser;
    Talent _chosenTalent;
    bool _wasPlayerTurn;
    int _leftoverXp;
    Battler _battler;

    void chooseTalent(Talent t) {
      _chosenTalent = t;
      _view = new LevelUpView(Vector2i.Zero, _battler, t.bonus, t.potential);
      _talentChooser = null;
    }
  }

  class Trade : State {
    this(Battler trader, Battler[] allies, Tile prevTile) {
      _trader = trader;
      _others = bicycle(allies);
      _prevTile = prevTile;
    }

    override void onStart() {
      _traderMenu = new InventoryMenu(traderPos, _trader.items, &chooseGive, null,
          x => "give", InventoryMenu.ShowPrice.no, false, true);
      _otherMenu = new InventoryMenu(otherPos, _others.front.items, &chooseReceive, null,
          x => "take", InventoryMenu.ShowPrice.no, true, true);
    }

    override void update(float time) {
      if (_input.next) {
        auto other = _others.advance;
        _otherMenu = new InventoryMenu(otherPos, other.items, &chooseReceive, null,
            x => "take", InventoryMenu.ShowPrice.no, true, true);
      }
      else if (_input.previous) {
        auto other = _others.reverse;
        _otherMenu = new InventoryMenu(otherPos, other.items, &chooseReceive, null,
            x => "take", InventoryMenu.ShowPrice.no, true, true);
      }
      else if (_input.selectLeft || _input.selectRight) {
        swapFocus();
      }
      else if (_input.cancel) {
        if (_itemsSwapped) {
          _trader.moved = true;
          setState(new PlayerTurn);
        }
        else {
          auto currentTile = _map.tileAt(_trader.row, _trader.col);
          setState(new ChooseBattlerAction(_trader, currentTile, _prevTile));
        }
      }
      _traderMenu.handleInput(_input);
      _otherMenu.handleInput(_input);
      if (_swapFocus) { swapFocus(); }
    }

    override void draw() {
      _traderMenu.draw();
      _otherMenu.draw();
      _targetSprite.draw(_others.front.pos - _camera.topLeft);
    }

    private:
    Battler _trader;
    Bicycle!(Battler[]) _others;
    Tile _prevTile;
    InventoryMenu _traderMenu, _otherMenu;
    Item _give, _take;
    Vector2i traderPos = screenCenter - Vector2i(100, 0);
    Vector2i otherPos = screenCenter + Vector2i(100, 0);
    bool _itemsSwapped, _chosenGive, _chosenTake, _swapFocus;

    void chooseGive(Item item) {
      _give = item;
      _chosenGive = true;
      if (_chosenTake) {
        swapItems();
      }
      _swapFocus = true;
    }

    void chooseReceive(Item item) {
      _take = item;
      _chosenTake = true;
      if (_chosenGive) {
        swapItems();
      }
      _swapFocus = true;
    }

    void swapItems() {
      _trader.removeItem(_give);
      _trader.addItem(_take);
      _others.front.removeItem(_take);
      _others.front.addItem(_give);
      _itemsSwapped = true;
      _traderMenu = new InventoryMenu(traderPos, _trader.items, &chooseGive);
      _otherMenu = new InventoryMenu(otherPos, _others.front.items, &chooseReceive);
      _traderMenu.hasFocus = false;
      _take = null;
      _give = null;
      _chosenGive = false;
      _chosenTake = false;
    }

    void swapFocus() {
      _traderMenu.hasFocus = !_traderMenu.hasFocus;
      _otherMenu.hasFocus = !_otherMenu.hasFocus;
      _swapFocus = false;
    }
  }

  class Wait : State {
    this(float time, State nextState = null, void delegate() onWaitEnd = null) {
      _timer = time;
      _nextState = nextState;
      _onWaitEnd = onWaitEnd;
    }

    override void update(float time) {
      _timer -= time;
      if (_timer < 0) {
        if (_onWaitEnd) { _onWaitEnd(); }
        if (_nextState) {
          setState(_nextState);
        }
        else {
          popState();
        }
      }
    }

    private:
    float _timer;
    State _nextState;
    void delegate() _onWaitEnd;
  }

  class EnemyTurn : State {
    this() {
      auto findReady = _enemies.find!"!a.moved";
      if (findReady.empty) { // no unmoved enemies -- player turn
        _battler = null;
      }
      else {
        _battler = findReady.front;
        _behavior = getAI(_battler, _map, _allies, _enemies);
      }
    }

    override void onStart() {
      foreach(battler ; _battlers) {
        battler.hideInfoBox;
      }
    }

    override void update(float time) {
      if (_battler is null) {
        foreach(enemy ; _enemies) {
          enemy.passTurn();
        }
        setState(new PlayerTurn);
      }

      else {
        auto path = _behavior.moveRequest;
        if (path !is null) {
          auto selfTerrain = _map.tileAt(_battler.row, _battler.col);
          setState(new Wait(walkPauseTime, new MoveBattler(_battler, selfTerrain, path)));
        }
        else {
          setState(new EnemyChooseAction(_battler, _behavior));
        }
      }
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

    override void update(float time) {
      auto selfTerrain = _map.tileAt(_battler.row, _battler.col);
      auto target = _behavior.attackRequest;
      if (target) {
        auto targetTerrain = _map.tileAt(target.row, target.col);
        auto attack  = new CombatPrediction(_battler, target, targetTerrain, false);
        auto counter = new CombatPrediction(target, _battler, selfTerrain, true);
        auto series = constructAttackSeries(attack, counter);
        setState(new ExecuteCombat(series, _battler, series.playerXp));
      }
      else {
        _battler.moved = true; // skip turn
        setState(new Wait(pauseTime, new EnemyTurn));
      }
    }

    private:
    Battler _battler;
    AI _behavior;
  }

  class BattleOver : State {
    this(bool victory) {
      _victory = victory;
      _splash = getTexture(victory ? "victorySplash" : "defeatSplash");
    }

    override void update(float time) {
      if (_input.confirm) {
        endBattle(_victory);
      }
    }

    override void draw() {
      _splash.draw(Vector2i.Zero);
    }

    private:
    Texture _splash;
    bool _victory;
  }

  class ConsiderSkip : State {
    private enum {
      confirmOffset = Vector2i(-24, 20),
      cancelOffset = Vector2i(-24, 40),
    }

    this() {
      _notification = new Notification(screenCenter, "Skip Turn?");
    }

    override void update(float time) {
      if (_input.confirm) {
        foreach(battler ; _allies) {
          battler.passTurn();
        }
        setState(new EnemyTurn);
      }
      else if (_input.cancel) {
        setState(new PlayerTurn);
      }
    }

    override void draw() {
      _notification.draw();
      drawInputIcon("confirm", screenCenter + confirmOffset, _input.gamepadConnected, "confirm");
      drawInputIcon("cancel", screenCenter + cancelOffset, _input.gamepadConnected, "cancel");
    }

    private:
    Notification _notification;
  }

  private class TileCursor {
    bool active = true;

    this() {
      _sprite = new AnimatedSprite("target", shade);
    }

    /// tile under cursor
    @property {
      Tile tile() { return active ? _map.tileAt(_row, _col) : null; }
      auto battler() { return active ? tile.battler : null; }
      auto pos() { return _pos; }

      int left()   { return cast(int) (_pos.x - _map.tileWidth / 2); }
      int right()  { return cast(int) (_pos.x + _map.tileWidth / 2); }
      int top()    { return cast(int) (_pos.y - _map.tileHeight / 2); }
      int bottom() { return cast(int) (_pos.y + _map.tileHeight / 2); }
    }

    void update(float time, InputManager input) {
      if (!active) { return; }
      _sprite.update(time);

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

      _pos = (_pos + direction * scrollSpeed * time)
        .clamp(_map.bounds.topLeft, _map.bounds.bottomRight - _map.tileSize / 2);

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
