module gui.roster_view;

import gui.element;
import gui.container;
import geometry.all;
import graphics.all;
import model.character;

class RosterView : GUIContainer {
  this(Vector2i pos, Character[] characters) {
    super(pos, Anchor.topLeft, "roster_view");
    foreach(character ; characters) {
    }
  }
}
