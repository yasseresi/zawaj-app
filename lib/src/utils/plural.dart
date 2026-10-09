import 'package:easy_localization/easy_localization.dart';

extension PluralOrZero on String {
  /// `plural(n)`, except a count of 0 uses the key's authored `zero` form
  /// when it has one. With CLDR plural rules on, easy_localization picks the
  /// form from the language rule alone: French maps 0 to `one` ("1 invité")
  /// and English to `other` ("0 guests"), skipping "Aucun invité"/"No guests".
  String pluralOrZero(num n) {
    if (n == 0 && '$this.zero'.trExists()) return '$this.zero'.tr();
    return plural(this, n);
  }
}
