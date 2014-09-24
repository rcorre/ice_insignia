module gui.mission_view;

import std.range;
import std.array;
import std.algorithm;
import std.string : format;
import gui.element;
import gui.container;
import gui.roster_slot;
import gui.input_icon;
import geometry.all;
import graphics.all;
import model.character;
import util.input;
import util.savegame;
import tilemap.loader;

private enum {
  goldOffset       = Vector2i(120, 25),
  rosterStartPos   = Vector2i(113, 105),
  countOffset      = Vector2i(419, 449),
  startOffset      = Vector2i(311, 457),
  overviewTitlePos = Vector2i(447, 102),
  overviewStatsPos = Vector2i(447, 183),
  cursorShade      = Color(0, 0, 0.5, 0.8),
  numRecruitCols   = 3,
  rosterSpacingX   = 64,
  rosterSpacingY   = 64,
}

class MissionView : GUIContainer {
  alias StartCommand = void delegate(Character[]);
  this(Vector2i pos, SaveData data, LevelData mapData, StartCommand startCmd) {
    _data = data;
    auto cursor = new AnimatedSprite("target", cursorShade);
    super(pos, Anchor.topLeft, "mission_view", cursor);
    auto slotPos = rosterStartPos;
    foreach(idx ; iota(0, rosterSize - 1)) {
      if (idx != 0 && idx % numRecruitCols == 0) {
        slotPos.x = rosterStartPos.x;
        slotPos.y += rosterSpacingY;
      }
      auto character = (idx >= _data.roster.length) ? null : _data.roster[idx];
      auto slot = new RosterSlot(slotPos, character, &selectRoster, null, false);
      _slots ~= slot;
      addElement(slot);
      slotPos.x += rosterSpacingX;
    }
    _unitsAllowedOnMission = cast(int) mapData.spawnPoints.length;
    _startCmd = startCmd;
    _mapData = mapData;

    _overviewStats ~= mapData.description;
    _overviewStats ~= format("Number of Enemies: %d", mapData.enemies.length);
    _overviewStats ~= format("Average Enemy Level: %d", mapData.avgLevel);
    _overviewStats ~= format("Reward: %d", mapData.goldReward);
  }

  override {
    void draw() {
      super.draw;
      _goldFont.draw(format("%dG", _data.gold), bounds.topLeft + goldOffset);
      _countFont.draw(format("%d / %d Units", _numActiveUnits, _unitsAllowedOnMission),
          bounds.topLeft + countOffset);
      drawInputIcon("start", bounds.topLeft + startOffset, _gamepadConnected);
      _titleFont.draw(format("Mission %d", _data.mission), overviewTitlePos);
      _statsFont.draw(_overviewStats, overviewStatsPos);
    }

    bool handleInput(InputManager input) {
      _gamepadConnected = input.gamepadConnected;
      if (input.start) {
        auto units = _slots.filter!"a.active".find!"a.character !is null".map!"a.character";
        if (!units.empty) {
          _startCmd(array(units));
        }
        return true;
      }
      return super.handleInput(input);
    }
  }

  void regenerateRoster() {
    foreach(slot, character; zip(_slots, _data.roster)) {
      slot.character = character;
    }
  }

  void selectRoster(Character character) {
    auto r = _slots.find!(a => a.character == character);
    if (!r.empty) {
      auto slot = r.front;
      auto active = slot.active;
      if (active) {
        --_numActiveUnits;
        slot.active = !slot.active;
      }
      else if (_numActiveUnits < _unitsAllowedOnMission) {
        ++_numActiveUnits;
        slot.active = !slot.active;
      }
    }
  }

  private:
  SaveData _data;
  RosterSlot[] _slots;
  int _numActiveUnits;
  int _unitsAllowedOnMission;
  StartCommand _startCmd;
  LevelData _mapData;
  bool _gamepadConnected;
  string[] _overviewStats;
}

private static Font _goldFont, _countFont, _titleFont, _statsFont;

static this() {
  _goldFont = getFont("rosterGold");
  _countFont = getFont("activeUnitCount");
  _titleFont = getFont("missionTitle");
  _statsFont = getFont("missionStats");
}
