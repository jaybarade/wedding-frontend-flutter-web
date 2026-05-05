class ApiConfig {
  // Toggle this for Android emulator vs Web/Localhost
  static const bool isAndroid = false;

  static String get baseUrl =>
      "https://wedding-album-42gg.onrender.com/api";

  static const String loginUrl = "/auth/login";
  static const String registerUrl = "/auth/register";
  static const String myWeddingsUrl = "/weddings/my";
  static const String createWeddingUrl = "/weddings";
  static const String uploadPhotosUrl = "/photos/upload-multiple";
  static const String publicGalleryUrl = "/public/weddings"; // + /{slug}
}
