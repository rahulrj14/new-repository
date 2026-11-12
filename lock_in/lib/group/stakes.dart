/// Fixed, wholesome stakes the host can pick. No free text.
library;

const stakes = <String>[
  'no stakes, just vibes ✌️',
  'first crack buys the snacks 🍟',
  'first crack makes the chai ☕',
  'first crack picks the next song 🎵',
  'first crack does 10 jumping jacks 🤸',
  'first crack tidies up 🧹',
  'last one standing picks the movie 🎬',
];

String stakeText(int id) => stakes[id.clamp(0, stakes.length - 1)];
