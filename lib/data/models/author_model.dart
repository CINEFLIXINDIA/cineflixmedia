class AuthorModel {
  final int id;
  final String name;
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final String email;
  final String? phone;
  final String? avatar;
  final String? description;
  final String? joinedDate;
  final String? createdAt;
  final String? dob;
  final String? gender;
  final String? education;
  final String? designation;
  final String? experience;
  final String? city;
  final String? state;
  final String? address;
  final String organization;
  final String? facebook;
  final String? instagram;
  final String? xTwitter;
  final String? youtube;
  final String? linkedin;

  const AuthorModel({
    required this.id,
    required this.name,
    this.firstName,
    this.lastName,
    this.displayName,
    required this.email,
    this.phone,
    this.avatar,
    this.description,
    this.joinedDate,
    this.createdAt,
    this.dob,
    this.gender,
    this.education,
    this.designation,
    this.experience,
    this.city,
    this.state,
    this.address,
    this.organization = 'CineFlix Media',
    this.facebook,
    this.instagram,
    this.xTwitter,
    this.youtube,
    this.linkedin,
  });

  String get effectiveDisplayName {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }
    return name;
  }

  String get cityState {
    final c = city?.trim() ?? '';
    final s = state?.trim() ?? '';
    if (c.isNotEmpty && s.isNotEmpty) return '$c, $s';
    if (c.isNotEmpty) return c;
    if (s.isNotEmpty) return s;
    return '';
  }

  String? get age {
    if (dob == null || dob!.trim().isEmpty) return null;
    try {
      final date = DateTime.tryParse(dob!.trim());
      if (date == null) return null;
      final now = DateTime.now();
      int years = now.year - date.year;
      if (now.month < date.month || (now.month == date.month && now.day < date.day)) {
        years--;
      }
      return years >= 0 ? '$years yrs' : null;
    } catch (_) {
      return null;
    }
  }

  String? get formattedDobWithAge {
    if (dob == null || dob!.trim().isEmpty) return null;
    final a = age;
    if (a != null && a.isNotEmpty) {
      return '$dob ($a)';
    }
    return dob;
  }

  factory AuthorModel.fromJson(Map<String, dynamic> json) {
    return AuthorModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      displayName: json['display_name']?.toString(),
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      avatar: json['avatar']?.toString(),
      description: json['description']?.toString(),
      joinedDate: json['joined_date']?.toString(),
      createdAt: json['created_at']?.toString(),
      dob: json['dob']?.toString(),
      gender: json['gender']?.toString(),
      education: json['education']?.toString(),
      designation: json['designation']?.toString(),
      experience: json['experience']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      address: json['address']?.toString(),
      organization: json['organization']?.toString() ?? 'CineFlix Media',
      facebook: json['facebook']?.toString(),
      instagram: json['instagram']?.toString(),
      xTwitter: (json['x_twitter'] ?? json['twitter'] ?? json['x'])?.toString(),
      youtube: json['youtube']?.toString(),
      linkedin: json['linkedin']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'first_name': firstName,
      'last_name': lastName,
      'display_name': displayName,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'description': description,
      'joined_date': joinedDate,
      'created_at': createdAt,
      'dob': dob,
      'gender': gender,
      'education': education,
      'designation': designation,
      'experience': experience,
      'city': city,
      'state': state,
      'address': address,
      'organization': organization,
      'facebook': facebook,
      'instagram': instagram,
      'x_twitter': xTwitter,
      'youtube': youtube,
      'linkedin': linkedin,
    };
  }
}

class AuthorStatsModel {
  final int postsApproved;
  final int publishedPosts;
  final int pendingPosts;
  final int draftPosts;

  const AuthorStatsModel({
    this.postsApproved = 0,
    this.publishedPosts = 0,
    this.pendingPosts = 0,
    this.draftPosts = 0,
  });

  factory AuthorStatsModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val is int) return val;
      if (val != null) return int.tryParse(val.toString()) ?? 0;
      return 0;
    }

    return AuthorStatsModel(
      postsApproved: parseInt(json['posts_approved']),
      publishedPosts: parseInt(json['published_posts']),
      pendingPosts: parseInt(json['pending_posts']),
      draftPosts: parseInt(json['draft_posts']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'posts_approved': postsApproved,
      'published_posts': publishedPosts,
      'pending_posts': pendingPosts,
      'draft_posts': draftPosts,
    };
  }
}

class ActivityLogModel {
  final int id;
  final String action;
  final String description;
  final String? ipAddress;
  final String? createdAt;
  final String? timeAgo;

  const ActivityLogModel({
    required this.id,
    required this.action,
    required this.description,
    this.ipAddress,
    this.createdAt,
    this.timeAgo,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      action: json['action']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      ipAddress: json['ip_address']?.toString(),
      createdAt: json['created_at']?.toString(),
      timeAgo: json['time_ago']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'description': description,
      'ip_address': ipAddress,
      'created_at': createdAt,
      'time_ago': timeAgo,
    };
  }
}

class AuthorDashboardData {
  final AuthorModel author;
  final AuthorStatsModel stats;
  final List<ActivityLogModel> activityLogs;

  const AuthorDashboardData({
    required this.author,
    required this.stats,
    this.activityLogs = const [],
  });

  factory AuthorDashboardData.fromJson(Map<String, dynamic> json) {
    final authorJson = json['author'] as Map<String, dynamic>? ?? {};
    final statsJson = json['statistics'] as Map<String, dynamic>? ?? {};
    final logsJson = json['activity_logs'] as List? ?? [];

    return AuthorDashboardData(
      author: AuthorModel.fromJson(authorJson),
      stats: AuthorStatsModel.fromJson(statsJson),
      activityLogs: logsJson
          .whereType<Map<String, dynamic>>()
          .map((e) => ActivityLogModel.fromJson(e))
          .toList(),
    );
  }
}

