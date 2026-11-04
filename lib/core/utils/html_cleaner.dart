import '../constants/app_constants.dart';

class HtmlCleaner {
  HtmlCleaner._();

  /// Fixes relative image URLs and shortcodes from Botble CMS HTML output
  static String prepareHtmlContent(String? rawHtml) {
    if (rawHtml == null || rawHtml.trim().isEmpty) return '';

    String cleaned = rawHtml;

    // Convert relative storage URLs to absolute
    cleaned = cleaned.replaceAll('src="/storage/', 'src="${AppConstants.websiteUrl}/storage/');
    cleaned = cleaned.replaceAll("src='/storage/", "src='${AppConstants.websiteUrl}/storage/");
    cleaned = cleaned.replaceAll('src="storage/', 'src="${AppConstants.websiteUrl}/storage/');

    // Strip shortcode tags but keep inner content if readable
    cleaned = cleaned.replaceAll('<shortcode>', '<div class="shortcode-box">');
    cleaned = cleaned.replaceAll('</shortcode>', '</div>');

    // Clean up empty paragraphs
    cleaned = cleaned.replaceAll(RegExp(r'<p>\s*(&nbsp;|\s*)*<\/p>'), '');

    return cleaned;
  }

  /// Calculates estimated reading time in minutes
  static int estimateReadingTime(String? text) {
    if (text == null || text.isEmpty) return 1;
    final plainText = text.replaceAll(RegExp(r'<[^>]*>'), ' ');
    final wordCount = plainText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final minutes = (wordCount / 200).ceil();
    return minutes < 1 ? 1 : minutes;
  }

  /// Strips HTML tags for clean text previews
  static String stripHtml(String? html) {
    if (html == null) return '';
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

