import 'package:amap_en_ligne/domain/validation/search_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeForSearch', () {
    test('lowercases and drops French accents', () {
      expect(normalizeForSearch('Cécile'), 'cecile');
      expect(normalizeForSearch('HÉLÈNE'), 'helene');
      expect(normalizeForSearch('Noël'), 'noel');
      expect(normalizeForSearch('Françoise'), 'francoise');
      expect(normalizeForSearch('Ève à l’île'), 'eve a l’ile');
      expect(normalizeForSearch('Où'), 'ou');
      expect(normalizeForSearch('Ÿvonne'), 'yvonne');
    });

    test('expands ligatures', () {
      expect(normalizeForSearch('Cœur'), 'coeur');
      expect(normalizeForSearch('Lætitia'), 'laetitia');
      expect(normalizeForSearch('ŒUVRE'), 'oeuvre');
    });

    test('keeps other characters untouched', () {
      expect(
        normalizeForSearch('jburet+lea@gmail.com'),
        'jburet+lea@gmail.com',
      );
    });
  });

  group('matchesSearch', () {
    test('an empty query matches everything', () {
      expect(matchesSearch('', ['Anything']), isTrue);
      expect(matchesSearch('   ', ['Anything']), isTrue);
    });

    test('ignores accents and letter case on both sides', () {
      expect(matchesSearch('cécile', ['Augustin et Cecile MIGNOT']), isTrue);
      expect(matchesSearch('cecile', ['Cécile MECHAIN']), isTrue);
      expect(matchesSearch('francoise', ['Françoise DUPONT']), isTrue);
      expect(matchesSearch('FRANÇOISE', ['françoise dupont']), isTrue);
    });

    test('matches any of the fields and skips null ones', () {
      expect(
        matchesSearch('lea@', [null, 'Léa', 'jburet+lea@gmail.com']),
        isTrue,
      );
      expect(matchesSearch('zz', [null, 'Léa']), isFalse);
    });

    test('trims the query', () {
      expect(matchesSearch('  léa ', ['Léa RODRIGUEZ']), isTrue);
    });
  });
}
