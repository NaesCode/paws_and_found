/// Application legal constants for Terms of Service and Privacy Policy.
/// Derived directly from project root `TERMS_OF_SERVICE.md` and `PRIVACY_POLICY.md`.
class AppLegalConstants {
  AppLegalConstants._();

  static const String lastUpdated = 'November 7, 2026';

  // ---------------------------------------------------------------------------
  // Privacy Policy
  // ---------------------------------------------------------------------------
  static const String privacyPolicyTitle = 'Privacy Policy';

  static const String privacyPolicyIntro =
      'Paws and Found ("we", "our", or "us") is committed to protecting your '
      'privacy. This Privacy Policy explains how our mobile application collects, '
      'uses, and safeguards your information when you use our services.';

  static const List<Map<String, dynamic>> privacyPolicySections = [
    {
      'title': '1. Information We Collect',
      'items': [
        'Account Information: When you register or sign in via Google OAuth or email, we receive your email address, name, and profile picture.',
        'Animal Reports & Sightings: Photos, descriptions, species, status (lost/found/stray), and timestamps of reported pets.',
        'Location Data: GPS coordinates and location descriptions attached to animal sightings or missing pet alerts to help reunite lost pets within the community.',
        'Device & Usage Data: Basic diagnostic information to ensure system stability and performance.',
      ],
    },
    {
      'title': '2. How We Use Your Information',
      'items': [
        'To facilitate community pet reunification and map missing/found animal reports.',
        'To execute AI visual matching between reported lost pets and spotted animals.',
        'To notify users regarding status updates or potential matches for their pets.',
        'To authenticate and maintain secure user sessions.',
      ],
    },
    {
      'title': '3. Data Sharing & Security',
      'items': [
        'We do not sell, rent, or trade your personal information.',
        'Animal sighting locations and photos are displayed publicly on the community animal map to aid recovery.',
        'Personal contact details (phone numbers and exact home addresses) are strictly protected by Row-Level Security (RLS) policies.',
      ],
    },
    {
      'title': '4. Contact Us',
      'items': [
        'If you have any questions about this Privacy Policy, please contact the development team through our repository: https://github.com/NaesCode/paws_and_found.',
      ],
    },
  ];

  // ---------------------------------------------------------------------------
  // Terms of Service
  // ---------------------------------------------------------------------------
  static const String termsOfServiceTitle = 'Terms of Service';

  static const String termsOfServiceIntro =
      'Welcome to Paws and Found. By downloading, accessing, or using the '
      'Paws and Found mobile application, you agree to be bound by these Terms of Service.';

  static const List<Map<String, dynamic>> termsOfServiceSections = [
    {
      'title': '1. Acceptance of Terms',
      'items': [
        'By creating an account or submitting reports, you confirm that you are at least 13 years of age and agree to comply with all applicable laws and these Terms.',
      ],
    },
    {
      'title': '2. Community Conduct & Content Standards',
      'items': [
        'Users agree to submit truthful, accurate information regarding lost, found, or stray animals.',
        'Submissions containing fraudulent reports, spam, harassment, inappropriate imagery, or malicious content are strictly prohibited and will be quarantined or removed by administrators.',
        'Users retain ownership of photos they submit, but grant Paws and Found a non-exclusive license to display the photos for pet recovery and matching purposes.',
      ],
    },
    {
      'title': '3. Disclaimer of Warranties',
      'items': [
        'Paws and Found is provided on an "as-is" and "as-available" basis. While we strive for high accuracy in AI matching and location services, we make no guarantees that every lost pet will be recovered.',
      ],
    },
    {
      'title': '4. Limitation of Liability',
      'items': [
        'To the maximum extent permitted by law, Paws and Found and its developers are not liable for any indirect, incidental, or consequential damages resulting from the use of the platform.',
      ],
    },
    {
      'title': '5. Contact',
      'items': [
        'For questions regarding these Terms, visit our project repository: https://github.com/NaesCode/paws_and_found.',
      ],
    },
  ];
}
