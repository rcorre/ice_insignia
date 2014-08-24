module gui.selection_view;

import std.algorithm : max;
import graphics.all;
import geometry.all;
import util.input;

private enum {
  fontName = "selection_font",
  spacingY = 5
}

class SelectionView {
  alias Action = void delegate();
  this(Vector2i pos, Action[string] selections) {
    auto selectionArea = Rect2i(pos.x, pos.y, 0, 0);
    auto totalArea     = Rect2i(pos.x, pos.y, 0, 0);
    foreach(text, action; selections) {
      selectionArea.width  = _font.widthOf(text);
      selectionArea.height = _font.heightOf(text);

      Selection sel;
      sel.onClick = action;
      sel.text = text;
      sel.clickArea = selectionArea;
      sel.drawPos = selectionArea.topLeft;
      _selections ~= sel;

      int offset = selectionArea.height + spacingY;
      selectionArea.y += offset;
      totalArea.height += offset;
      totalArea.width = max(totalArea.width, selectionArea.width);
    }
    _totalArea = totalArea;
  }

  void handleInput(InputManager input) {
    if (input.selectUp) { --_cursorIdx; }
    else if (input.selectDown) { ++_cursorIdx; }
    _cursorIdx %= _selections.length;

    if (input.confirm) {
      _selections[_cursorIdx].onClick();
    }
  }

  void draw() {
    _totalArea.draw();
    foreach(idx, selection ; _selections) {
      if (idx == _cursorIdx) {
        selection.clickArea.drawFilled(Tint.white, 5, 5);
      }
      selection.draw();
    }
  }

  private:
  Rect2i _totalArea;
  Selection[] _selections;
  int _cursorIdx;

  struct Selection {
    Action onClick;
    string text;
    Rect2i clickArea;
    Vector2i drawPos;

    void draw() {
      _font.draw(text, drawPos);
    }
  }

  static Font _font;
  static this() {
    _font = getFont(fontName);
  }
}
