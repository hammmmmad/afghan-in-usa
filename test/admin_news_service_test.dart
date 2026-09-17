import 'package:flutter_test/flutter_test.dart';

import 'package:afghan_in_usa/services/admin_news_service.dart';

void main() {
  group('AdminNewsService.makeSlug', () {
    test(r'keeps the database pattern ^[a-z0-9]+(-[a-z0-9]+)*$', () {
      final RegExp pattern = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');
      expect(
        AdminNewsService.makeSlug('New Visa Update', '12345678'),
        matches(pattern),
      );
    });

    test('falls back to an id-based slug for Persian titles', () {
      // Persian letters are not allowed in slugs, so they are dropped.
      final String slug = AdminNewsService.makeSlug('خبر مهم', '12345678');
      expect(slug, 'news-12345678');
    });

    test('appends the suffix so two articles never collide', () {
      final String a = AdminNewsService.makeSlug('same title', 'aaaaaaaa-1');
      final String b = AdminNewsService.makeSlug('same title', 'bbbbbbbb-2');
      expect(a, isNot(b));
    });
  });

  group('AdminNewsService.paragraphs', () {
    test('splits on blank lines and drops empties', () {
      expect(
        AdminNewsService.paragraphs('اول\n\nدوم\n\n\n\nسوم'),
        <String>['اول', 'دوم', 'سوم'],
      );
    });

    test('handles CRLF input', () {
      expect(
        AdminNewsService.paragraphs('a\r\n\r\nb'),
        <String>['a', 'b'],
      );
    });

    test('a single paragraph stays a single item', () {
      expect(AdminNewsService.paragraphs('فقط یک پاراگراف'), <String>['فقط یک پاراگراف']);
      expect(AdminNewsService.paragraphs('   '), <String>[]);
    });
  });
}
