module model.attribute;

enum Attribute {
  maxHp,
  strength,
  magic,
  skill,
  speed,
  luck,
  defense,
  resist,
  move,
  constitution
}

enum AttributeCaps = [
  Attribute.maxHp        : 100,
  Attribute.strength     : 25,
  Attribute.magic        : 25,
  Attribute.skill        : 25,
  Attribute.speed        : 25,
  Attribute.luck         : 25,
  Attribute.defense      : 25,
  Attribute.resist       : 25,
  Attribute.move         : 10,
  Attribute.constitution : 15,
];
