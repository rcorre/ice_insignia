module gui.talent_menu;

import std.string : format;
import std.array : array;
import std.algorithm : filter, max;
import graphics.all;
import geometry.all;
import gui.selection_menu;
import gui.talent_view;
import model.item;
import model.talent;

class TalentMenu : SelectionMenu!Talent {
  this(Vector2i pos, Talent[] talents, Action onChoose, bool focus = false)
  {
    super(pos, talents, onChoose, &showTalentDetail, null, focus);
  }

  protected override {
    void drawEntry(Talent talent, Rect2i rect, bool isSelected) {
      if (talent) {
        Vector2i size = talent.sprite.size;
        talent.sprite.draw(rect.topLeft + size / 2);
        _talentFont.draw(talent.title, rect.topLeft + Vector2i(size.x, 0));
        if (isSelected && _detailBox) {
          _detailBox.draw;
        }
      }
    }

    int entryWidth(Talent entry) {
      return entry.sprite.width + _talentFont.widthOf(entry.title);
    }

    int entryHeight(Talent entry) {
      return max(entry.sprite.height, _talentFont.heightOf(entry.title));
    }
  }

  void showTalentDetail(Talent talent, Rect2i area) {
    _detailBox = new TalentView(talent, area.topLeft - Vector2i(TalentView.width, 0));
  }
}

private:
static Font _talentFont;
static TalentView _detailBox;

static this() {
  _talentFont = getFont("talentSlot");
}
