module gui.roster_slot;

import gui.element;
import geometry.all;
import graphics.all;
import model.character;

private enum {
  bgColor = Color.gray,
  borderColor = Color.black,
  levelColor = Color.green,
  slotSize = 40,
  borderThickness = 2,
  levelOffset = Vector2i(8, 8),
  activeShade = Color.white,
  inactiveShade = Color.gray,
}

class RosterSlot : GUIElement {
  alias Action = void delegate(Character);

  this(Vector2i pos, Character character, Action action, Action hoverAction,
      bool active = true)
  {
    this.character = character;
    _action = action;
    _hoverAction = hoverAction;
    super(pos, Anchor.center);
    this.active = active;
  }

  @property {
    auto character() { return _character; }
    void character(Character newChar) {
      _character = newChar;
      _sprite = newChar ? new CharacterSprite(newChar.model) : null;
    }
    bool active() { return _active; }
    void active(bool val) {
      _active = val;
      _sprite.tint = val ? activeShade : inactiveShade;
    }
  }

  override {
    @property {
      int width() {
        return slotSize;
      }
      int height() {
        return slotSize;
      }
    }

    void handleSelect() {
      _action(character);
    }

    void handleHover() {
      if (_hoverAction) {
        _hoverAction(character);
      }
    }

    void draw() {
      bounds.drawFilled(bgColor);
      bounds.draw(borderThickness, borderColor);
      if (character) {
        _sprite.draw(bounds.center);
        _font.draw(character.level, bounds.center + levelOffset, levelColor);
      }
    }
  }

  private:
  CharacterSprite _sprite;
  Character _character;
  Action _action, _hoverAction;
  bool _active;
}

private Font _font;

static this() {
  _font = getFont("rosterSlot");
}
