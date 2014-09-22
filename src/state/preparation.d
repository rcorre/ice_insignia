module state.preparation;

import std.range;
import allegro;
import state.gamestate;
import gui.all;
import geometry.all;
import util.input;
import model.character;
import model.item;
import util.savegame;
import util.bicycle;
import state.battle;
import tilemap.loader;

private enum {
  // button sprites
  lbButtonPos = Vector2i(36, 70),
  rbButtonPos = Vector2i(36, 560),
}

class Preparation : GameState {
  this(SaveData data, bool newMission) {
    _data = data;
    if (newMission) {
      data.advanceMission;
    }
    _data.saveGame;
    auto forSale = [
      new Item("dirk"),
      new Item("broadsword"),
      new Item("falchion"),
      new Item("sabre"),
      new Item("claymore"),
      new Item("katana"),
      new Item("quarterstaff"),
      new Item("spear"),
      new Item("pike"),
      new Item("javelin"),
      new Item("glaive"),
      new Item("halberd"),
      new Item("mace"),
      new Item("battleaxe"),
      new Item("crescentaxe"),
      new Item("tomahawk"),
      new Item("greataxe"),
      new Item("warhammer"),
      new Item("shortbow"),
      new Item("crossbow"),
      new Item("longbow"),
      new Item("barbedbow"),
      new Item("greatbow"),
      new Item("arbalest"),
      new Item("poultice"),
      new Item("doorkey"),
      new Item("chestkey"),
      new Item("lockpick"),
      new Item("heal"),
    ];
    _levelData = loadLevel(data.mission);
    auto rosterView = new RosterView(Vector2i.Zero, data, data.forHire);
    auto storeView = new StoreView(Vector2i.Zero, data, forSale);
    _missionView = new MissionView(Vector2i.Zero, data, _levelData, &startMission);
    GUIContainer[] views = [rosterView, storeView, _missionView];
    _views = bicycle(views);
    _input = new InputManager;
  }

  /// returns a GameState to request a state transition, null otherwise
  override GameState update(float time) {
    _views.front.update(time);
    _input.update(time);
    if (_views.front.handleInput(_input)) {
      return _startBattle;
    }
    if (_input.next) {
      _views.advance;
      _missionView.regenerateRoster;
    }
    else if (_input.previous) {
      _views.reverse;
      _missionView.regenerateRoster;
    }
    return _startBattle;
  }

  /// render game state to screen
  override void draw() {
    _views.front.draw();
    drawInputIcon("previous", lbButtonPos, _input.gamepadConnected);
    drawInputIcon("next", rbButtonPos, _input.gamepadConnected);
  }

  override void handleEvent(ALLEGRO_EVENT ev) {
    if (ev.type == ALLEGRO_EVENT_JOYSTICK_CONFIGURATION) {
      _input.reconfigureGamepad();
    }
  }

  override void onExit() {
  }

  void startMission(Character[] party) {
    _startBattle = new Battle(_levelData, party, _data);
  }

  private:
  Bicycle!(GUIContainer[]) _views;
  InputManager _input;
  SaveData _data;
  Battle _startBattle;
  LevelData _levelData;
  MissionView _missionView;
}
