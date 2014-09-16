module model.attackable;

interface Attackable {
  @property {
    bool alive();
    int row();
    int col();
  }
  void dealDamage(int amount);
}
