import 'package:flutter_test/flutter_test.dart';
import 'package:everywear/services/clothing_semantic_label.dart';

void main() {
  test('semantic label uses canonical fields and ignores localized labels', () {
    final english = buildClothingSemanticLabel({
      'color': 'blue',
      'colorLabel': 'Blue',
      'material': 'Cotton',
      'materialLabel': 'Cotton',
      'category': 'Tops',
    });
    final french = buildClothingSemanticLabel({
      'color': 'blue',
      'colorLabel': 'Bleu',
      'material': 'Cotton',
      'materialLabel': 'Coton',
      'category': 'Tops',
    });
    final spanish = buildClothingSemanticLabel({
      'color': 'blue',
      'colorLabel': 'Azul',
      'material': 'Cotton',
      'materialLabel': 'Algodón',
      'category': 'Tops',
    });

    expect(english, 'blue Cotton Tops');
    expect(french, english);
    expect(spanish, english);
  });

  test('omits missing and unknown structured attributes', () {
    expect(
      buildClothingSemanticLabel({
        'color': 'unknown',
        'material': ' Linen ',
        'category': '',
      }),
      'Linen',
    );
    expect(buildClothingSemanticLabel(null), isEmpty);
  });
}
