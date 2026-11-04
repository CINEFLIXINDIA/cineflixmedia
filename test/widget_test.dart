import 'package:cineflix_app/core/utils/date_formatter.dart';
import 'package:cineflix_app/core/utils/html_cleaner.dart';
import 'package:cineflix_app/data/models/article_model.dart';
import 'package:cineflix_app/data/models/category_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CineFlix Media Unit Tests', () {
    test('CategoryModel JSON serialization and deserialization', () {
      final json = {
        'id': 9,
        'name': 'Bollywood News',
        'slug': 'bollywood-news',
        'description': 'Latest updates from Bollywood',
        'children': [],
        'parent': {'id': null, 'name': null, 'slug': '', 'url': 'https://cineflixmedia.in'},
      };

      final category = CategoryModel.fromJson(json);
      expect(category.id, 9);
      expect(category.name, 'Bollywood News');
      expect(category.slug, 'bollywood-news');

      final serialized = category.toJson();
      expect(serialized['id'], 9);
      expect(serialized['name'], 'Bollywood News');
    });

    test('ArticleModel JSON deserialization and getters', () {
      final json = {
        'id': 3127,
        'name': 'Why We Compare Ourselves to People We Do Not Know',
        'slug': 'why-we-compare-ourselves-to-people-we-dont-know',
        'description': 'A psychologist explains the psychological drivers.',
        'content': '<p>Full content of the news article here.</p>',
        'image': 'automatic-news/cineflix-news-k8tdoss2kis3drlsvet.jpg',
        'categories': [
          {'id': 14, 'name': 'Theatre & Drama', 'slug': 'theatre-drama'}
        ],
        'tags': [
          {'id': 1, 'name': 'psychologist'}
        ],
        'created_at': '2026-10-23T14:50:11.000000Z',
        'author': 'CINEFLIX INDIA',
      };

      final article = ArticleModel.fromJson(json);
      expect(article.id, 3127);
      expect(article.title, 'Why We Compare Ourselves to People We Do Not Know');
      expect(article.slug, 'why-we-compare-ourselves-to-people-we-dont-know');
      expect(article.primaryCategoryName, 'Theatre & Drama');
      expect(article.primaryCategoryId, 14);
      expect(article.author, 'CINEFLIX INDIA');
      expect(article.image, startsWith('https://cineflixmedia.in/storage/'));
      expect(article.readingTimeMinutes, greaterThanOrEqualTo(1));
    });

    test('HtmlCleaner cleans storage URLs and tags', () {
      const raw = '<p>Test <img src="/storage/main/news.jpg"><shortcode>Quote</shortcode></p>';
      final prepared = HtmlCleaner.prepareHtmlContent(raw);
      expect(prepared.contains('https://cineflixmedia.in/storage/main/news.jpg'), isTrue);
      expect(prepared.contains('<shortcode>'), isFalse);

      final stripped = HtmlCleaner.stripHtml('<p>Hello <b>World</b> &amp; CineFlix</p>');
      expect(stripped, 'Hello World & CineFlix');
    });

    test('DateFormatter parses ISO strings', () {
      final nowIso = DateTime.now().toIso8601String();
      final timeAgo = DateFormatter.timeAgo(nowIso);
      expect(timeAgo, 'Just now');

      final pastIso = '2025-12-24T01:58:49.000000Z';
      final formatted = DateFormatter.formatShortDate(pastIso);
      expect(formatted, contains('2025'));
    });
  });
}
