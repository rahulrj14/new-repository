/// Your blob grows with lifetime locked time. Purely cosmetic.
library;

class BlobStage {
  const BlobStage(this.index, this.name, this.minutes);
  final int index;
  final String name;

  /// Lifetime locked minutes needed.
  final int minutes;
}

const stages = <BlobStage>[
  BlobStage(0, 'Sprout', 0),
  BlobStage(1, 'Buddy', 60),
  BlobStage(2, 'Glow', 300),
  BlobStage(3, 'Radiant', 900),
  BlobStage(4, 'Legend', 2400),
];

BlobStage stageFor(int lifetimeMinutes) {
  var s = stages.first;
  for (final st in stages) {
    if (lifetimeMinutes >= st.minutes) s = st;
  }
  return s;
}

BlobStage? nextStage(BlobStage s) =>
    s.index + 1 < stages.length ? stages[s.index + 1] : null;
