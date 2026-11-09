import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mano_requester/features/explore/category_photos.dart';
import 'package:mano_session/mano_session.dart';

void main() {
  test('every known category has a bundled photo', () {
    for (final category in ServiceCategories.all) {
      final photo = categoryPhoto(category.id) as Image;
      expect(
        (photo.image as AssetImage).assetName,
        'assets/categories/${category.id}.jpg',
      );
      final file = File('assets/categories/${category.id}.jpg');
      expect(file.lengthSync(), lessThan(80 * 1024));
    }
  });

  test('an unknown category falls back to its icon', () {
    final photo = categoryPhoto('roofing');

    expect(photo, isA<ColoredBox>());
    expect((photo as ColoredBox).child, isA<Icon>());
  });
}
