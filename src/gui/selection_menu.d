module gui.selection_menu;

import std.conv;
import std.algorithm : map, reduce, max;
import graphics.all;
import geometry.all;
import util.input;

private enum {
  fontName = "selection_font",
  spacingY = 5
}

abstract class SelectionMenu(T) {
  alias Action = void delegate(T);
  this(Vector2i pos, T[] selections, Action onChoose, Action onHover) {
    // the width/height of each entry is normalized to the largest entry
    _entryWidth = selections.map!(a  => entryWidth(a)).reduce!max;
    _entryHeight = selections.map!(a => entryHeight(a)).reduce!max;
    int n = cast(int) selections.length + 1;
    _totalArea = Rect2i(pos, _entryWidth * n, _entryHeight * n);

    _selections = selections;
    _onChoose = onChoose;
    _onHover = onHover;
  }

  final void handleInput(InputManager input) {
    bool movedSelection;
    if (input.selectUp) {
      --_cursorIdx;
      movedSelection = true;
    }
    else if (input.selectDown) {
      ++_cursorIdx;
      movedSelection = true;
    }
    if (movedSelection) {
      // add length so negative values wrap
      _cursorIdx = cast(int) ((_cursorIdx + _selections.length) % _selections.length);
      _onHover(_selections[_cursorIdx]);
    }

    if (input.confirm) {
      _onChoose(_selections[_cursorIdx]);
    }
  }

  void draw() {
    _totalArea.draw(); // TODO: draw bg texture
    auto rect = Rect2i(_totalArea.topLeft, _entryWidth, _entryHeight);
    foreach(idx, entry ; _selections) {
      drawEntry(entry, rect, idx == _cursorIdx);
      rect.y += _entryHeight + spacingY;
    }
  }

  protected:
  void drawEntry(T entry, Rect2i rect, bool isSelected);
  int entryWidth(T entry);
  int entryHeight(T entry);

  static Font _font;

  private:
  Rect2i _totalArea;
  int _entryWidth, _entryHeight;
  T[] _selections;
  int _cursorIdx;
  Action _onHover, _onChoose;

  static this() {
    _font = getFont(fontName);
  }
}
