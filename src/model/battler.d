module model.battler;

import std.range;
import std.algorithm;
import std.math : abs;
import allegro;
import geometry.all;
import graphics.all;
import util.math;
import util.sound;
import gui.all;
import model.character;
import model.item;
import model.attackable;
import model.talent;
import tilemap.object;

private enum {
  movedTint        = Color(0.6,0.6,0.6,0.9),
  damageFlashTime  = 0.22, /// duration of flash used to indicate damage
  fadeTime         = 0.5,  /// duration of flash used to indicate damage
  damageFlashColor = Color(0.5, 0, 0),
  fadeSpectrum     = [Color.red, Color.clear],
  healFlashColor   = Color(0.0, 1.0, 0),
  healFlashTime    = 0.42,
  hpTransitionRate = 20,
  xpTransitionRate = 80,
  fortitudeRegen   = 2 /// health restored per turn by fortitude
}

enum BattleTeam {
  ally,
  enemy,
  neutral
}

class Battler : Attackable {
  alias character this;

  this(Character c, int row, int col, Vector2i pos, BattleTeam team, 
      string aiType = "agressive", bool isBoss = false) 
  {
    character = c;
    _row = row;
    _col = col;
    _pos = pos;
    _sprite = new CharacterSprite(c, team);
    this.team = team;
    _hp = c.maxHp;
    _aiType = aiType;
    this.isBoss = isBoss;
    if (isBoss) {
      _bossIcon = new AnimatedSprite("bossIcon");
    }
  }

  @property {
    Sprite sprite() { return _sprite; }
    int row() { return _row; }
    int col() { return _col; }
    int row(int val) { return _row = val; }
    int col(int val) { return _col = val; }
    ref Vector2i pos() { return _pos; }
    int hp() { return _hp; }

    bool alive() { return _hp > 0; }

    bool moved() { return _moved || !alive; }
    void moved(bool val) {
      if (alive) {
        _moved = val;
        // shade sprite if moved
        _sprite.tint = val ? movedTint : Color.white;
      }
    }

    Item equippedWeapon() {
      return character.equippedWeapon;
    }
    void equippedWeapon(Item item) {
      character.equippedWeapon = item;
      _sprite = new CharacterSprite(character, team);
    }

    BattlerInfoBox infoBox() { return _infoBox; }
    bool isHpTransitioning() { return _infoBox.healthBar.isTransitioning; }
    bool isXpTransitioning() { return _infoBox.xpBar.isTransitioning; }

    /// get an item this battler could open a door with
    Item getDoorOpener(TileObject door) {
      if (cast(Door) door is null) { return null; } // not a door
      int dist = abs(door.row - row) + abs(door.col - col);
      auto knock = findItem("Knock");
      if (dist == 2) {
        if (knock !is null && canWieldMagic(knock)) {
          return knock;
        }
      }
      else if (dist == 1) {
        if (knock !is null && canWieldMagic(knock)) {
          return knock;
        }
        auto lockpick = findItem("Lockpick");
        if (lockpick !is null && hasTalent("theft")) {
          return lockpick;
        }
        auto doorKey = findItem("Door Key");
        return doorKey;
      }
      return null;
    }

    /// get an item this battler could open a chest with
    Item getChestOpener(TileObject chest) {
      if (chest.row != row || chest.col != col) { // must be on same tile
        return null;
      }
      auto lockpick = findItem("Lockpick");
      if (lockpick !is null && hasTalent("theft")) {
        return lockpick;
      }
      auto chestKey = findItem("Chest Key");
      return chestKey;
    }

    /// return true if item totally consumed
    bool useItem(Item item) {
      auto idx = items[].countUntil(item);
      assert(idx >= 0, "trying to use item " ~ item.name ~ " but it is not in inventory");
      if (--items[idx].uses <= 0) {
        removeItem(item);
        if (idx == 0) { // was equipped weapon
          equipNextWeapon();
        }
        return true;
      }
      return false;
    }

    string aiType() {return _aiType; }
    Item itemToDrop() {
      auto r = items[].find!"a !is null && a.drop";
      return r.empty ? null : r.front;
    }
  }

