/// Centralized asset path constants for the Paws and Found mobile app.
///
/// Adheres to project Rule 2:
/// - Never hardcode asset strings in UI widgets.
/// - Define asset paths here as static constants.
class AppAssets {
  AppAssets._();

  // ---------------------------------------------------------------------------
  // Base Asset Directories
  // ---------------------------------------------------------------------------
  static const String imagesDir = 'assets/images';
  static const String svgsDir = 'assets/svgs';
  static const String audioDir = 'assets/audio';

  // ---------------------------------------------------------------------------
  // Audio (Species Alert Sounds)
  // ---------------------------------------------------------------------------
  static const String soundBird = '$audioDir/bird_default.wav';
  static const String soundCat = '$audioDir/cat_default1.wav';
  static const String soundSystem = '$audioDir/default_system.wav';
  static const String soundDog = '$audioDir/dog_default.wav';
  static const String soundKitten = '$audioDir/kitten_default.wav';
  static const String soundMacaw = '$audioDir/macaw-default.wav';
  static const String soundPuppy = '$audioDir/puppy_default.wav';

  // ---------------------------------------------------------------------------
  // Images (Add constants here as image assets are added to assets/images/)
  // ---------------------------------------------------------------------------
  static const String petPlaceholder = '$imagesDir/images.jpg';
  static const String appLogo = '$imagesDir/app_logo.png';
  static const String appLauncherIconPng = '$imagesDir/app_launcher_icon.png';

  // ---------------------------------------------------------------------------
  // SVGs (Add constants here as SVG assets are added to assets/svgs/)
  // ---------------------------------------------------------------------------
  static const String appLogoSvg = '$svgsDir/paws-logo.svg';
  static const String pawsLogoSvg = '$svgsDir/paws-logo.svg';
  static const String authBackgroundSvg = '$svgsDir/paw-bg.svg';
  static const String pawBackgroundSvg = '$svgsDir/paw-bg.svg';
  static const String appIconSvg = '$svgsDir/paws-app-icon.svg';
  static const String appLauncherIconSvg = '$svgsDir/paws-app-icon.svg';
}
