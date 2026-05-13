class Wedding {
  final int? id;
  final String title;
  final String slug;
  final String? coverImage;
  final String? musicUrl;
  final DateTime? createdAt;

  Wedding({
    this.id,
    required this.title,
    required this.slug,
    this.coverImage,
    this.musicUrl,
    this.createdAt,
  });

  factory Wedding.fromJson(Map<String, dynamic> json) {
    return Wedding(
      id: json['id'],
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      coverImage: json['coverImage'],
      musicUrl: json['musicUrl'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'coverImage': coverImage,
      'musicUrl': musicUrl,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
