module model.weapon;

import util.jsonizer;
import model.item;

class Weapon : Item {
  mixin JsonizeMe;

  enum Type {
    sword,
    axe,
    lance,
    bow,
    anima,
    light,
    dark,
    staff
  }

  @property {
    int damage() { return _damage; }
    int hit()    { return _hit; }
    int avoid()  { return _avoid; }
    int weight() { return _weight; }
  }

  @jsonize private {
    int _damage;
    int _hit;
    int _avoid;
    int _weight;
  }
}
