module model.attribute;

import model.valueset;

alias AttributeSet = ValueSet!Attribute;

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

enum AttributeAbbreviation = [
  Attribute.maxHp        : "HP",
  Attribute.strength     : "str",
  Attribute.skill        : "skl",
  Attribute.speed        : "spd",
  Attribute.luck         : "lck",
  Attribute.defense      : "def",
  Attribute.move         : "mov",
  Attribute.constitution : "con",
];

string abbreviation(Attribute att) {
  return AttributeAbbreviation[att];
}
