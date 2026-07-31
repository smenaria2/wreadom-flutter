import 'package:flutter/foundation.dart';

/// Registers custom licenses (e.g. font licenses, dataset licenses)
/// with Flutter's [LicenseRegistry] so they appear in [LicensePage].
void registerCustomLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      ['Dakshina Dataset v1.0'],
      '''
Dakshina Dataset v1.0
Authors: Google Research (Roark et al.)
Source: https://github.com/google-research-datasets/dakshina

Licensed under the Creative Commons Attribution-ShareAlike 4.0 International License (CC BY-SA 4.0).
https://creativecommons.org/licenses/by-sa/4.0/
''',
    );
    yield const LicenseEntryWithLineBreaks(
      [
        'Plus Jakarta Sans',
        'Noto Sans Devanagari',
        'Dancing Script',
        'Cormorant Garamond',
        'Inter',
        'Caveat',
      ],
      '''
SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007

This Font Software is licensed under the SIL Open Font License, Version 1.1.
This license is available with a FAQ at: http://scripts.sil.org/OFL
''',
    );
  });
}
