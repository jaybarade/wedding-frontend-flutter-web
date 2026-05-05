class Photo {
  final int? id;
  final String imageUrl;
  final DateTime? uploadedAt;

  Photo({
    this.id,
    required this.imageUrl,
    this.uploadedAt,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'],
      imageUrl: json['imageUrl'] ?? '',
      uploadedAt: json['uploadedAt'] != null ? DateTime.parse(json['uploadedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'uploadedAt': uploadedAt?.toIso8601String(),
    };
  }
}
