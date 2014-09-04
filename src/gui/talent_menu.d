module gui.talent_menu;

import std.string : format;
import std.array : array;
import std.algorithm : filter, max;
import graphics.all;
import geometry.all;
import gui.selection_menu;
import model.item;
import model.talent;

class TalentMenu : SelectionMenu!Talent {
  this(Vector2i pos, Talent[] talents, Action onChoose, HoverAction onHover, bool focus = false)
  {
    super(pos, talents, onChoose, onHover, focus);
  }

  protected override {
    void drawEntry(Talent talent, Rect2i rect, bool isSelected) {
      if (isSelected) {
        rect.drawFilled(Color.white, 5, 5);
      }
      else {
        rect.drawFilled(Color.gray, 5, 5);
      }
      if (talent) {
        Vector2i size = talent.sprite.size;
        talent.sprite.draw(rect.topLeft + size / 2);
        _talentFont.draw(talent.title, rect.topLeft + Vector2i(size.x, 0));
      }
    }

    int entryWidth(Talent entry) {
      return entry.sprite.width + _talentFont.widthOf(entry.title);
    }

    int entryHeight(Talent entry) {
      return max(entry.sprite.height, _talentFont.heightOf(entry.title));
    }
  }
}

private:
static Font _talentFont;

static this() {
  _talentFont = getFont("talentSlot");
}
