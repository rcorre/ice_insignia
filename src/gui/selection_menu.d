module gui.selection_menu;

import std.conv;
import std.array : empty;
import std.algorithm : map, reduce, max;
import graphics.all;
import geometry.all;
import util.all;
import gui.input_icon;

private enum {
  fontName = "selection_font",
  spacingY = 5,
  buffer = Vector2i(10, 4)
}

abstract class SelectionMenu(T) {
  alias Action = void delegate(T);
  alias HoverAction = void delegate(T, Rect2i);
  alias InputString = string delegate(T);

  this(Vector2i pos, T[] selections, Action onChoose, HoverAction onHover = null,
      InputString inputString = null, bool hasFocus = true, bool drawBackButton = false)
  {
    // the width/height of each entry is normalized to the largest entry
    if (selections is null || selections.empty) {
      _entryWidth = 0; // TODO: use texture
      _entryHeight = 0;
    }
    else {
      _entryWidth = selections.map!(a  => entryWidth(a)).reduce!max;
      _entryHeight = selections.map!(a => entryHeight(a)).reduce!max;
    }
    int n = cast(int) selections.length + 1;
    _totalArea = Rect2i(pos, _entryWidth, _entryHeight * n);

    _selections = selections;
    _onChoose = onChoose;
    _onHover = onHover;
    _inputString = inputString;
    _drawBackButton = drawBackButton;
    this.hasFocus = hasFocus;
    _texture = new Sprite("selectionBox");
    _textureSelected = new Sprite("selectionBoxSelected");
    auto scale = Vector2f(cast(float) (_entryWidth + buffer.x) / _texture.width, cast(float)
        (_entryHeight + buffer.y) / _texture.height);
    _texture.scale = scale;
    _textureSelected.scale = scale;
  }

  @property bool hasFocus() { return _hasFocus; }
  @property void hasFocus(bool val) {
    if (val && !_hasFocus) {
      callHoverAction;
    }
    _hasFocus = val;
  }

  @property T selection() {
    return _selections[_cursorIdx];
  }

  final void keepInside(Rect2i camera, int buffer = 0) {
    _totalArea.keepInside(camera, buffer);
  }

  final void handleInput(InputManager input) {
    if (!_hasFocus) { return; }
    bool movedSelection;
    if (input.selectUp) {
      --_cursorIdx;
      movedSelection = true;
    }
    else if (input.selectDown) {
      ++_cursorIdx;
      movedSelection = true;
    }
    else if (input.selectRight) {
      handleSideMovement(selection, 1);
    }
    else if (input.selectLeft) {
      handleSideMovement(selection, -1);
    }
    if (movedSelection) {
      playSound("cursor");
      // add length so negative values wrap
      _cursorIdx = cast(int) ((_cursorIdx + _selections.length) % _selections.length);
      callHoverAction;
    }

    if (input.confirm && _onChoose !is null) {
      playSound("select");
      _onChoose(_selections[_cursorIdx]);
    }

    _gamepadConnected = input.gamepadConnected;
  }

  final void callHoverAction() {
    if (_onHover && _selections) {
      auto area = Rect2i(_totalArea.topLeft + Vector2i(0, _entryHeight * _cursorIdx), _entryWidth, _entryHeight);
      _onHover(_selections[_cursorIdx], area);
    }
  }

  void draw() {
    auto rect = Rect2i(_totalArea.topLeft, _entryWidth, _entryHeight);
    foreach(idx, entry ; _selections) {
      bool isSelected = _hasFocus && idx == _cursorIdx;
      (isSelected ? _textureSelected : _texture).draw(rect.center);
      if (isSelected && hasFocus && entry !is null) {
        _textureSelected.draw(rect.center);
        Vector2i iconPos = rect.topRight + inputIconSize / 2;
        if (_inputString) {
          auto str =  _inputString(entry);
          if (str !is null) {
            drawInputIcon("confirm", iconPos, _gamepadConnected, str);
          }
        }
      }
      drawEntry(entry, rect, isSelected);
      rect.y += _entryHeight + spacingY;
    }
    if (_drawBackButton) {
      drawInputIcon("cancel", rect.center, _gamepadConnected, "back");
    }
  }

  void handleSideMovement(T entry, int direction) { }

  protected:
  void drawEntry(T entry, Rect2i rect, bool isSelected);
  int entryWidth(T entry);
  int entryHeight(T entry);
  bool _gamepadConnected;

  static Font _font;

  private:
  Rect2i _totalArea;
  int _entryWidth, _entryHeight;
  T[] _selections;
  int _cursorIdx;
  HoverAction _onHover;
  InputString _inputString;
  Action _onChoose;
  bool _hasFocus, _drawBackButton;
  Sprite _texture, _textureSelected;

  static this() {
    _font = getFont(fontName);
  }
}
