import '../../core/utils/date_formatter.dart';

class CommentModel {
  final int id;
  final String name;
  final String? email;
  final String content;
  final String? avatarUrl;
  final int? replyTo;
  final String? createdAt;

  const CommentModel({
    required this.id,
    required this.name,
    this.email,
    required this.content,
    this.avatarUrl,
    this.replyTo,
    this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    int id = 0;
    if (json['id'] is int) {
      id = json['id'];
    } else if (json['id'] != null) {
      id = int.tryParse(json['id'].toString()) ?? 0;
    }

    int? replyToId;
    if (json['reply_to'] is int) {
      replyToId = json['reply_to'];
    } else if (json['reply_to'] != null) {
      replyToId = int.tryParse(json['reply_to'].toString());
    }

    return CommentModel(
      id: id,
      name: json['name']?.toString() ?? 'Reader',
      email: json['email']?.toString(),
      content: json['content']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      replyTo: replyToId,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'content': content,
      'avatar_url': avatarUrl,
      'reply_to': replyTo,
      'created_at': createdAt,
    };
  }

  String get timeAgo => DateFormatter.timeAgo(createdAt);

  String get initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'R';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }
}

