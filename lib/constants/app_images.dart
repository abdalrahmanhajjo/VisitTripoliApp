/// Local Tripoli images - stored in assets/images/
/// Download high-quality Tripoli photos from:
/// https://commons.wikimedia.org/wiki/Category:Tripoli,_Lebanon
class AppImages {
  static const _base = 'assets/images';

  /// Intro slides - 4 images for onboarding
  /// intro_1 = ساحة التل (Al-Tell clock tower), intro_3 = قلعة طرابلس (citadel by river)
  static const List<String> intro = [
    '$_base/intro_1.png',
    '$_base/intro_2.jpg',
    '$_base/intro_3.png',
    '$_base/intro_4.jpg',
  ];

  static const String tripoliCity = '$_base/intro_1.png';
  static const String citadel = '$_base/intro_2.jpg';
  static const String oldCity = '$_base/downtown.jpg';
  static const String greatMosque = '$_base/intro_4.jpg';
  static const String skyline = '$_base/intro_1.png';
  static const String khanSaboun = '$_base/intro_3.png';
  static const String heritage = '$_base/intro_2.jpg';
  static const String fallback = '$_base/intro_1.png';

  /// Explore page background (clock tower sketch).
  static const String exploreBackground = '$_base/explore_background.png';
}
