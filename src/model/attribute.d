module model.attribute;

enum Attribute {
  maxHp,
  strength,
  skill,
  speed,
  luck,
  defense,
  move,
  constitution
}

enum AttributeCaps = [
  Attribute.maxHp        : 100,
  Attribute.strength     : 25,
  Attribute.skill        : 25,
  Attribute.speed        : 25,
  Attribute.luck         : 25,
  Attribute.defense      : 25,
  Attribute.move         : 10,
  Attribute.constitution : 15,
];
