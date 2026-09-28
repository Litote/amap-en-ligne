import 'package:amap_en_ligne/domain/validation/input_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('email shape mirrors the back InputRules', () {
    expect(isValidEmail('jean@example.com'), isTrue);
    expect(isValidEmail(' jean+amap@example.co.uk '), isTrue);
    expect(isValidEmail('not-an-email'), isFalse);
    expect(isValidEmail('jean@example'), isFalse);
    expect(isValidEmail('je an@example.com'), isFalse);
  });

  test('http(s) URL check mirrors the back InputRules', () {
    expect(isValidHttpUrl('https://amap.example.org'), isTrue);
    expect(isValidHttpUrl('http://amap.example.org/page'), isTrue);
    expect(isValidHttpUrl('ftp://amap.example.org'), isFalse);
    expect(isValidHttpUrl('amap.example.org'), isFalse);
  });

  test('form validators return French messages', () {
    expect(requiredName('AMAP'), isNull);
    expect(requiredName('  '), 'Ce champ est requis.');
    expect(
      requiredName('x' * 201),
      'Ce champ ne doit pas dépasser 200 caractères.',
    );
    expect(requiredEmail(''), 'Ce champ est requis.');
    expect(requiredEmail('bad'), 'Adresse email invalide.');
    expect(optionalEmail(''), isNull);
    expect(optionalEmail('bad'), 'Adresse email invalide.');
    expect(optionalHttpUrl(''), isNull);
    expect(
      optionalHttpUrl('amap.example.org'),
      "L'URL n'est pas valide (ex. https://…).",
    );
  });

  test('phone check mirrors the back InputRules', () {
    expect(isValidPhone('06 12 34 56 78'), isTrue);
    expect(isValidPhone('+33 (0)6.12.34.56.78'), isTrue);
    expect(isValidPhone('06-12-34-56-78'), isTrue);
    expect(isValidPhone('abc<script>'), isFalse);
    expect(isValidPhone('12 34'), isFalse);
    expect(isValidPhone('06 12 +34 56 78'), isFalse);
    expect(isValidPhone('0' * 31), isFalse);
    expect(optionalPhone(''), isNull);
    expect(optionalPhone('abc'), 'Numéro de téléphone invalide.');
  });

  test('basket sizes mirror the back InputRules', () {
    expect(basketSizesError(['Petit', 'Grand']), isNull);
    expect(basketSizesError(['x' * 201]), contains('200 caractères'));
    expect(
      basketSizesError(['Petit', ' petit ']),
      'La taille « petit » est présente deux fois.',
    );
  });

  test('component icons: only small inline SVG markup (same as the back)', () {
    expect(optionalSvgImageError(''), isNull);
    expect(optionalSvgImageError('<svg></svg>'), isNull);
    expect(optionalSvgImageError('  <?xml version="1.0"?><svg/>'), isNull);
    expect(
      optionalSvgImageError('https://x/y.png'),
      'Seules les images au format SVG sont acceptées.',
    );
    final atLimit = '<svg>${'x' * (kMaxSvgLength - 11)}</svg>';
    expect(optionalSvgImageError(atLimit), isNull);
    expect(optionalSvgImageError('${atLimit}x'), contains('Image trop lourde'));
  });

  test('optionalSvgImageError rejects active content', () {
    const active = [
      '<svg><script>alert(1)</script></svg>',
      '<svg><SCRIPT src=x /></svg>',
      '<svg onload="alert(1)"></svg>',
      "<svg><rect ONCLICK = 'x'/></svg>",
      '<svg><a href="javascript:alert(1)"/></svg>',
      '<svg><foreignObject><div/></foreignObject></svg>',
    ];
    for (final svg in active) {
      expect(
        optionalSvgImageError(svg),
        "L'image ne doit contenir ni script ni gestionnaire d'événement.",
        reason: svg,
      );
    }
    expect(
      optionalSvgImageError('<svg><rect fill="gold" class="onion"/></svg>'),
      isNull,
    );
  });
}