  void update(float time) {
    _sprite.update(time);
    if (_infoBox) {
      _infoBox.update(time);
    }
    if (isBoss) {
      _bossIcon.update(time);
    }
  }

  void draw(Vector2i offset) {
    _sprite.draw(pos - offset);
    if (isBoss) {
      _bossIcon.draw(pos - offset);
    }
  }

  void drawInfoBox() {
    if (_infoBox) {
      _infoBox.draw();
    }
  }

  void showInfoBox(Vector2i pos) {
    if (_infoBox is null) {
      _infoBox = new BattlerInfoBox(pos, this);
    }
  }

  void hideInfoBox() {
    _infoBox = null;
  }

  void passTurn() {
    moved = false;
    if (hasTalent("fortitude")) {
      heal(fortitudeRegen);
    }
    character.passTurn();
  }

  void dealDamage(int amount) {
    amount = amount.clamp(0, _hp);
    if (amount > 0) {
      _sprite.flash(damageFlashTime, damageFlashColor);
      _infoBox.healthBar.transition(_hp, _hp - amount, hpTransitionRate);
    }
    _hp -= amount;
    if (_hp <= 0) {
      _sprite.fade(fadeTime, fadeSpectrum);
    }
  }

  void heal(int amount) {
    amount = amount.clamp(0, maxHp - _hp);
    if (amount > 0) {
      _sprite.flash(healFlashTime, healFlashColor);
      _infoBox.healthBar.transition(_hp, _hp + amount, hpTransitionRate);
    }
    _hp += amount;
  }

  bool awardXp(int amount, out AttributeSet bonuses, out int leftover) {
    assert(_infoBox, "infobox not shown to award xp");
    _infoBox.xpBar.transition(xp, min(xp + amount, xpLimit), xpTransitionRate);
    return character.awardXp(amount, bonuses, leftover);
  }

  bool canAttack(Battler other) {
    auto dist = abs(row - other.row) + abs(col - other.col);
    return other.alive && dist >= character.equippedWeapon.minRange && dist <= character.equippedWeapon.maxRange;
  }

  bool canAttack(TileObject obj) {
    auto wall = cast(Wall) obj;
    if (wall is null) { return false; }
    auto dist = abs(row - obj.row) + abs(col - obj.col);
    return wall.alive && dist >= character.equippedWeapon.minRange && dist <= character.equippedWeapon.maxRange;
  }

  auto stealableItems() {
    return items[].drop(1).filter!(x => x !is null); // cant steal equipped item
  }

  bool canStealFrom(Battler other) {
    auto dist = abs(row - other.row) + abs(col - other.col);
    auto hasPickpocket = talents.canFind!(x => x.key == "theft");
    bool hasSpace = items[].canFind!(x => x is null);
    return hasPickpocket && dist == 1 && !other.stealableItems.empty;
  }

  Item[] weaponOptions(Attackable other) {
    int dist = abs(row - other.row) + abs(col - other.col);
    return array(items[].filter!(a => character.canWield(a) && a.minRange <= dist && dist <= a.maxRange));
  }

  Item[] magicOptions(Battler target) {
    return array(items[].filter!(a => canMagic(target, a)));
  }

  bool canMagic(Battler other, Item item) {
    if (item is null) { return false; }
    auto dist = abs(row - other.row) + abs(col - other.col);
    bool inRange = dist >= item.minRange && dist <= item.maxRange;
    return inRange && canWieldMagic(item);
  }

  bool canWieldMagic(Item item) {
    return item !is null && item.type == ItemType.magic &&
      talents.canFind!(a => a.weaponSkill == ItemType.magic && a.weaponTier >= item.tier);
  }

  void addTalent(Talent t) {
    character.addTalent(t);
    _sprite = new CharacterSprite(this);
  }

  const BattleTeam team;
  const bool isBoss;
  Character character;

  private:
  CharacterSprite _sprite;
  AnimatedSprite _bossIcon;
  int _row, _col;
  Vector2i _pos;
  int _hp;
  bool _moved;
  BattlerInfoBox _infoBox;
  string _aiType;
}
