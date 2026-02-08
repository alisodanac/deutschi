enum WordType {
  noun,
  verb,
  adjective,
  adverb;

  @override
  String toString() {
    switch (this) {
      case WordType.noun:
        return 'Noun';
      case WordType.verb:
        return 'Verb';
      case WordType.adjective:
        return 'Adjective';
      case WordType.adverb:
        return 'Adverb';
    }
  }

  static WordType? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'Noun':
        return WordType.noun;
      case 'Verb':
        return WordType.verb;
      case 'Adjective':
        return WordType.adjective;
      case 'Adverb':
        return WordType.adverb;
      default:
        // Handle case if there are lowercase values in DB or new ones
        try {
          return WordType.values.firstWhere((e) => e.name.toLowerCase() == value.toLowerCase());
        } catch (_) {
          return null;
        }
    }
  }
}
