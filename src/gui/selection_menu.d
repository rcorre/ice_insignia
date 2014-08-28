module gui.selection_menu;

import std.conv;
import std.algorithm : max;
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
    auto selectionArea = Rect2i(pos.x, pos.y, 0, 0);
    auto totalArea     = Rect2i(pos.x, pos.y, 0, 0);
    foreach(entry; selections) {
      selectionArea.width  = entryWidth(entry);
      selectionArea.height = entryHeight(entry);
      _areas ~= selectionArea;

      int offset = selectionArea.height + spacingY;
      selectionArea.y += offset;
      totalArea.height += offset;
      totalArea.width = max(totalArea.width, selectionArea.width);
    }
    _totalArea = totalArea;
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
    foreach(idx, entry ; _selections) {
      auto rect = _areas[idx];
      drawEntry(entry, rect, idx == _cursorIdx);
    }
  }

  protected:
  void drawEntry(T entry, Rect2i rect, bool isSelected);
  int entryWidth(T entry);
  int entryHeight(T entry);

  static Font _font;

  private:
  Rect2i _totalArea;
  T[] _selections;
  Rect2i[] _areas;
  int _cursorIdx;
  Action _onHover, _onChoose;

  static this() {
    _font = getFont(fontName);
  }
}
